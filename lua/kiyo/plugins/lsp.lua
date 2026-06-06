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

    -- LSP Attach Configuration
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        map("gl", vim.diagnostic.open_float, "Open Diagnostic Float")
        map("<leader>d", vim.diagnostic.open_float, "Open Diagnostic Float")
        map("K", vim.lsp.buf.hover, "Hover Documentation")
        map("gs", vim.lsp.buf.signature_help, "Signature Documentation")
        map("gD", vim.lsp.buf.declaration, "Goto Declaration")
        map("gi", vim.lsp.buf.implementation, "Goto Implementation")
        map("<leader>gt", vim.lsp.buf.type_definition, "Goto Type Definition")
        map("[d", function()
          vim.diagnostic.jump({ count = -1 })
        end, "Prev Diagnostic")
        map("]d", function()
          vim.diagnostic.jump({ count = 1 })
        end, "Next Diagnostic")

        map(
          "<leader>v",
          "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>",
          "Goto Definition in Vertical Split"
        )

        local wk = require("which-key")
        wk.add({
          { "<leader>la", vim.lsp.buf.code_action, desc = "Code Action" },
          {
            "<leader>lA",
            vim.lsp.buf.range_code_action,
            desc = "Range Code Actions",
          },
          {
            "<leader>ls",
            vim.lsp.buf.signature_help,
            desc = "Display Signature Information",
          },
          {
            "<leader>lr",
            vim.lsp.buf.rename,
            desc = "Rename all references",
          },
          { "<leader>lf", vim.lsp.buf.format, desc = "Format" },
          {
            "<leader>Wa",
            vim.lsp.buf.add_workspace_folder,
            desc = "Workspace Add Folder",
          },
          {
            "<leader>Wr",
            vim.lsp.buf.remove_workspace_folder,
            desc = "Workspace Remove Folder",
          },
          {
            "<leader>Wl",
            function()
              print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end,
            desc = "Workspace List Folders",
          },
        })

        local function client_supports_method(client, method, bufnr)
          if vim.fn.has("nvim-0.11") == 1 then
            return client:supports_method(method, bufnr)
          else
            return client.supports_method(method, { bufnr = bufnr })
          end
        end

        local client = vim.lsp.get_client_by_id(event.data.client_id)

        -- Disable semantic tokens for ts_ls to prevent it from overriding treesitter highlighting
        if client and client.name == "ts_ls" then
          client.server_capabilities.semanticTokensProvider = nil
        end

        if
          client
          and client_supports_method(
            client,
            vim.lsp.protocol.Methods.textDocument_documentHighlight,
            event.buf
          )
        then
          local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
            end,
          })
        end

        if
          client
          and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
        then
          -- Enable inlay hints initially
          vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })

          map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
          end, "[T]oggle Inlay [H]ints")
        end
      end,
    })
  end,
}
