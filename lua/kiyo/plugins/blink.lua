-- Root of this Neovim config, derived from this file's own path
-- (…/config/nvim/lua/kiyo/plugins/blink.lua -> …/config/nvim).
--
-- Prefer `$XDG_CONFIG_HOME/nvim` so a user who has symlinked the directory
-- into their XDG config dir gets the same answer as one who checked the repo
-- out in place. Falls back to resolving the file path, which covers the Nix
-- out-of-store symlink layout where this file is read through a symlink.
local nvim_dir = vim.fs.normalize(vim.fn.stdpath("config"))
if vim.fn.isdirectory(nvim_dir .. "/lua") == 0 then
  nvim_dir = vim.fs.dirname(
    vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))))
  )
end

return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  dependencies = {
    "rafamadriz/friendly-snippets",
    "folke/lazydev.nvim",
    "Kaiser-Yang/blink-cmp-dictionary",
  },
  version = "1.*",
  opts_extend = {
    "sources.completion.enabled_providers",
    "sources.compat",
    "sources.default",
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = "enter",
      ["<C-J>"] = { "select_next", "snippet_forward", "fallback" },
      ["<C-K>"] = { "select_prev", "snippet_backward", "fallback" },
      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide", "fallback" },
      ["<C-y>"] = { "select_and_accept" },
    },

    appearance = {
      nerd_font_variant = "mono",
      kind_icons = {
        Copilot = " ",
        Text = "󰉿",
        Method = "󰊕",
        Function = "󰊕",
        Constructor = "󰒓",

        Field = "󰜢",
        Variable = "󰆦",
        Property = "󰖷",

        Class = "󱡠",
        Interface = "󱡠",
        Struct = "󱡠",
        Module = "󰅩",

        Unit = "󰪚",
        Value = "󰦨",
        Enum = "󰦨",
        EnumMember = "󰦨",

        Keyword = "󰻾",
        Constant = "󰏿",

        Snippet = "󱄽",
        Color = "󰏘",
        File = "󰈔",
        Reference = "󰬲",
        Folder = "󰉋",
        Event = "󱐋",
        Operator = "󰪚",
        TypeParameter = "󰬛",
      },
    },

    signature = {
      enabled = true,
    },

    completion = {

      list = {
        selection = {
          preselect = function(_)
            return not require("blink.cmp").snippet_active({ direction = 1 })
          end,
          auto_insert = function(_)
            return vim.bo.filetype ~= "markdown"
          end,
        },
      },

      accept = {
        create_undo_point = true,
        resolve_timeout_ms = 500,
        auto_brackets = {
          enabled = true,
          default_brackets = { "(", ")" },
          override_brackets_for_filetypes = {},
          kind_resolution = {
            enabled = true,
            blocked_filetypes = { "typescriptreact", "javascriptreact", "vue" },
          },
          semantic_token_resolution = {
            enabled = true,
            blocked_filetypes = { "java" },
            timeout_ms = 400,
          },
        },
      },

      documentation = {
        window = {
          border = nil,
          scrollbar = false,
          winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
        },
        auto_show = true,
        auto_show_delay_ms = 500,
      },

      menu = {
        auto_show = true,
        draw = {
          treesitter = {
            "lsp",
          },
          columns = {
            -- { "label", "label_detail", "label_description", gap = 1 },
            { "kind_icon" },
            { "label", "label_description", gap = 1 },
            { "kind" },
            { "source_name" },
          },
          components = {
            kind_icon = {
              ellipsis = false,
              text = function(ctx)
                return ctx.kind_icon .. ctx.icon_gap
              end,
              highlight = function(ctx)
                return ctx.kind_hl
              end,
            },

            kind = {
              ellipsis = false,
              width = { fill = true },
              text = function(ctx)
                return ctx.kind
              end,
              highlight = function(ctx)
                return ctx.kind_hl
              end,
            },

            label = {
              width = { fill = true, max = 60 },
              text = function(ctx)
                return ctx.label .. ctx.label_detail
              end,
              highlight = function(ctx)
                -- label and label details
                local highlights = {
                  {
                    0,
                    #ctx.label,
                    group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
                  },
                }
                if ctx.label_detail then
                  table.insert(highlights, {
                    #ctx.label,
                    #ctx.label + #ctx.label_detail,
                    group = "BlinkCmpLabelDetail",
                  })
                end

                -- characters matched on the label by the fuzzy matcher
                for _, idx in ipairs(ctx.label_matched_indices) do
                  table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
                end

                return highlights
              end,
            },

            label_description = {
              width = { max = 30 },
              text = function(ctx)
                return ctx.label_description
              end,
              highlight = "BlinkCmpLabelDescription",
            },

            source_name = {
              width = { max = 30 },
              text = function(ctx)
                return ctx.source_name
              end,
              highlight = "BlinkCmpSource",
            },

            source_id = {
              width = { max = 30 },
              text = function(ctx)
                return ctx.source_id
              end,
              highlight = "BlinkCmpSource",
            },
          },
        },
      },

      ghost_text = {
        enabled = true,
        show_with_selection = true,
      },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "lazydev", "dictionary" },
      providers = {
        lsp = {
          name = "lsp",
          enabled = true,
          score_offset = 100, -- the higher the number, the higher the priority
        },
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 20,
          max_items = 8,
          min_keyword_length = 3,
        },
        dictionary = {
          module = "blink-cmp-dictionary",
          name = "Dict",
          min_keyword_length = 3,
          opts = {
            -- Optional: explicitly force fallback mode
            -- (By default, fallback is used when fzf is not found)
            force_fallback = true,

            -- Resolved from this file's own location rather than a hardcoded
            -- `~/dotfiles` path, so the config works wherever it is checked
            -- out and for anyone copying just `config/nvim`.
            dictionary_directories = { nvim_dir .. "/dictionaries" },
            dictionary_files = {
              nvim_dir .. "/spell/en.utf-8.add",
              nvim_dir .. "/spell/es.utf-8.add",
            },
          },
        },
      },
    },

    fuzzy = {
      implementation = "prefer_rust_with_warning",
    },
  },
}
