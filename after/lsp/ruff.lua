---@brief
---
--- https://docs.astral.sh/ruff/editors
---
--- Ruff language server. Linting, formatting, and organizing imports.
return {
  on_attach = function(client, bufnr)
    -- Disable Ruff's hover in favor of Pyright's richer hover docs
    if client.server_capabilities then
      client.server_capabilities.hoverProvider = false
    end
  end,
}
