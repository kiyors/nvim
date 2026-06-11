---@brief
---
--- https://microsoft.github.io/pyright/
---
--- Pyright language server. Type checking and autocompletion.
return {
  settings = {
    pyright = {
      disableOrganizeImports = true, -- Let Ruff handle imports
    },
    python = {
      analysis = {
        -- Optional: Ignores all Pyright linting warnings, leaving them to Ruff.
        -- Only type-checking errors will be shown.
        ignore = { "*" },
      },
    },
  },
}
