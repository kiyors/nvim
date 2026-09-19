return {
  -- ui components
  { "MunifTanjim/nui.nvim", lazy = true },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
  -- search/replace in multiple files
  {
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
    },
  },
  -- Flash enhances the built-in search functionality by showing labels
  -- at the end of each match, letting you quickly jump to a specific
  -- location.
  {
    "folke/flash.nvim",
    event = { "BufReadPre", "BufNewFile" },
    vscode = true,
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
  {
    "mbbill/undotree",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "<leader><F5>", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
      { "<leader>uu", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
    },
  },
  {
    "nvim-tree/nvim-web-devicons",
    -- lazy = true,
    event = "VeryLazy",
    opts = {
      override = {
        [".env.local"] = {
          icon = "",
          color = "#89b4fa",
          name = "EnvLocal",
        },
        [".envrc"] = {
          icon = "",
          color = "#f9e2af",
          name = "Envrc",
        },
        [".env.example"] = {
          icon = "",
          color = "#f9e2af",
          name = "EnvExample",
        },
        [".env.development"] = {
          icon = "",
          color = "#a6e3a1",
          name = "EnvDevelopment",
        },
        [".env.production"] = {
          icon = "",
          color = "#f38ba8",
          name = "EnvProduction",
        },
      },
    },
  },
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },

  -- {
  --   "smjonas/inc-rename.nvim",
  --   cmd = "IncRename",
  --   opts = {},
  -- },
}
