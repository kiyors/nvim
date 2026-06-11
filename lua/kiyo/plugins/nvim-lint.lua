-- lua/kiyo/plugins/nvim-lint.lua
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")
    local pu = require("kiyo.utils.project-utils")

    -- Helper: arg that resolves at lint-time, dropped if `value_fn` returns nil
    local function maybe_arg(value_fn)
      return function()
        return value_fn()
      end
    end

    -- biome: reuse built-in biomejs definition, but inject --config-path so
    -- we pick up project config (or rules/biome.jsonc fallback).
    local biomejs = vim.deepcopy(require("lint.linters.biomejs"))
    biomejs.args = {
      "lint",
      maybe_arg(function()
        local dir = pu.get_biome_config_dir(vim.fn.expand("%:p:h"))
        return dir and ("--config-path=" .. dir) or nil
      end),
    }
    lint.linters.biome = biomejs

    -- selene: reuse built-in, inject --config when no project selene.toml
    local selene = vim.deepcopy(require("lint.linters.selene"))
    local original_selene_args = selene.args
    selene.args = vim.list_extend({
      maybe_arg(function()
        local project =
          pu.find_config_file({ "selene.toml", ".selene.toml" }, vim.fn.expand("%:p:h"))
        if project then
          return nil -- selene auto-discovers from cwd; nothing to inject
        end
        local default = pu.get_default_selene_config()
        return pu.file_exists(default) and ("--config=" .. default) or nil
      end),
    }, vim.deepcopy(original_selene_args))
    lint.linters.selene = selene

    -- ruff: inject --config when no project pyproject.toml/ruff.toml
    local ruff = vim.deepcopy(require("lint.linters.ruff"))
    table.insert(
      ruff.args,
      2,
      maybe_arg(function()
        local project = pu.find_config_file(
          { "pyproject.toml", "ruff.toml", ".ruff.toml" },
          vim.fn.expand("%:p:h")
        )
        if project then
          return nil
        end
        local default = pu.get_default_ruff_config()
        return pu.file_exists(default) and ("--config=" .. default) or nil
      end)
    )
    lint.linters.ruff = ruff

    -- shellcheck has no --rcfile flag, so when there's no project .shellcheckrc
    -- we inline the rules/.shellcheckrc defaults as CLI args (CLI > rcfile).
    local function project_has_shellcheckrc()
      return pu.cached(0, "cached_shellcheckrc", function()
        return pu.find_config_file({ ".shellcheckrc" }, vim.fn.expand("%:p:h")) ~= nil
      end)
    end
    local function default_arg(value)
      return maybe_arg(function()
        return not project_has_shellcheckrc() and value or nil
      end)
    end

    local shellcheck = vim.deepcopy(require("lint.linters.shellcheck"))
    shellcheck.args = vim.list_extend({
      default_arg("--external-sources"),
      default_arg("--source-path=SCRIPTDIR"),
      default_arg("--exclude=SC1090,SC1091"),
    }, shellcheck.args)
    lint.linters.shellcheck = shellcheck

    -- Smart linter selection for JS/TS: ESLint (project) > biome (project or default)
    local function js_like_linters()
      local bufnr = vim.api.nvim_get_current_buf()
      return pu.cached(bufnr, "cached_js_linters", function()
        local dirname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
        if pu.has_eslint_config(dirname) then
          return { "eslint_d" }
        end
        return { "biome" } -- biome wrapper handles project-or-default config
      end)
    end

    -- JSON: only lint if biome config is available (project or default)
    local function json_linters()
      local bufnr = vim.api.nvim_get_current_buf()
      return pu.cached(bufnr, "cached_json_linters", function()
        local dirname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
        if pu.has_biome_config(dirname) or pu.file_exists(pu.get_default_biome_config()) then
          return { "biome" }
        end
        return {}
      end)
    end

    lint.linters_by_ft = {
      -- JavaScript/TypeScript - smart detection
      javascript = js_like_linters,
      typescript = js_like_linters,
      javascriptreact = js_like_linters,
      typescriptreact = js_like_linters,

      json = json_linters,
      jsonc = json_linters,

      go = { "golangcilint" },
      python = { "ruff" },
      rust = {},
      lua = { "selene" },
      nix = { "statix" },

      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },

      toml = { "tombi" },

      terraform = { "terraform_validate" },
      tf = { "terraform_validate" },
    }

    -- Auto-lint on write: run the first executable linter for the filetype.
    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = lint_augroup,
      callback = function()
        local ft = vim.bo.filetype
        local linters = lint.linters_by_ft[ft]

        if type(linters) == "function" then
          linters = linters()
        end

        if not linters or #linters == 0 then
          return
        end

        for _, linter_name in ipairs(linters) do
          local linter = lint.linters[linter_name]
          if type(linter) == "function" then
            linter = linter()
          end
          if linter then
            local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
            if cmd and vim.fn.executable(cmd) == 1 then
              lint.try_lint(linter_name)
              break
            end
          end
        end
      end,
    })

    vim.keymap.set("n", "<leader>cl", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })

    vim.keymap.set("n", "<leader>cL", function()
      local ft = vim.bo.filetype
      local linters = lint.linters_by_ft[ft]

      if type(linters) == "function" then
        linters = linters()
      end

      if linters and #linters > 0 then
        vim.notify("Linters for " .. ft .. ": " .. table.concat(linters, ", "), vim.log.levels.INFO)
      else
        vim.notify("No linters configured for " .. ft, vim.log.levels.WARN)
      end
    end, { desc = "Show configured linters" })
  end,
}
