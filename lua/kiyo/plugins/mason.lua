return {
  "mason-org/mason.nvim",
  dependencies = {
    "mason-org/mason-lspconfig.nvim",
    "mason-org/mason-registry",
  },
  cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate" },
  keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
  build = ":MasonUpdate",
  opts = {
    ensure_installed = {
      -- LSP servers (matching your vim.lsp.enable() config)
      "lua-language-server", -- Lua LSP
      "gopls", -- Go LSP
      "zls", -- Zig LSP
      "typescript-language-server", -- TypeScript LSP
      "intelephense", -- PHP LSP
      "python-lsp-server", -- Python LSP
      "tailwindcss-language-server", -- Tailwind CSS LSP
      "html-lsp", -- HTML LSP
      "css-lsp", -- CSS LSP
      "json-lsp",
      "eslint-lsp",
      "vue-language-server", -- Vue LSP
      "biome",
      "docker-language-server",
      "dockerfile-language-server",
      "docker-compose-language-service",
      "yaml-language-server",
      "mdx-analyzer",
      "terraform",
      "tofu-ls",
      "markdown-oxide",
      "tombi",
      "taplo",
      "codelldb",

      -- Formatters (for conform.nvim and general use)
      "stylua",
      "selene",
      "goimports",
      "prettier",
      "blade-formatter",
      "oxfmt",

      -- Linters and diagnostics
      "golangci-lint",
      "eslint_d",
      "luacheck", -- Lua linting
      "tflint",
      "pint", -- Laravel Pint for PHP (formatting & linting)
      "ruff",

      -- Additional useful tools
      "delve", -- Go debugger
      "shfmt", -- Shell formatter
      "shellcheck", -- Shell linter
      "emmet-language-server",
      "emmet-ls",
      "elm-format",
      "elm-language-server",
      "harper-ls",
    },
  },
  config = function(_, opts)
    require("mason").setup(opts)

    -- Simplified auto-install without Nix-managed tools
    local mr = require("mason-registry")
    local function ensure_installed()
      for _, tool in ipairs(opts.ensure_installed) do
        if mr.has_package(tool) then
          local p = mr.get_package(tool)
          if not p:is_installed() then
            vim.notify("Mason: Installing " .. tool .. "...", vim.log.levels.INFO)
            p:install()
          end
        end
      end
    end

    if mr.refresh then
      mr.refresh(ensure_installed)
    else
      ensure_installed()
    end
  end,
}
