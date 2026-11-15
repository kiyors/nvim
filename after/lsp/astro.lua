---@brief
---
--- https://github.com/withastro/language-tools/tree/main/packages/language-server
---
--- Astro language server.
local mason_astro_ts = vim.fn.stdpath("data")
  .. "/mason/packages/astro-language-server/node_modules/typescript/lib"
local mason_ts = vim.fn.stdpath("data")
  .. "/mason/packages/typescript-language-server/node_modules/typescript/lib"

local fallback_tsdk = (vim.uv.fs_stat(mason_astro_ts .. "/typescript.js") and mason_astro_ts)
  or (vim.uv.fs_stat(mason_ts .. "/typescript.js") and mason_ts)
  or nil

local function resolve_tsdk(root_dir)
  if root_dir then
    local project_ts = root_dir .. "/node_modules/typescript/lib"
    if
      vim.uv.fs_stat(project_ts .. "/typescript.js")
      or vim.uv.fs_stat(project_ts .. "/tsserverlibrary.js")
    then
      return project_ts
    end
  end
  return fallback_tsdk
end

return {
  init_options = {
    typescript = {
      tsdk = fallback_tsdk,
    },
  },
  before_init = function(params, config)
    local tsdk = resolve_tsdk(config.root_dir)
    if tsdk and tsdk ~= "" then
      ---@diagnostic disable-next-line: inject-field
      config.init_options = config.init_options or {}
      ---@diagnostic disable-next-line: inject-field
      config.init_options.typescript = { tsdk = tsdk }
      if params and type(params.initializationOptions) == "table" then
        ---@diagnostic disable-next-line: inject-field
        params.initializationOptions.typescript = { tsdk = tsdk }
      end
    end
  end,
}
