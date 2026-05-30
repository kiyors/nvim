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
  local default_config = M.get_default_config_dir() .. "/biome.jsonc"
  if M.file_exists(default_config) then
    return default_config
  end

  return nil
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
