-- lua/kiyo/plugins/conform.lua
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true }, function(err, did_edit)
          if not err and did_edit then
            vim.notify("Code formatted", vim.log.levels.INFO, { title = "Conform" })
          end
        end)
      end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },
  opts = function()
    local util = require("conform.util")
    local pu = require("kiyo.utils.project-utils")

    -- Shallow merge that inherits unset keys from `base` via metatable.
    local function extend_formatter(base, override)
      return setmetatable(override, { __index = base })
    end

    -- biome: project config wins, fallback to rules/biome.jsonc
    local biome_for_project = extend_formatter(require("conform.formatters.biome"), {
      require_cwd = false,
      args = function(_, ctx)
        local args = { "check", "--write", "--unsafe", "--stdin-file-path", "$FILENAME" }
        local config_dir = pu.get_biome_config_dir(ctx.dirname)
        if config_dir then
          table.insert(args, "--config-path=" .. config_dir)
        end
        return args
      end,
      cwd = util.root_file(
        vim.list_extend(vim.deepcopy(pu.BIOME_CONFIG_FILES), { "package.json" })
      ),
    })

    -- prettier: only when project config exists
    local prettier_for_project = extend_formatter(require("conform.formatters.prettier"), {
      require_cwd = true,
      cwd = util.root_file(
        vim.list_extend(vim.deepcopy(pu.PRETTIER_CONFIG_FILES), { "package.json" })
      ),
    })

    -- biome > prettier (only if project prettier config) > biome (default)
    local function js_like_formatters(bufnr)
      bufnr = bufnr or vim.api.nvim_get_current_buf()

      -- deno LSP takes precedence; do not cache (LSP attach is async)
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      for _, client in pairs(clients) do
        if client.name == "denols" then
          return { "deno_fmt" }
        end
      end

      return pu.cached(bufnr, "cached_js_formatters", function()
        local dirname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
        if pu.has_biome_config(dirname) then
          return { "biome_for_project" }
        elseif pu.has_prettier_config(dirname) then
          return { "prettier_for_project" }
        end
        -- Fallback to biome with default config
        return { "biome_for_project" }
      end)
    end

    local function json_formatters(bufnr)
      bufnr = bufnr or vim.api.nvim_get_current_buf()
      return pu.cached(bufnr, "cached_json_formatters", function()
        local dirname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
        if pu.has_biome_config(dirname) then
          return { "biome_for_project" }
        end
        -- stop_after_first: try project prettier first, then biome with default config
        return { "prettier_for_project", "biome_for_project", stop_after_first = true }
      end)
    end

    -- pint is Laravel-only; fall back to php-cs-fixer for vanilla PHP projects
    local function php_formatters(bufnr)
      bufnr = bufnr or vim.api.nvim_get_current_buf()
      return pu.cached(bufnr, "cached_php_formatters", function()
        local dirname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
        local is_laravel = pu.find_config_file({ "artisan" }, dirname) ~= nil
        return is_laravel and { "pint" } or { "php_cs_fixer" }
      end)
    end

    return {
      formatters = {
        biome_for_project = biome_for_project,
        prettier_for_project = prettier_for_project,
      },
      formatters_by_ft = {
        -- JavaScript/TypeScript - smart detection
        javascript = js_like_formatters,
        typescript = js_like_formatters,
        javascriptreact = js_like_formatters,
        typescriptreact = js_like_formatters,

        -- JSON - prefer biome, fallback to prettier
        json = json_formatters,
        jsonc = json_formatters,

        -- Core Web (Biome with default config fallback)
        html = { "biome_for_project" },
        css = { "biome_for_project" },

        -- Data, Docs, and Content
        markdown = { "oxfmt" },
        mdx = { "oxfmt" },
        yaml = { "oxfmt" },

        -- Additional Styling & Frameworks
        scss = { "oxfmt" },
        less = { "oxfmt" },
        vue = { "oxfmt" },
        graphql = { "oxfmt" },
        handlebars = { "oxfmt" },

        -- Go
        go = { "goimports", "gofmt" },

        -- Lua
        lua = { "stylua" },

        -- Toml
        toml = { "taplo" },

        -- Nix
        nix = { "nixfmt" },

        -- Python
        python = { "ruff" },

        -- PHP: pint when Laravel (artisan present), php-cs-fixer otherwise
        php = php_formatters,
        blade = { "blade-formatter" },

        -- Shell
        sh = { "shfmt" },
        bash = { "shfmt" },

        -- Rust
        rust = { "rustfmt" },

        -- Terraform
        hcl = { "packer_fmt" },
        terraform = { "terraform_fmt" },
        tf = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return {
          timeout_ms = 2000,
          lsp_format = "fallback",
        }
      end,
    }
  end,
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

    -- Commands to disable/enable formatting
    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        vim.b.disable_autoformat = true
      else
        vim.g.disable_autoformat = true
      end
    end, {
      desc = "Disable autoformat-on-save",
      bang = true,
    })

    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, {
      desc = "Re-enable autoformat-on-save",
    })
  end,
}
