return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "mason-org/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
    "saghen/blink.cmp", -- For LSP capabilities (auto-detected in 0.11)
  },
  config = function()
    -- Diagnostic Configuration
    vim.diagnostic.config({
      -- Show diagnostic signs in the sign column
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "󰅚 ",
          [vim.diagnostic.severity.WARN] = "󰀪 ",
          [vim.diagnostic.severity.INFO] = "󰋽 ",
          [vim.diagnostic.severity.HINT] = "󰌶 ",
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = "ErrorMsg",
          [vim.diagnostic.severity.WARN] = "WarningMsg",
        },
        linehl = {
          [vim.diagnostic.severity.ERROR] = "Error",
          [vim.diagnostic.severity.WARN] = "Warn",
          [vim.diagnostic.severity.INFO] = "Info",
          [vim.diagnostic.severity.HINT] = "Hint",
        },
      },

      -- Update diagnostics while typing
      update_in_insert = false,

      -- Underline diagnostics
      underline = true,

      -- Sort diagnostics by severity
      severity_sort = true,

      -- Floating window configuration
      float = {
        border = "rounded",
        source = true,
        header = "",
        prefix = "",
      },
    })

    -- Enable LSP Servers (Native Neovim 0.11+ API)
    -- This is the safest way to ensure your specific servers are loaded.
    -- Note: rust_analyzer is EXCLUDED because it's handled by rustaceanvim.
    vim.lsp.enable({
      "ts_ls",
      "html",
      "cssls",
      "biome",
      "tailwindcss",
      "emmet_language_server",
      "eslint",
      "lua_ls",
      "pyright",
      "gopls",
      "zls",
      "nixd",
      "intelephense",
      "volar", -- Correct name for Vue/Vite
      "jsonls",
      "yamlls",
      "dockerls",
      "docker_compose_language_service",
      "terraformls",
      "opentofu_ls", -- Correct name for OpenTofu
      "elmls",
      "harper_ls",
      "markdown_oxide",
      "phpactor",
      "laravel_ls",
    })

    -- LSP Attach Configuration    -- Customize behavior when LSP attaches to a buffer
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local opts = { buffer = ev.buf }

        -- Get the client for this buffer
        local client = vim.lsp.get_client_by_id(ev.data.client_id)

        -- Disable semantic tokens for ts_ls to prevent it from overriding treesitter highlighting
        if client and client.name == "ts_ls" then
          client.server_capabilities.semanticTokensProvider = nil
        end

        -- Keybindings
        -- Note: Many of these are already default in Neovim 0.11
        -- but we define them here for customization

        -- Go to definition
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

        -- Go to declaration
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

        -- Go to implementation
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)

        -- Go to type definition
        vim.keymap.set("n", "<leader>gt", vim.lsp.buf.type_definition, opts)

        -- Show references
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

        -- Hover documentation
        vim.keymap.set("n", "K", function()
          vim.lsp.buf.hover({ border = "rounded" })
        end, opts)

        -- Signature help
        vim.keymap.set("n", "<C-k>", function()
          vim.lsp.buf.signature_help({ border = "rounded" })
        end, opts)
        vim.keymap.set("i", "<C-k>", function()
          vim.lsp.buf.signature_help({ border = "rounded" })
        end, opts)

        -- Rename symbol
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

        -- Code action
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        -- Show diagnostics in floating window
        vim.keymap.set("n", "<leader>d", function()
          vim.diagnostic.open_float({
            border = "rounded",
          })
        end, opts)

        -- Go to next/previous diagnostic
        vim.keymap.set("n", "[d", function()
          vim.diagnostic.jump({ count = -1 })
        end, opts)
        vim.keymap.set("n", "]d", function()
          vim.diagnostic.jump({ count = 1 })
        end, opts)

        -- INLAY HINTS CONFIGURATION
        if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
          -- Enable inlay hints initially
          vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end

        -- Document Highlight (if supported)
        -- Highlight symbol under cursor
        if client and client.server_capabilities.documentHighlightProvider then
          local highlight_augroup = vim.api.nvim_create_augroup("LspDocumentHighlight", {})
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = ev.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = ev.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end,
    })
  end,
}
