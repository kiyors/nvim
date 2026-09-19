return {
  {
    "echasnovski/mini.icons",
    enabled = true,
    opts = {},
    lazy = true,
  },
  {
    "echasnovski/mini.ai",
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ -- code block
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
          d = { "%f[%d]%d+" }, -- digits
          e = { -- Word with case
            {
              "%u[%l%d]+%f[^%l%d]",
              "%f[%S][%l%d]+%f[^%l%d]",
              "%f[%P][%l%d]+%f[^%l%d]",
              "^[%l%d]+%f[^%l%d]",
            },
            "^().*()$",
          },
          g = { -- Buffer text object without LazyVim
            a = "^[^%s]+$", -- whole buffer content
            i = "^[^%s]+$", -- inner buffer content
          },
          u = ai.gen_spec.function_call(), -- u for "Usage"
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
        },
      }
    end,
    config = function(_, opts)
      require("mini.ai").setup(opts)
    end,
  },

  {
    "echasnovski/mini.files",
    event = "VeryLazy",
    config = function()
      local MiniFiles = require("mini.files")
      MiniFiles.setup({
        mappings = {
          go_in = "<CR>", -- Map both Enter and L to enter directories or open files
          go_in_plus = "L",
          go_out = "-",
          go_out_plus = "H",
        },
      })
      vim.keymap.set(
        "n",
        "<leader>fe",
        "<cmd>lua MiniFiles.open()<CR>",
        { desc = "Toggle mini file explorer" }
      ) -- toggle file explorer
      vim.keymap.set("n", "<leader>e", function()
        MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
        MiniFiles.reveal_cwd()
      end, { desc = "Toggle into currently opened file" })
    end,
  },
  {
    "echasnovski/mini.move",
    version = false,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("mini.move").setup({
        -- module mappings. use `''` (empty string) to disable one.
        mappings = {
          -- move visual selection in visual mode. defaults are alt (meta) + hjkl.
          left = "<m-h>",
          right = "<m-l>",
          down = "<m-j>",
          up = "<m-k>",

          -- move current line in normal mode
          line_left = "<m-h>",
          line_right = "<m-l>",
          line_down = "<m-j>",
          line_up = "<m-k>",
        },

        -- options which control moving behavior
        options = {
          -- automatically reindent selection during linewise vertical move
          reindent_linewise = true,
        },
      })
    end,
  },
  {
    "echasnovski/mini.trailspace",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      {
        "<leader>cw",
        function()
          require("mini.trailspace").trim()
          require("mini.trailspace").trim_last_lines()
        end,
        desc = "Trim trailing whitespace and empty lines",
      },
    },
  },
}
