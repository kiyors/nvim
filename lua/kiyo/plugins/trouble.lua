return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = {
    modes = {
      diagnostics = {
        auto_close = false,
        auto_open = false,
      },
    },
    preview = {
      type = "main",
      scratch = false,
    },
    keys = {
      ["<c-x>"] = "jump_split",
      ["<c-v>"] = "jump_vsplit",
      ["<tab>"] = "jump",
    },
    win = {
      position = "bottom",
      size = 15,
    },
  },
  config = function(_, opts)
    require("trouble").setup(opts)
    local ok, Preview = pcall(require, "trouble.view.preview")
    if ok and Preview and Preview.open then
      local orig_open = Preview.open
      Preview.open = function(view, item, p_opts)
        local ret = orig_open(view, item, p_opts)
        if
          Preview.preview
          and Preview.preview.buf
          and vim.api.nvim_buf_is_valid(Preview.preview.buf)
        then
          local pbuf = Preview.preview.buf
          local pwin = Preview.preview.win
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(pbuf) and vim.api.nvim_win_is_valid(pwin) then
              pcall(function()
                local H = require("todo-comments.highlight")
                if vim.treesitter.highlighter.active[pbuf] then
                  local parser = vim.treesitter.get_parser(pbuf)
                  if parser then
                    parser:parse()
                  end
                end
                H.attach(pwin, true)
                H.highlight(pbuf, 0, vim.api.nvim_buf_line_count(pbuf))
              end)
            end
          end)
        end
        return ret
      end
    end
  end,
  lazy = true,
  specs = {
    "folke/snacks.nvim",
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts or {}, {
        picker = {
          actions = setmetatable({}, {
            __index = function(_, k)
              return require("trouble.sources.snacks").actions[k]
            end,
          }),
          win = {
            input = {
              keys = {
                ["<c-t>"] = {
                  "trouble_open",
                  mode = { "n", "i" },
                },
              },
            },
          },
        },
      })
    end,
  },
  keys = {
    {
      "<leader>xx",
      "<cmd>Trouble diagnostics toggle<cr>",
      desc = "Diagnostics (Trouble)",
    },
    {
      "<leader>xX",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    {
      "<leader>cs",
      "<cmd>Trouble symbols toggle focus=false<cr>",
      desc = "Symbols (Trouble)",
    },
    {
      "<leader>cl",
      "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
      desc = "LSP Definitions / references / ... (Trouble)",
    },
    {
      "<leader>xL",
      "<cmd>Trouble loclist toggle<cr>",
      desc = "Location List (Trouble)",
    },
    {
      "<leader>xQ",
      "<cmd>Trouble qflist toggle<cr>",
      desc = "Quickfix List (Trouble)",
    },
  },
}
