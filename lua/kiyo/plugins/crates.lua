-- Editor support for managing Rust crates. In `Cargo.toml` you will see virtual
-- text showing the installed version for each dependency, and options for
-- upgrading.
--
-- Type `K` over a crate name, version number, or feature for an info popup.
-- Press `K` again to focus the popup. Highlight version numbers or features and
-- press `<cr>` to apply or to unapply.
--
-- To install a new dependency type it out, and when you get to the version
-- field press `<tab>` inside an empty set of quotes to see available versions.

return {
  "saecki/crates.nvim",
  event = { "BufRead Cargo.toml" },
  dependencies = {
    { "nvim-lua/plenary.nvim" },
  },
  config = function()
    local crates = require("crates")

    crates.setup({
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    })

    vim.api.nvim_create_autocmd("BufRead", {
      group = vim.api.nvim_create_augroup("CratesNvimCustomization", { clear = true }),
      pattern = "Cargo.toml",
      callback = function(data)
        local wk = require("which-key")

        -- Set up keybindings.
        wk.add({
          { "<leader>C", group = "crates.nvim", buffer = data.buf },
          { "<leader>Ct", crates.toggle, desc = "toggle", buffer = data.buf },
          { "<leader>Cr", crates.reload, desc = "reload", buffer = data.buf },
          { "<leader>Cv", crates.show_versions_popup, desc = "show versions", buffer = data.buf },
          { "<leader>Cf", crates.show_features_popup, desc = "show features", buffer = data.buf },
          {
            "<leader>Cd",
            crates.show_dependencies_popup,
            desc = "show dependencies",
            buffer = data.buf,
          },
          { "<leader>Cu", crates.update_crate, desc = "update crate", buffer = data.buf },
          { "<leader>Ca", crates.update_all_crates, desc = "update all crates", buffer = data.buf },
          { "<leader>CU", crates.upgrade_crate, desc = "upgrade crate", buffer = data.buf },
          {
            "<leader>CA",
            crates.upgrade_all_crates,
            desc = "upgrade all crates",
            buffer = data.buf,
          },
          { "<leader>CH", crates.open_homepage, desc = "open homepage", buffer = data.buf },
          { "<leader>CR", crates.open_repository, desc = "open repository", buffer = data.buf },
          {
            "<leader>CD",
            crates.open_documentation,
            desc = "open documentation",
            buffer = data.buf,
          },
          { "<leader>CC", crates.open_crates_io, desc = "open crates.io", buffer = data.buf },
          {
            mode = "v",
            { "<leader>Cu", crates.update_crates, desc = "update crates", buffer = data.buf },
            { "<leader>CU", crates.upgrade_crates, desc = "upgrade crates", buffer = data.buf },
          },
        })
        wk.add({
          {
            "K",
            function()
              if crates.popup_available() then
                crates.show_popup()
              else
                vim.lsp.buf.hover()
              end
            end,
            desc = "hover documentation",
            buffer = data.buf,
          },
        })
      end,
    })
  end,
}
