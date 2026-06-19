return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile", "VeryLazy" },
    cmd = { "TSUpdate", "TSInstall", "TSModuleInfo", "TSBufEnable", "TSBufDisable" },
    dependencies = { "davidmh/mdx.nvim" },
    build = ":TSUpdate",
    branch = "main",
    main = "nvim-treesitter",
    init = function()
      -- Register custom predicates and directives for Nix injections (hmts replacement)
      require("kiyo.utils.nix_treesitter").setup()

      -- Define parsers to install
      local parsers_to_ensure = {
        "json",
        "javascript",
        "typescript",
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

      -- Store parsers_to_ensure in a global or module so the config block can access it
      _G.kiyo_treesitter_parsers = parsers_to_ensure
    end,
    config = function()
      local parsers_to_ensure = _G.kiyo_treesitter_parsers or {}
      _G.kiyo_treesitter_parsers = nil -- Clean up

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

      -- Register filetypes to their respective treesitter parsers
      vim.treesitter.language.register("bash", "kitty")
      vim.treesitter.language.register("ini", "ghostty")
      vim.treesitter.language.register("tsx", "javascriptreact")
      vim.treesitter.language.register("tsx", "typescriptreact")

      -- Force start Treesitter and enable folding
      vim.api.nvim_create_autocmd({ "FileType", "BufReadPost" }, {
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
            or vim.bo[buf].filetype

          -- Try to start Treesitter highlighting
          local start_ok, _ = pcall(vim.treesitter.start, buf, lang)
          if start_ok then
            -- Standard treesitter integrations
            vim.wo.foldmethod = "expr"
            vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          end
        end,
      })
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
}
