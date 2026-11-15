return {
  "nvimdev/lspsaga.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- optional
    "nvim-tree/nvim-web-devicons", -- optional
  },
  opts = {
    ui = {
      code_action = "",
    },
    symbol_in_winbar = {
      enable = true,
      separator = "| ",
      hide_keyword = true,
      show_file = true,
      folder_level = 2,
      respect_root = false,
      color_mode = true,
    },
    outline = {
      win_position = "botright",
      win_with = "",
      win_width = 30,
      show_detail = true,
      auto_preview = true,
      auto_refresh = true,
      auto_close = true,
      custom_sort = nil,
      keys = {
        jump = "o",
        expand_collapse = "u",
        quit = "q",
      },
    },
  },
  keys = {
    { "gd", "<cmd>Lspsaga goto_definition<CR>", desc = "Go to definition" },
    { "<leader>ln", "<cmd>Lspsaga rename ++project<CR>", desc = "Rename (project-wide)" },
    { "<leader>tt", "<cmd>Lspsaga term_toggle<CR>", desc = "Toggle terminal (lspsaga)" },
    { "K", "<cmd>Lspsaga hover_doc<cr>", desc = "Show hover documentation" },
    { "<Plug>(lsp)a", "<cmd>Lspsaga code_action<cr>", desc = "Code action" },
    {
      "<Plug>(lsp)d",
      "<cmd>Lspsaga show_cursor_diagnostics<cr>",
      desc = "Show diagnostics at cursor",
    },
    {
      "<Plug>(lsp)D",
      "<cmd>Lspsaga show_workspace_diagnostics<cr>",
      desc = "Show diagnostics in workspace",
    },
    { ";e", "<cmd>Lspsaga diagnostic_jump_next<cr>", desc = "Jump to next diagnostic" },
    { ";E", "<cmd>Lspsaga diagnostic_jump_prev<cr>", desc = "Jump to previous diagnostic" },
    { "<Plug>(lsp)rn", "<cmd>Lspsaga rename<cr>", desc = "Rename" },
  },
}
