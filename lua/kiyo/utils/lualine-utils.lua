-- lua/kiyo/utils/lualine-utils.lua
local M = {}

-- Color configuration (Catppuccin Mocha palette)
M.colors = {
  rosewater = "#f5e0dc",
  flamingo = "#f2cdcd",
  pink = "#f5c2e7",
  mauve = "#cba6f7",
  red = "#f38ba8",
  maroon = "#eba0ac",
  peach = "#fab387",
  yellow = "#f9e2af",
  green = "#a6e3a1",
  teal = "#94e2d5",
  sky = "#89dceb",
  sapphire = "#74c7ec",
  blue = "#89b4fa",
  lavender = "#b4befe",
  text = "#cdd6f4",
  subtext1 = "#bac2de",
  subtext0 = "#a6adc8",
  overlay2 = "#9399b2",
  overlay1 = "#7f849c",
  overlay0 = "#6c7086",
  surface2 = "#585b70",
  surface1 = "#45475a",
  surface0 = "#313244",
  base = "#1e1e2e",
  mantle = "#181825",
  crust = "#11111b",
}

-- Separator component
function M.separator()
  return {
    function()
      return "│"
    end,
    color = { fg = M.colors.overlay0, bg = "NONE" },
    padding = { left = 1, right = 1 },
  }
end

-- Macro recording component
function M.macro_recording()
  local recording_register = vim.fn.reg_recording()
  return recording_register ~= "" and ("󰑊 Recording @" .. recording_register) or ""
end

-- Lazy updates component
function M.lazy_updates()
  return require("lazy.status").updates()
end

-- Check if lazy has updates
function M.lazy_has_updates()
  local ok, lazy_status = pcall(require, "lazy.status")
  return ok and lazy_status.has_updates()
end

-- Get active LSP clients for current buffer
function M.get_lsp_clients()
  local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
  local exclude_list = { "null-ls", "copilot", "GitHub Copilot" }
  local clients = {}
  local unique_clients = {}

  for _, client in pairs(buf_clients) do
    local should_exclude = false
    for _, excluded in ipairs(exclude_list) do
      if client.name:lower():find(excluded:lower()) then
        should_exclude = true
        break
      end
    end

    if not should_exclude and not unique_clients[client.name] then
      unique_clients[client.name] = true
      table.insert(clients, client.name)
    end
  end

  return clients
end

-- Get active linters for current buffer
function M.get_linters()
  local buf_ft = vim.bo.filetype
  local lint_ok, lint = pcall(require, "lint")

  if not lint_ok or not lint.linters_by_ft then
    return {}
  end

  local configured_linters = lint.linters_by_ft[buf_ft]
  if not configured_linters then
    return {}
  end

  -- Handle function-based linter configuration
  if type(configured_linters) == "function" then
    local ok, result = pcall(configured_linters)
    if ok and result then
      configured_linters = result
    else
      return {}
    end
  end

  -- Normalize to table and extract linter names
  local linters = {}
  local unique_linters = {}
  if type(configured_linters) == "table" then
    for _, linter in ipairs(configured_linters) do
      if type(linter) == "string" and not unique_linters[linter] then
        unique_linters[linter] = true
        table.insert(linters, linter)
      end
    end
  elseif type(configured_linters) == "string" then
    table.insert(linters, configured_linters)
  end

  return linters
end

-- Get active formatters for current buffer
function M.get_formatters()
  local buf_ft = vim.bo.filetype
  local conform_ok, conform = pcall(require, "conform")

  if not conform_ok or not conform.formatters_by_ft then
    return {}
  end

  local configured_formatters = conform.formatters_by_ft[buf_ft]
  if not configured_formatters then
    return {}
  end

  -- Handle function-based formatter configuration
  if type(configured_formatters) == "function" then
    local ok, result = pcall(configured_formatters)
    if ok and result then
      configured_formatters = result
    else
      return {}
    end
  end

  -- Normalize to table and extract formatter names
  local formatters = {}
  local unique_formatters = {}
  if type(configured_formatters) == "table" then
    for _, formatter in ipairs(configured_formatters) do
      if type(formatter) == "string" then
        -- Clean up formatter names (remove _for_project suffix)
        local clean_name = formatter:gsub("_for_project$", "")
        if not unique_formatters[clean_name] then
          unique_formatters[clean_name] = true
          table.insert(formatters, clean_name)
        end
      end
    end
  end

  return formatters
end

-- Build the complete LSP status string
function M.build_lsp_status()
  local lsp_clients = M.get_lsp_clients()
  local linters = M.get_linters()
  local formatters = M.get_formatters()

  local parts = {}

  -- LSP Clients
  if #lsp_clients > 0 then
    local lsp_str = " 󰒋 " .. table.concat(lsp_clients, ", ")
    table.insert(parts, lsp_str)
  end

  -- Formatters
  if #formatters > 0 then
    local formatter_str = "󰉿 " .. table.concat(formatters, ", ")
    table.insert(parts, formatter_str)
  end

  -- Linters
  if #linters > 0 then
    local linter_str = "󰁨 " .. table.concat(linters, ", ")
    table.insert(parts, linter_str)
  end

  -- Return appropriate message
  if #parts == 0 then
    return " 󰒋 No servers"
  end

  return table.concat(parts, ", ")
end

-- Component wrapper for LSP status with proper color
function M.lsp_status_component()
  return {
    function()
      return M.build_lsp_status()
    end,
    color = { fg = M.colors.blue, bg = "NONE" },
    padding = { left = 1, right = 1 },
  }
end

-- Diagnostics color functions
function M.diagnostic_color_error()
  local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  return { fg = count > 0 and M.colors.red or M.colors.green, bg = "NONE", gui = "bold" }
end

function M.diagnostic_color_warn()
  local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
  return { fg = count > 0 and M.colors.yellow or M.colors.green, bg = "NONE", gui = "bold" }
end

function M.diagnostic_color_info()
  local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  return { fg = count > 0 and M.colors.blue or M.colors.green, bg = "NONE", gui = "bold" }
end

function M.diagnostic_color_hint()
  local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
  return { fg = count > 0 and M.colors.teal or M.colors.green, bg = "NONE", gui = "bold" }
end

-- Setup highlight groups
function M.setup_highlights()
  vim.api.nvim_set_hl(0, "LualineLspColor", { fg = M.colors.blue, bg = "NONE", bold = true })
  vim.api.nvim_set_hl(0, "LualineFormatterColor", { fg = M.colors.peach, bg = "NONE", bold = true })
  vim.api.nvim_set_hl(0, "LualineLinterColor", { fg = M.colors.yellow, bg = "NONE", bold = true })
end

-- Configure theme to remove backgrounds
function M.configure_theme(theme)
  local modes = { "normal", "insert", "visual", "replace", "command", "inactive", "terminal" }
  for _, mode in ipairs(modes) do
    if theme[mode] then
      if theme[mode].a then
        theme[mode].a.bg = M.colors.surface0
      end
      if theme[mode].b then
        theme[mode].b.bg = "NONE"
      end
      if theme[mode].c then
        theme[mode].c.bg = "NONE"
      end
    end
  end
  return theme
end

return M
