return {
  "rmagatti/auto-session",
  cmd = { "SessionRestore", "SessionSave", "Autosession" },
  keys = {
    { "<leader>wr", "<cmd>SessionRestore<CR>", desc = "Restore session for cwd" },
    { "<leader>ws", "<cmd>SessionSave<CR>", desc = "Save session for cwd" },
  },
  opts = {
    auto_restore = false,
    suppressed_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
  },
}
