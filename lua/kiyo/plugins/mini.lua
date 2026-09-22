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

      -- Scrub vim.NIL from LSP fileOperations filter schemes to prevent crash during file sync
      local sanitize_lsp_file_operations = function()
        for _, client in ipairs(vim.lsp.get_clients()) do
          local file_ops = vim.tbl_get(client, "server_capabilities", "workspace", "fileOperations")
          if type(file_ops) == "table" then
            for _, op in pairs(file_ops) do
              if type(op) == "table" and type(op.filters) == "table" then
                for _, filter in ipairs(op.filters) do
                  if
                    filter.scheme == vim.NIL
                    or (filter.scheme ~= nil and type(filter.scheme) ~= "string")
                  then
                    filter.scheme = nil
                  end
                end
              end
            end
          end
        end
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesExplorerOpen",
        callback = sanitize_lsp_file_operations,
      })

      -- Buffer-local mappings for mini.files
      local show_dotfiles = true
      local filter_show = function(_)
        return true
      end
      local filter_hide = function(fs_entry)
        return not vim.startswith(fs_entry.name, ".")
      end

      local toggle_dotfiles = function()
        show_dotfiles = not show_dotfiles
        local new_filter = show_dotfiles and filter_show or filter_hide
        MiniFiles.refresh({ content = { filter = new_filter } })
      end

      local map_split = function(buf_id, lhs, direction)
        local rhs = function()
          local cur_target = MiniFiles.get_explorer_state().target_window
          local new_target = vim.api.nvim_win_call(cur_target, function()
            vim.cmd(direction .. " split")
            return vim.api.nvim_get_current_win()
          end)
          MiniFiles.set_target_window(new_target)
          MiniFiles.go_in({ close_on_file = true })
        end
        vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = "Split " .. direction })
      end

      local set_cwd = function()
        local cur_entry = MiniFiles.get_fs_entry()
        if not cur_entry then
          return
        end
        local dir = cur_entry.fs_type == "directory" and cur_entry.path
          or vim.fs.dirname(cur_entry.path)
        vim.fn.chdir(dir)
        vim.notify("Changed working directory to: " .. dir, vim.log.levels.INFO)
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          local buf_id = args.data.buf_id
          vim.keymap.set(
            "n",
            "g.",
            toggle_dotfiles,
            { buffer = buf_id, desc = "Toggle hidden files" }
          )
          vim.keymap.set(
            "n",
            "<Esc>",
            MiniFiles.close,
            { buffer = buf_id, desc = "Close explorer" }
          )
          vim.keymap.set("n", "g~", set_cwd, { buffer = buf_id, desc = "Set cwd to directory" })
          map_split(buf_id, "<C-s>", "belowright horizontal")
          map_split(buf_id, "<C-v>", "belowright vertical")
        end,
      })

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
