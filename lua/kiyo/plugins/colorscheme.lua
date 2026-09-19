-- IMPORTANT!: It is necessary to apply the colorscheme synchronously during
-- startup or the colors come out wrong.
--
-- There is something that automatically links Treesitter highlight
-- groups to generic ones on startup if custom colors or styles are not assigned
-- to Treesitter groups in time. For example `@variable.builtin` gets linked to
-- `TSVariableBuiltin` which gets linked to `Special`. Colors and styles applied
-- to the Treesitter groups after they are linked are ignored.

return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false, -- Load immediately
  priority = 1000, -- Ensure it loads before other plugins
  opts = {
    compile = {
      enabled = true,
      path = vim.fn.stdpath("cache") .. "/catppuccin",
    },
    flavour = "mocha", -- latte, frappe, macchiato, mocha
    background = { -- :h background
      light = "latte",
      dark = "mocha",
    },
    transparent_background = true, -- disables setting the background color.
    term_colors = true,
    float = {
      transparent = true, -- if you would like floating windows to *also* be transparent
    },
    styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
      comments = { "italic" },
      conditionals = { "italic" },
      loops = {},
      functions = { "italic" },
      keywords = { "italic" },
      strings = {},
      variables = {},
      numbers = {},
      booleans = {},
      properties = {},
      types = {},
      operators = {},
      -- miscs = {}, -- Uncomment to turn off hard-coded styles
    },
    integrations = {
      aerial = true,
      cmp = true,
      blink_cmp = true,
      flash = true,
      fzf = true,
      grug_far = true,
      gitsigns = true,
      headlines = true,
      illuminate = true,
      indent_blankline = { enabled = true },
      leap = true,
      lsp_trouble = true,
      mason = true,
      markdown = true,
      mini = true,
      native_lsp = true,
      lsp_styles = { -- Handles the style of specific lsp hl groups (see `:h lsp-highlight`).
        underlines = {
          errors = { "italic" },
          hints = { "italic" },
          warnings = { "italic" },
          information = { "italic" },
        },
        virtual_text = {
          errors = "italic",
          hints = { "italic" },
          information = { "italic" },
          ok = { "italic" },
          warnings = "italic",
        },
        inlay_hints = {
          background = false,
        },
      },
      navic = { enabled = true, custom_bg = "lualine" },
      neotest = true,
      neotree = true,
      noice = true,
      notify = true,
      semantic_tokens = true,
      snacks = true,
      treesitter = true,
      treesitter_context = true,
      which_key = true,
    },
    custom_highlights = function(colors)
      local utils = require("catppuccin.utils.colors")
      -- Soft, readable diff backgrounds (blend with base for theme-adaptive tints)
      local add_bg = utils.blend(colors.green, colors.base, 0.20)
      local del_bg = utils.blend(colors.red, colors.base, 0.20)
      local change_bg = utils.blend(colors.blue, colors.base, 0.20)
      local hunk_bg = utils.blend(colors.sapphire, colors.base, 0.16)

      return {
        -- Tree-sitter diff highlights
        ["@diff.plus"] = { fg = colors.green, bg = add_bg },
        ["@diff.minus"] = { fg = colors.red, bg = del_bg },
        ["@diff.delta"] = { fg = colors.yellow, bg = change_bg },
        ["@diff.plus.sign"] = { fg = colors.green, bg = add_bg, style = { "bold" } },
        ["@diff.minus.sign"] = { fg = colors.red, bg = del_bg, style = { "bold" } },
        ["@diff.location"] = { fg = colors.sapphire, bg = hunk_bg, style = { "bold" } },

        -- Classic Vim diff highlights
        ["DiffAdd"] = { bg = add_bg },
        ["DiffDelete"] = { bg = del_bg, fg = colors.red },
        ["DiffChange"] = { bg = change_bg },
        ["DiffText"] = { bg = utils.blend(colors.blue, colors.base, 0.35), style = { "bold" } },
      }
    end,
    -- custom_highlights = function(colors)
    --   return {
    --     ["Boolean"] = { style = { "italic" } },
    --     ["Include"] = { style = {} }, -- disable italic
    --     ["Interface"] = { fg = colors.flamingo },
    --     ["@module"] = { style = {} }, -- some `Include` items are also linked to `@module`
    --     ["StorageClass"] = { fg = colors.yellow, style = { "italic" } }, -- `&`, `&mut`, and `ref` in Rust
    --     ["@function.builtin"] = { style = { "italic" } },
    --     ["@keyword.import"] = { fg = colors.mauve, style = { "italic" } }, -- `use` and `as` in Rust
    --     ["@parameter"] = { style = {} }, -- disable italic
    --     ["@variable.builtin"] = { style = { "italic" } }, -- italic for `self` in Rust
    --
    --     -- messages from vim.notify
    --     ["ErrorMsg"] = { style = {} },
    --     ["WarningMsg"] = { style = {} },
    --
    --     -- Highlights used by tiny-inline-diagnostic
    --     ["DiagnosticError"] = { style = {} }, -- disable italic style
    --     ["DiagnosticWarn"] = { style = {} },
    --     ["DiagnosticInfo"] = { style = {} },
    --     ["DiagnosticHint"] = { style = {} },
    --
    --     -- Link lsp groups more precisely
    --     ["@lsp.type.interface"] = { link = "Interface" },
    --
    --     -- Modify semantic highlighting to make highlighting for strings transparent.
    --     -- This prevents semantic highlighting from overriding highlighting from
    --     -- treesitter language injections, like my sqlx::query!() injection.
    --     ["@lsp.type.string"] = {},
    --
    --     -- I'm using @markup.normal in my sqlx injection for nodes that the
    --     -- sql queries don't otherwise highlight. This makes those nodes
    --     -- white, instead of using the green highlighting used for strings.
    --     ["@markup.normal"] = { link = "Normal" },
    --   }
    -- end,
  },
  config = function(_, opts)
    -- Valid flavours are: 'latte', 'frappe', 'macchiato', 'mocha'
    local dark_flavour = "mocha"
    local light_flavour = "latte"

    vim.g.catppuccin_flavour = vim.o.background == "light" and light_flavour or dark_flavour

    require("catppuccin").setup(opts) -- pass the opts to the plugin

    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup

    local group = augroup("custom_catppuccin_hooks", { clear = true })

    -- Switch colorscheme flavours on background setting change.
    autocmd("OptionSet", {
      group = group,
      pattern = "background",
      callback = function()
        if vim.g.colors_name == "catppuccin" then
          vim.cmd.Catppuccin(vim.v.option_new == "light" and light_flavour or dark_flavour)
        end
      end,
    })

    vim.cmd.colorscheme("catppuccin-nvim")
  end,
}
