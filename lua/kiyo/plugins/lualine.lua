return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    local auto = require("lualine.themes.auto")
    local utils = require("kiyo.utils.lualine-utils")

    -- Setup highlight groups
    utils.setup_highlights()

    -- Configure theme
    local theme = utils.configure_theme(auto)

    -- Configure options
    opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
      theme = theme,
      component_separators = "",
      section_separators = "",
      globalstatus = true,
      disabled_filetypes = { statusline = {}, winbar = {} },
    })

    -- Configure sections
    opts.sections = {
      lualine_a = {
        {
          "mode",
          icon = "  ",
          color = function()
            local mode_color = {
              n = utils.colors.blue,
              i = utils.colors.green,
              v = utils.colors.mauve,
              ["\22"] = utils.colors.red, -- Visual block mode (<C-v>)
              V = utils.colors.yellow,
              c = utils.colors.peach,
              no = utils.colors.blue,
              s = utils.colors.teal,
              S = utils.colors.teal,
              ["\19"] = utils.colors.teal, -- Select block mode (<C-s>)
              ic = utils.colors.green,
              R = utils.colors.red,
              Rv = utils.colors.red,
              cv = utils.colors.peach,
              ce = utils.colors.peach,
              r = utils.colors.red,
              rm = utils.colors.sky,
              ["r?"] = utils.colors.sky,
              ["!"] = utils.colors.flamingo,
              t = utils.colors.lavender,
            }
            return { fg = mode_color[vim.fn.mode()] or utils.colors.text, bg = "none", gui = "bold" }
          end,
          padding = { left = 0, right = 0 },
        },
      },

      lualine_b = {
        utils.separator(),
        { "branch", color = { bg = "none" } },
        {
          "diff",
          colored = true,
          diff_color = {
            added = { fg = utils.colors.teal, bg = "none", gui = "bold" },
            modified = { fg = utils.colors.yellow, bg = "none", gui = "bold" },
            removed = { fg = utils.colors.red, bg = "none", gui = "bold" },
          },
          symbols = { added = "+", modified = "~", removed = "-" },
          padding = { left = 1, right = 0 },
        },
      },

      lualine_c = {
        utils.separator(),
        {
          "filename",
          path = 3, -- 0: Just the filename, 1: Relative path, 2: Absolute path, 3: Absolute path, with tilde as the home directory
          color = { fg = utils.colors.green, bg = "none", gui = "bold" },
          padding = { left = 1, right = 1 },
          symbols = { modified = "  ", readonly = " 󰌾 ", unnamed = " 󰟢 " },
        },
      },

      lualine_x = {
        {
          utils.macro_recording,
          cond = function()
            return vim.fn.reg_recording() ~= ""
          end,
          color = { fg = "#ff0000" },
        },
        {
          function()
            return "│"
          end,
          cond = function()
            return vim.fn.reg_recording() ~= ""
          end,
          color = { fg = utils.colors.surface0, bg = "NONE", gui = "bold" },
          padding = { left = 0, right = 1 },
        },
        {
          utils.lazy_updates,
          cond = utils.lazy_has_updates,
          color = { fg = "#ff9e64" },
        },
        {
          function()
            return "│"
          end,
          cond = utils.lazy_has_updates,
          color = { fg = utils.colors.surface0, bg = "NONE", gui = "bold" },
          padding = { left = 1, right = 1 },
        },
        {
          "fileformat",
          color = { fg = utils.colors.yellow, bg = "none", gui = "bold" },
          symbols = {
            unix = "",
            dos = "",
            mac = "",
          },
          padding = { left = 0, right = 0 },
        },
        {
          "encoding",
          color = { fg = utils.colors.yellow, bg = "none", gui = "bold" },
          padding = { left = 1, right = 1 },
        },
        {
          function()
            return "│"
          end,
          color = { fg = utils.colors.surface0, bg = "NONE", gui = "bold" },
          padding = { left = 0, right = 0 },
        },
        {
          function()
            return utils.build_lsp_status()
          end,
          color = { fg = utils.colors.blue, bg = "none" },
          padding = { left = 0, right = 0 },
        },
      },

      lualine_y = {
        utils.separator(),
        {
          "diagnostics",
          sources = { "nvim_diagnostic", "coc" },
          sections = { "error", "warn", "info", "hint" },
          diagnostics_color = {
            error = utils.diagnostic_color_error,
            warn = utils.diagnostic_color_warn,
            info = utils.diagnostic_color_info,
            hint = utils.diagnostic_color_hint,
          },
          symbols = {
            error = "󰅚 ",
            warn = "󰀪 ",
            info = "󰋽 ",
            hint = "󰌶 ",
          },
          colored = true,
          update_in_insert = false,
          always_visible = true,
          padding = { left = 0, right = 0 },
        },
      },

      lualine_z = {
        utils.separator(),
        {
          "progress",
          color = { fg = utils.colors.peach, bg = "none", gui = "bold" },
          padding = { left = 0, right = 0 },
        },
        {
          "location",
          color = { fg = utils.colors.sky, bg = "none", gui = "bold" },
          padding = { left = 1, right = 0 },
        },
      },
    }

    return opts
  end,
}
