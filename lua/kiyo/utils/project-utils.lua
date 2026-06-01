-- Utilities for detecting project configurations

local M = {}

-- Check if a file exists
function M.file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "file"
end

-- Find config file in project hierarchy
function M.find_config_file(filenames, start_path)
  start_path = start_path or vim.fn.getcwd()

  if type(filenames) == "string" then
    filenames = { filenames }
  end

  for _, filename in ipairs(filenames) do
    local found = vim.fs.find(filename, {
      upward = true,
      path = start_path,
      limit = 1,
    })
    if #found > 0 then
      return found[1]
    end
  end
  return nil
end

-- Get the default config directory
function M.get_default_config_dir()
  return vim.fn.stdpath("config") .. "/rules"
end

-- Default rule file paths
function M.get_default_biome_config()
  return M.get_default_config_dir() .. "/biome.jsonc"
end

function M.get_default_selene_config()
  return M.get_default_config_dir() .. "/selene.toml"
end

function M.get_default_shellcheckrc()
  return M.get_default_config_dir() .. "/.shellcheckrc"
end

function M.get_default_ruff_config()
  return M.get_default_config_dir() .. "/ruff.toml"
end

-- Biome config files
M.BIOME_CONFIG_FILES = { "biome.json", "biome.jsonc" }

-- ESLint config files
M.ESLINT_CONFIG_FILES = {
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.json",
  ".eslintrc.yaml",
  ".eslintrc.yml",
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
}

-- Prettier config files
M.PRETTIER_CONFIG_FILES = {
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.yml",
  ".prettierrc.yaml",
  ".prettierrc.json5",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
}

-- Check if project has biome config
function M.has_biome_config(dirname)
  dirname = dirname or vim.fn.getcwd()
  return M.find_config_file(M.BIOME_CONFIG_FILES, dirname) ~= nil
end

-- Check if project has ESLint config
function M.has_eslint_config(dirname)
  dirname = dirname or vim.fn.getcwd()
  return M.find_config_file(M.ESLINT_CONFIG_FILES, dirname) ~= nil
end

-- Check if project has Prettier config
function M.has_prettier_config(dirname)
  dirname = dirname or vim.fn.getcwd()
  return M.find_config_file(M.PRETTIER_CONFIG_FILES, dirname) ~= nil
end

-- Get biome config path (project or default)
function M.get_biome_config_path(dirname)
  dirname = dirname or vim.fn.getcwd()

  -- Try project config first
  local project_config = M.find_config_file(M.BIOME_CONFIG_FILES, dirname)
  if project_config then
    return project_config
  end

  -- Fallback to default config
  local default_config = M.get_default_biome_config()
  if M.file_exists(default_config) then
    return default_config
  end

  return nil
end

-- Directory of the resolved biome config (what biome's --config-path expects)
function M.get_biome_config_dir(dirname)
  local cfg = M.get_biome_config_path(dirname)
  return cfg and vim.fn.fnamemodify(cfg, ":h") or nil
end

-- Generic config-path resolver: project config wins, fallback to a default
function M.resolve_config_path(project_files, default_path, dirname)
  dirname = dirname or vim.fn.getcwd()
  local project_config = M.find_config_file(project_files, dirname)
  if project_config then
    return project_config
  end
  if default_path and M.file_exists(default_path) then
    return default_path
  end
  return nil
end

-- Per-buffer memoization with auto-invalidation on cwd/buffer-rename
-- Keys touched here are tracked so setup_cache_invalidation() can clear them.
M._cache_keys = {}

function M.cached(bufnr, key, compute)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  M._cache_keys[key] = true
  local cached = vim.b[bufnr][key]
  if cached ~= nil then
    return cached
  end
  local result = compute()
  vim.b[bufnr][key] = result
  return result
end

function M.setup_cache_invalidation()
  local group = vim.api.nvim_create_augroup("project-utils-cache", { clear = true })

  local function clear_buf(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    for key in pairs(M._cache_keys) do
      vim.b[bufnr][key] = nil
    end
  end

  -- File renamed under the buffer: project context may have changed
  vim.api.nvim_create_autocmd("BufFilePost", {
    group = group,
    callback = function(args)
      clear_buf(args.buf)
    end,
  })

  -- cwd changed: every buffer's project context may be different now
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        clear_buf(bufnr)
      end
    end,
  })
end

-- Detect formatter preference for JS/TS files
function M.detect_js_formatter(dirname)
  dirname = dirname or vim.fn.expand("%:p:h")

  -- Priority: biome > prettier
  if M.has_biome_config(dirname) then
    return "biome"
  elseif M.has_prettier_config(dirname) then
    return "prettier"
  else
    -- Default to biome
    return "biome"
  end
end

-- Detect linter preference for JS/TS files
function M.detect_js_linter(dirname)
  dirname = dirname or vim.fn.expand("%:p:h")

  -- Priority: eslint > biome
  if M.has_eslint_config(dirname) then
    return "eslint"
  else
    return "biome"
  end
end

-- Create a user command to show project detection info
function M.setup_commands()
  vim.api.nvim_create_user_command("ProjectInfo", function()
    local dirname = vim.fn.expand("%:p:h")
    local lines = {
      "=== Project Detection Info ===",
      "",
      "Current directory: " .. dirname,
      "",
      "Formatter configs found:",
      "  Biome: " .. (M.has_biome_config(dirname) and "✓" or "✗"),
      "  Prettier: " .. (M.has_prettier_config(dirname) and "✓" or "✗"),
      "",
      "Linter configs found:",
      "  ESLint: " .. (M.has_eslint_config(dirname) and "✓" or "✗"),
      "  Biome: " .. (M.has_biome_config(dirname) and "✓" or "✗"),
      "",
      "Detected preferences for JS/TS:",
      "  Formatter: " .. M.detect_js_formatter(dirname),
      "  Linter: " .. M.detect_js_linter(dirname),
      "",
      "Default config dir: " .. M.get_default_config_dir(),
    }

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = "nofile"

    local width = 60
    local height = #lines
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      col = (vim.o.columns - width) / 2,
      row = (vim.o.lines - height) / 2,
      style = "minimal",
      border = "rounded",
      title = " Project Info ",
      title_pos = "center",
    })

    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
  end, { desc = "Show project configuration detection info" })
end

return M
