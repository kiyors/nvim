return {
  "adalessa/laravel.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "kevinhwang91/promise-async",
  },
  cmd = { "Laravel", "Artisan", "Composer", "Sail" },
  event = { "VeryLazy" },
  keys = {
    { "<leader>La", "<cmd>Laravel artisan<cr>", desc = "Laravel Artisan" },
    { "<leader>Lr", "<cmd>Laravel routes<cr>", desc = "Laravel Routes" },
    { "<leader>Lm", "<cmd>Laravel related<cr>", desc = "Laravel Related" },
    { "<leader>Lc", "<cmd>Laravel commands<cr>", desc = "Laravel Commands" },
    { "<leader>Lt", "<cmd>Laravel make<cr>", desc = "Laravel Make" },
  },
  opts = {
    features = {
      pickers = {
        provider = "snacks",
      },
    },
  },
  config = true,
}
