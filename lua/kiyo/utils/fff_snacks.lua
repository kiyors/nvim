-- fff.nvim ↔ snacks.picker bridge.
-- Trimmed port of madmaxieee/fff-snacks.nvim: source specs only, no setup
-- plumbing, no :FFFSnacks command. Pass opts per call.

local M = {}

local staged_status = {
  staged_new = true,
  staged_modified = true,
  staged_deleted = true,
  renamed = true,
}

local status_map = {
  untracked = "untracked",
  modified = "modified",
  deleted = "deleted",
  renamed = "renamed",
  staged_new = "added",
  staged_modified = "modified",
  staged_deleted = "deleted",
  ignored = "ignored",
  unknown = "untracked",
}

-- Relative path of the current buffer, for fff frecency deprioritization.
local function get_current_file(base_path)
  local buf = vim.api.nvim_get_current_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return nil
  end
  local stat = vim.uv.fs_stat(name)
  if not stat or stat.type ~= "file" then
    return nil
  end
  local abs = vim.fn.resolve(vim.fn.fnamemodify(name, ":p"))
  local base = vim.fn.resolve(base_path)
  local escaped = base:gsub("([%%^$()%.%[%]*+%-?])", "%%%1")
  local rel = abs:gsub("^" .. escaped .. "/", "")
  if rel == "" or rel == abs then
    return nil
  end
  return rel
end

local function format_file_git_status(item, picker)
  local ret = {}
  local status = item.status
  local hl = "SnacksPickerGitStatus"
  if status.unmerged then
    hl = "SnacksPickerGitStatusUnmerged"
  elseif status.staged then
    hl = "SnacksPickerGitStatusStaged"
  else
    hl = "SnacksPickerGitStatus" .. status.status:sub(1, 1):upper() .. status.status:sub(2)
  end
  local icon = picker.opts.icons.git[status.status]
  if status.staged then
    icon = picker.opts.icons.git.staged
  end
  local text_icon = status.status:sub(1, 1):upper()
  text_icon = status.status == "untracked" and "?"
    or status.status == "ignored" and "!"
    or text_icon
  ret[#ret + 1] = { icon, hl }
  ret[#ret + 1] = { " ", virtual = true }
  ret[#ret + 1] = {
    col = 0,
    virt_text = { { text_icon, hl }, { " " } },
    virt_text_pos = "right_align",
    hl_mode = "combine",
  }
  return ret
end

local find_files_source = {
  title = "FFFiles",
  live = true,
  formatters = { file = { filename_first = true } },
  finder = function(opts, ctx)
    local file_picker = require("fff.file_picker")
    if not file_picker.is_initialized() then
      if not file_picker.setup() then
        vim.notify("fff_snacks: failed to initialize file picker", vim.log.levels.ERROR)
        return {}
      end
    end

    local config = require("fff.conf").get()
    local merged = vim.tbl_deep_extend("force", config or {}, opts or {})
    local base = opts.cwd or vim.uv.cwd()
    if not base then
      return {}
    end

    local current = get_current_file(base)
    local result = file_picker.search_files(
      ctx.filter.search,
      current,
      opts.limit or merged.max_results,
      merged.max_threads,
      nil
    )

    local items = {}
    for _, fff_item in ipairs(result) do
      items[#items + 1] = {
        text = fff_item.name,
        file = fff_item.relative_path,
        cwd = base,
        score = fff_item.total_frecency_score,
        status = status_map[fff_item.git_status] and {
          status = status_map[fff_item.git_status],
          staged = staged_status[fff_item.git_status] or false,
          unmerged = fff_item.git_status == "unmerged",
        },
      }
    end
    return items
  end,
  format = function(item, picker)
    local ret = {}
    if item.label then
      ret[#ret + 1] = { item.label, "SnacksPickerLabel" }
      ret[#ret + 1] = { " ", virtual = true }
    end
    if item.status then
      vim.list_extend(ret, format_file_git_status(item, picker))
    else
      ret[#ret + 1] = { "  ", virtual = true }
    end
    vim.list_extend(ret, require("snacks").picker.format.filename(item, picker))
    if item.line then
      require("snacks").picker.highlight.format(item, item.line, ret)
      table.insert(ret, { " " })
    end
    return ret
  end,
}

local live_grep_source = {
  title = "FFF Live Grep",
  format = "file",
  live = true,
  finder = function(opts, ctx)
    local file_picker = require("fff.file_picker")
    if not file_picker.is_initialized() then
      if not file_picker.setup() then
        vim.notify("fff_snacks: failed to initialize file picker", vim.log.levels.ERROR)
        return {}
      end
    end

    opts = vim.deepcopy(opts) or {}
    local config = require("fff.conf").get()
    local merged = vim.tbl_deep_extend("force", config or {}, opts)
    local base = opts.cwd or vim.uv.cwd()
    if not base or ctx.filter.search == "" then
      return {}
    end

    opts.grep_mode = opts.grep_mode
      or vim.tbl_get(merged, "grep", "modes")
      or { "plain", "regex", "fuzzy" }

    local result = require("fff.grep").search(
      ctx.filter.search,
      0,
      opts.limit or merged.max_results,
      merged.grep_config,
      opts.grep_mode[1] or "plain"
    )

    local items = {}
    for idx, fff_item in ipairs(result.items) do
      fff_item.match_ranges = fff_item.match_ranges or {}
      local pos, end_pos
      if #fff_item.match_ranges == 0 then
        pos = { fff_item.line_number, 0 }
      else
        pos = { fff_item.line_number, fff_item.match_ranges[1][1] }
        end_pos = { fff_item.line_number, fff_item.match_ranges[1][2] }
      end
      local positions = {}
      for _, range in ipairs(fff_item.match_ranges) do
        for i = range[1] + 1, range[2] do
          positions[#positions + 1] = i
        end
      end
      items[#items + 1] = {
        idx = idx,
        cwd = base,
        file = fff_item.relative_path,
        line = fff_item.line_content,
        pos = pos,
        end_pos = end_pos,
        positions = positions,
        score = fff_item.total_frecency_score,
        text = ("%s:%d:%d:%s"):format(
          fff_item.relative_path,
          pos[1],
          pos[2],
          fff_item.line_content
        ),
      }
    end
    return items
  end,
  toggles = {
    _is_grep_mode_plain = { icon = "plain", value = true },
    _is_grep_mode_regex = { icon = "regex", value = true },
    _is_grep_mode_fuzzy = { icon = "fuzzy", value = true },
  },
  on_show = function(picker)
    local modes = picker.opts.grep_mode or { "plain", "regex", "fuzzy" }
    picker.opts._is_grep_mode_plain = modes[1] == "plain"
    picker.opts._is_grep_mode_regex = modes[1] == "regex"
    picker.opts._is_grep_mode_fuzzy = modes[1] == "fuzzy"
  end,
  actions = {
    cycle_grep_mode = function(picker)
      local modes = picker.opts.grep_mode or { "plain", "regex", "fuzzy" }
      local first = modes[1]
      table.remove(modes, 1)
      modes[#modes + 1] = first
      picker.opts.grep_mode = modes
      picker.opts._is_grep_mode_plain = modes[1] == "plain"
      picker.opts._is_grep_mode_regex = modes[1] == "regex"
      picker.opts._is_grep_mode_fuzzy = modes[1] == "fuzzy"
      picker:refresh()
    end,
  },
  win = {
    input = {
      keys = {
        ["<S-Tab>"] = { "cycle_grep_mode", mode = { "n", "i" }, nowait = true },
      },
    },
  },
}

function M.find_files(opts)
  Snacks.picker.pick(vim.tbl_deep_extend("force", find_files_source, opts or {}))
end

function M.live_grep(opts)
  Snacks.picker.pick(vim.tbl_deep_extend("force", live_grep_source, opts or {}))
end

function M.grep_word(opts)
  local merged = vim.tbl_deep_extend("force", live_grep_source, opts or {}, {
    search = function(picker)
      return picker:word()
    end,
  })
  Snacks.picker.pick(merged)
end

return M
