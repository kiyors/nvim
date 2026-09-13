-- Code adapted from https://github.com/calops/hmts.nvim.git
-- Modified to improve safety, caching, and integrated directly into the config.

local M = {}

local magic_prefixes = { ["\\v"] = true, ["\\m"] = true, ["\\M"] = true, ["\\V"] = true }

---@param str string
---@return string
local function check_magic(str)
  if string.len(str) < 2 or magic_prefixes[string.sub(str, 1, 2)] then
    return str
  end
  return "\\v" .. str
end

local compiled_vim_regexes = setmetatable({}, {
  __index = function(t, pat)
    local res = vim.regex(check_magic(pat))
    rawset(t, pat, res)
    return res
  end,
})

--- Returns a compiled vim regex for the given pattern.
---@param pattern string
---@return any
local function get_regex(pattern)
  return compiled_vim_regexes[pattern]
end

--- Checks if the given string matches the given regex pattern.
---@param pattern string
---@param str string
---@return boolean
local function regex_match(pattern, str)
  local regex = get_regex(pattern)
  return regex:match_str(str) ~= nil
end

--- Compares the given nix path with the given target path.
---@param target_path string[]
---@param node_path string[]
---@return boolean
local function path_diff(target_path, node_path)
  local is_match = false

  while true do
    if
      #node_path == 0
      or #target_path == 0
      or not regex_match(target_path[#target_path], node_path[#node_path])
    then
      break
    end
    is_match = true
    table.remove(target_path)
    table.remove(node_path)
  end

  return is_match
end

--- Safely get a node from a match capture
---@param match table<number, any>
---@param id number
---@return any|nil
local function get_node(match, id)
  local node = match[id]
  if not node then
    return nil
  end
  if type(node) == "table" then
    return node[1]
  end
  return node
end

--- Returns the text of the given path node.
---@param node any
---@param bufnr integer
---@return string|nil
local function get_text_from_path_node(node, bufnr)
  if not node or not node.type then
    return nil
  end
  if node:type() == "identifier" then
    return vim.treesitter.get_node_text(node, bufnr)
  elseif node:type() == "string_expression" then
    for i = 0, node:named_child_count() - 1 do
      local child = node:named_child(i)
      if child:type() == "string_fragment" then
        return vim.treesitter.get_node_text(child, bufnr)
      end
    end
  end

  return nil
end

--- Returns the nix path of the given attrpath node as a list of strings.
---@param attrpath any
---@param bufnr integer
---@return string[]
local function attrpath_to_strings(attrpath, bufnr)
  local path = {}
  if not attrpath or not attrpath.field then
    return path
  end

  for _, node in ipairs(attrpath:field("attr")) do
    local text = get_text_from_path_node(node, bufnr)
    if text then
      table.insert(path, text)
    end
  end

  return path
end

--- Returns the filename contained in the parent of the given node.
---@param path_node any
---@param bufnr integer
---@return string|nil
local function find_filename_in_parent_node(path_node, bufnr)
  if not path_node then
    return nil
  end

  local attrs
  if path_node:type() == "attrpath" then
    attrs = path_node:field("attr")
  else
    local parent = path_node:parent()
    while parent do
      if parent:type() == "binding" then
        local attrpath = parent:field("attrpath")[1]
        if attrpath then
          attrs = attrpath:field("attr")
          break
        end
      end
      if not parent.parent then
        break
      end
      parent = parent:parent()
    end
  end

  if not attrs or #attrs < 2 then
    return nil
  end

  local last_attr = get_text_from_path_node(attrs[#attrs], bufnr)
  if last_attr ~= "text" then
    return nil
  end

  return get_text_from_path_node(attrs[#attrs - 1], bufnr)
end

--- Checks if the given capture is located at the end of the given nix path.
---@param match table<number, any>
---@param _ any
---@param bufnr integer
---@param predicate any[]
---@return boolean
function M.hmts_path_handler(match, _, bufnr, predicate)
  local capture = get_node(match, predicate[2])
  if not capture or not capture.parent then
    return false
  end

  local node = capture:parent()
  local target_path = vim.list_slice(predicate, 3, nil)

  while node do
    if #target_path == 0 then
      return true
    end
    if node:type() == "binding" then
      local path_node = node:field("attrpath")[1]
      if path_node then
        local is_match = path_diff(target_path, attrpath_to_strings(path_node, bufnr))
        if not is_match then
          return false
        end
      end
    end
    if not node.parent then
      break
    end
    node = node:parent()
  end

  return false
end

--- Detects the language of the injection from the file extension.
---@param match table<number, any>
---@param _ any
---@param bufnr integer
---@param predicate any[]
---@param metadata table<string, string>
function M.hmts_inject_handler(match, _, bufnr, predicate, metadata)
  local path_node = get_node(match, predicate[2])
  if not path_node then
    return
  end
  local filename = find_filename_in_parent_node(path_node, bufnr)
  if filename == nil then
    return
  end
  local alias = vim.filetype.match({ filename = filename })

  if alias == nil then
    return
  end

  local lang = vim.treesitter.language.get_lang(alias)
  if lang then
    metadata["injection.language"] = lang
  end
end

--- Detects language of an embedded script (from shebang, file redirect, or heredoc delimiter)
---@param match table<number, any>
---@param _ any
---@param bufnr integer
---@param predicate any[]
---@param metadata table<string, string>
function M.shebang_inject_handler(match, _, bufnr, predicate, metadata)
  local node_id = predicate[2]
  local node = get_node(match, node_id)
  if not node then
    return
  end

  local text = vim.treesitter.get_node_text(node, bufnr)
  local lang = nil

  -- 1. Check for shebang in the text content
  local shebang = text:match("^%s*#![^\r\n]+")
  if shebang then
    local interp = shebang:match("env%s+%-%S+%s+([%w_%-]+)")
      or shebang:match("env%s+([%w_%-]+)")
      or shebang:match("/([%w_%-]+)%s*$")
    if interp then
      lang = interp
    end
  end

  -- 2. Check parent/sibling file_redirect (e.g. cat << 'EOF' > $out/bin/tinycast)
  if not lang then
    local parent = node:parent()
    if parent and parent:type() == "heredoc_redirect" then
      for child in parent:iter_children() do
        if child:type() == "file_redirect" then
          local redirect_text = vim.treesitter.get_node_text(child, bufnr):gsub("^[>%s]+", "")
          local filename = redirect_text:match("([^/]+)$") or redirect_text
          local alias = vim.filetype.match({ filename = filename })
          if alias then
            lang = vim.treesitter.language.get_lang(alias) or alias
          elseif redirect_text:match("/bin/") then
            lang = "bash"
          end
          break
        end
      end
    end
  end

  -- 3. Check heredoc delimiter (e.g. << 'BASH' or << 'SH')
  if not lang then
    local parent = node:parent()
    if parent and parent:type() == "heredoc_redirect" then
      for child in parent:iter_children() do
        if child:type() == "heredoc_end" or child:type() == "heredoc_start" then
          local delim = vim.treesitter.get_node_text(child, bufnr):gsub("['\"]", ""):lower()
          if delim == "bash" or delim == "sh" or delim == "zsh" then
            lang = "bash"
            break
          elseif delim == "python" or delim == "py" then
            lang = "python"
            break
          elseif delim == "lua" then
            lang = "lua"
            break
          end
        end
      end
    end
  end

  if lang then
    local ts_lang = vim.treesitter.language.get_lang(lang) or lang
    if ts_lang == "sh" then
      ts_lang = "bash"
    elseif ts_lang == "python3" then
      ts_lang = "python"
    end
    metadata["injection.language"] = ts_lang
    metadata["injection.include-children"] = true
  end
end

function M.setup()
  local opts = vim.fn.has("nvim-0.10") == 1 and { force = true, all = false } or true
  vim.treesitter.query.add_predicate("hmts-path?", M.hmts_path_handler, opts)
  vim.treesitter.query.add_directive("hmts-inject!", M.hmts_inject_handler, opts)
  vim.treesitter.query.add_directive("shebang-inject!", M.shebang_inject_handler, opts)
end

return M
