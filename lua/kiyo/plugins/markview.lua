return {
  "OXY2DEV/markview.nvim",
  lazy = false,

  -- For `nvim-treesitter` users.
  priority = 49,

  -- For blink.cmp's completion
  dependencies = {
    "saghen/blink.cmp",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    preview = {
      modes = { "n", "i", "no", "c" },
      hybrid_modes = { "i" },
      -- This stops the document from jumping around when you enter insert mode.
      -- It keeps everything else rendered and only shows raw text for the block you are editing.
      callbacks = {
        on_enable = function(_, win)
          vim.wo[win].conceallevel = 2
          vim.wo[win].concealcursor = "nc"
        end,
      },
    },
    markdown_inline = {
      checkboxes = {
        checked = { scope_hl = false },
        unchecked = { scope_hl = false },
        ["-"] = { scope_hl = false },
      },
    },
  },
}
