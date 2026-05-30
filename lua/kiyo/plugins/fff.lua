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
  config = function(_, opts)
    require("fff").setup(opts)
    -- Pre-warm the file index so the first <leader>ff / <leader><space>
    -- shows files immediately instead of waiting on a cold scan.
    vim.schedule(function()
      pcall(function()
        require("fff.file_picker").setup()
      end)
    end)
  end,
  keys = (function()
    local function find_files()
      require("kiyo.utils.fff_snacks").find_files()
    end
    local function live_grep(opts)
      require("kiyo.utils.fff_snacks").live_grep(opts)
    end
    local function grep_word()
      require("kiyo.utils.fff_snacks").grep_word()
    end
    return {
      { "<leader>ff", find_files, desc = "Find files (fff)" },
      { "<leader><space>", find_files, desc = "Find files (fff)" },
      { "<leader>/", live_grep, desc = "Grep (fff)" },
      { "<leader>fw", live_grep, desc = "Grep (fff)" },
      { "<leader>fW", grep_word, desc = "Grep word under cursor (fff)", mode = { "n", "x" } },
      { "<leader>sg", live_grep, desc = "Grep (fff)" },
      { "<leader>sw", grep_word, desc = "Grep word under cursor (fff)", mode = { "n", "x" } },
      {
        "<leader>fz",
        function()
          live_grep({ grep_mode = { "fuzzy", "plain", "regex" } })
        end,
        desc = "Fuzzy grep (fff)",
      },
      {
        "<leader>fm",
        function()
          live_grep({ search = "git:modified " })
        end,
        desc = "Grep git-modified files (fff)",
      },
    }
  end)(),
}
