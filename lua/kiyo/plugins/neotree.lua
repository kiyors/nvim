return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons", -- optional, but recommended
    "kiyors/neotree-file-nesting-config",
  },
  ---@module 'neo-tree'
  ---@type neotree.Config
  opts = {
    sources = { "filesystem", "buffers", "git_status" },
    open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
    filesystem = {
      bind_to_cwd = false,
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = true,
        hide_ignored = true,
        hide_hidden = true,
        hide_by_name = {}, -- Empty by default, so nothing is hidden
        hide_by_pattern = {},
        always_show = {
          ".gitignored",
          ".gitignore",
          ".github",
        },
        always_show_by_pattern = {
          ".env*",
        },
        never_show = {
          ".DS_Store",
        },
        never_show_by_pattern = {},
      },
    },
    window = {
      position = "right",
      width = 32,
      mappings = {
        ["l"] = function(state)
          local node = state.tree:get_node()
          if node.type == "directory" or (node:has_children() and not node:is_expanded()) then
            require("neo-tree.sources.filesystem.commands").toggle_node(state)
          else
            require("neo-tree.sources.common.commands").open(state)
          end
        end,
        ["h"] = function(state)
          local node = state.tree:get_node()
          if node:is_expanded() then
            require("neo-tree.sources.filesystem.commands").toggle_node(state)
          else
            require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
          end
        end,
        ["<space>"] = "none",
        ["H"] = "toggle_hidden", -- Toggle dotfiles and gitignored files
        ["Y"] = {
          function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg("+", path, "c")
          end,
          desc = "Copy Path to Clipboard",
        },
        ["O"] = {
          function(state)
            require("lazy.util").open(state.tree:get_node().path, { system = true })
          end,
          desc = "Open with System Application",
        },
        ["P"] = { "toggle_preview", config = { use_float = false } },
        ["a"] = {
          "add",
          config = {
            show_path = "relative", -- "none" (default), "relative", "absolute"
          },
        },
        ["A"] = {
          "add_directory",
          config = {
            show_path = "relative", -- "none" (default), "relative", "absolute"
          },
        },
        ["R"] = "refresh",
      },
    },
    default_component_configs = {
      indent = {
        with_expanders = nil, -- if nil and file nesting is enabled, will enable expanders
        expander_collapsed = "",
        expander_expanded = "",
        expander_highlight = "NeoTreeExpander",
      },
      git_status = {
        symbols = {
          unstaged = "󰄱",
          staged = "󰱒",
        },
      },
    },
  },
  keys = {
    { "<leader>be", "<cmd>Neotree toggle<cr>", desc = "Explorer NeoTree (root dir)" },
  },
  config = function(_, opts)
    local function on_move(data)
      Snacks.rename.on_rename_file(data.source, data.destination)
    end

    local events = require("neo-tree.events")
    opts.event_handlers = opts.event_handlers or {}
    vim.list_extend(opts.event_handlers, {
      { event = events.FILE_MOVED, handler = on_move },
      { event = events.FILE_RENAMED, handler = on_move },
    })
    opts.nesting_rules = require("neotree-file-nesting-config").nesting_rules
    require("neo-tree").setup(opts)
    vim.api.nvim_create_autocmd("TermClose", {
      pattern = "*lazygit",
      callback = function()
        if package.loaded["neo-tree.sources.git_status"] then
          require("neo-tree.sources.git_status").refresh()
        end
      end,
    })
  end,
}
