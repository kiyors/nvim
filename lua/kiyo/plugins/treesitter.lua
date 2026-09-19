return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile", "VeryLazy" },
    cmd = { "TSUpdate", "TSInstall", "TSModuleInfo", "TSBufEnable", "TSBufDisable" },
    build = ":TSUpdate",
    branch = "main",
    main = "nvim-treesitter",
    init = function()
      -- Register custom predicates and directives for Nix injections (hmts replacement)
      require("kiyo.utils.nix_treesitter").setup()
    end,
    config = function()
      -- Define parsers to install
      local parsers_to_ensure = {
        "json",
        "javascript",
        "typescript",
        "astro",
        "tsx",
        "jsx",
        "go",
        "yaml",
        "html",
        "css",
        "python",
        "http",
        "prisma",
        "markdown",
        "markdown_inline",
        "svelte",
        "c",
        "toml",
        "cpp",
        "elm",
        "graphql",
        "sql",
        "bash",
        "php",
        "phpdoc",
        "blade",
        "lua",
        "nix",
        "vim",
        "dockerfile",
        "gitignore",
        "query",
        "vimdoc",
        "java",
        "kotlin",
        "editorconfig",
        "ssh_config",
        "rust",
        "wgsl",
        "ron",
        "diff",
        "terraform",
        "hcl",
        "nu",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "hyprlang",
        "regex",
        "ini",
        "zig",
        "vue",
        "gomod",
        "gosum",
        "gowork",
        "scss",
        "json5",
        "xml",
        "make",
        "cmake",
        "proto",
        "cuda",
        "c_sharp",
        "ruby",
        "swift",
        "objc",
        "latex",
        "typst",
      }

      -- Conditionally add parsers based on system executables
      if vim.fn.executable("fish") == 1 then
        table.insert(parsers_to_ensure, "fish")
      end

      if vim.fn.executable("rofi") == 1 or vim.fn.executable("wofi") == 1 then
        table.insert(parsers_to_ensure, "rasi")
      end

      -- Diff against already-installed parsers so it doesn't reinstall everything on startup
      local ok, ts_config = pcall(require, "nvim-treesitter.config")
      if ok then
        local alreadyInstalled = ts_config.get_installed()
        local parsersToInstall = vim
          .iter(parsers_to_ensure)
          :filter(function(parser)
            return not vim.tbl_contains(alreadyInstalled, parser)
          end)
          :totable()

        if #parsersToInstall > 0 then
          require("nvim-treesitter").install(parsersToInstall)
        end
      end

      -- Setup nvim-treesitter (v1.0.0+ API)
      require("nvim-treesitter").setup({
        ensure_installed = parsers_to_ensure,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
      })

      -- Start treesitter on the current buffer if already open
      local current_buf = vim.api.nvim_get_current_buf()
      if vim.api.nvim_buf_is_valid(current_buf) and vim.bo[current_buf].filetype ~= "" then
        local lang = vim.treesitter.language.get_lang(vim.bo[current_buf].filetype)
          or vim.bo[current_buf].filetype
        local started = pcall(vim.treesitter.start, current_buf, lang)
        if started then
          vim.wo.foldmethod = "expr"
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end
      end
    end,
  },

  -- NOTE: js,ts,jsx,tsx Auto Close Tags
  {
    "windwp/nvim-ts-autotag",
    enabled = true,
    ft = {
      "html",
      "xml",
      "javascript",
      "typescript",
      "javascriptreact",
      "typescriptreact",
      "svelte",
    },
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          enable_close = true,
          enable_rename = true,
        },
        per_filetype = {
          ["html"] = { enable_close = true },
          ["javascriptreact"] = { enable_close = true },
          ["typescriptreact"] = { enable_close = true },
        },
      })
    end,
  },

  -- Rainbow Delimiters
  {
    "HiPhish/rainbow-delimiters.nvim",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local rainbow_delimiters = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow_delimiters.strategy["global"],
          vim = rainbow_delimiters.strategy["local"],
        },
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks",
          javascript = "rainbow-delimiters",
          typescript = "rainbow-delimiters",
          tsx = "rainbow-delimiters",
        },
        highlight = {
          "RainbowDelimiterRed",
          "RainbowDelimiterYellow",
          "RainbowDelimiterBlue",
          "RainbowDelimiterOrange",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
      }
    end,
  },
  {
    "davidmh/mdx.nvim",
    ft = "mdx",
  },
}
