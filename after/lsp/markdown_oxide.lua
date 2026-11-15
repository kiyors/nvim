---@brief
---
--- https://github.com/Feel-ix-343/markdown-oxide
---
--- Markdown Oxide - PKM language server for Markdown.
return {
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  },
}
