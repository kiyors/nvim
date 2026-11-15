return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "muniftanjim/nui.nvim",
    -- "rcarriga/nvim-notify",
  },
  opts = {
    lsp = {
      progress = {
        enabled = true,
      },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    routes = {
      {
        filter = {
          event = "msg_show",
          any = {
            { find = "%d+L, %d+B" },
            { find = "%d+l, %d+b" },
            { find = "; after #%d+" },
            { find = "; before #%d+" },
            { find = "%d+ line less" },
            { find = "%d+ fewer lines" },
            { find = "%d+ more line" },
          },
        },
        opts = { skip = true },
      },
    },
    presets = {
      bottom_search = false,
      command_palette = true,
      long_message_to_split = true,
    },
  },
    -- stylua: ignore
    keys = {
      { "<leader>n", "", desc = "+noice"},
      { "<s-enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "redirect cmdline" },
      { "<leader>nl", function() require("noice").cmd("last") end, desc = "noice last message" },
      { "<leader>nh", function() require("noice").cmd("history") end, desc = "noice history" },
      { "<leader>na", function() require("noice").cmd("all") end, desc = "noice all" },
      { "<leader>nd", function() require("noice").cmd("dismiss") end, desc = "dismiss all" },
      { "<leader>nt", function() require("noice").cmd("pick") end, desc = "noice picker" },
      -- { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "scroll forward", mode = {"i", "n", "s"} },
      { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "scroll backward", mode = {"i", "n", "s"}},
    },
  config = function(_, opts)
    -- hack: noice shows messages from before it was enabled,
    -- but this is not ideal when lazy is installing plugins,
    -- so clear the messages in this case.
    if vim.o.filetype == "lazy" then
      vim.cmd([[messages clear]])
    end
    require("noice").setup(opts)
  end,
}
