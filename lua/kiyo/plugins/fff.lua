return {
  "dmtrKovalenko/fff.nvim",
  build = function()
    require("fff.download").download_or_build_binary()
  end,
  lazy = false,
  dependencies = { "folke/snacks.nvim" },
  ---@type fff.Config
  opts = {
    -- Native picker (only used for <leader>fm; bridge uses snacks UI)
    -- Backend tunables actually consumed by the snacks bridge:
    lazy_sync = true,
    max_results = 100,
    max_threads = 4,
    grep = {
      smart_case = true,
      modes = { "plain", "regex", "fuzzy" },
    },
  },
  keys = {
    {
      "<leader>ff",
      function()
        require("kiyo.utils.fff_snacks").find_files()
      end,
      desc = "Find files (fff)",
    },
    {
      "<leader><space>",
      function()
        require("kiyo.utils.fff_snacks").find_files()
      end,
      desc = "Find files (fff)",
    },
    {
      "<leader>/",
      function()
        require("kiyo.utils.fff_snacks").live_grep()
      end,
      desc = "Grep (fff)",
    },
    {
      "<leader>fw",
      function()
        require("kiyo.utils.fff_snacks").live_grep()
      end,
      desc = "Grep (fff)",
    },
    {
      "<leader>fW",
      function()
        require("kiyo.utils.fff_snacks").grep_word()
      end,
      desc = "Grep word under cursor (fff)",
      mode = { "n", "x" },
    },
    {
      "<leader>sg",
      function()
        require("kiyo.utils.fff_snacks").live_grep()
      end,
      desc = "Grep (fff)",
    },
    {
      "<leader>sw",
      function()
        require("kiyo.utils.fff_snacks").grep_word()
      end,
      desc = "Grep word under cursor (fff)",
      mode = { "n", "x" },
    },
    {
      "<leader>fz",
      function()
        require("kiyo.utils.fff_snacks").live_grep({ grep_mode = { "fuzzy", "plain", "regex" } })
      end,
      desc = "Fuzzy grep (fff)",
    },
    {
      "<leader>fm",
      function()
        require("fff").live_grep({ query = "git:modified " })
      end,
      desc = "Grep git-modified files (fff)",
    },
  },
}
