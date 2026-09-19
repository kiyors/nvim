local M = {}

--- @param icon_name string
--- @return string
function M.get_icon(icon_name)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    local icon = devicons.get_icon(icon_name)
    if icon then
      return icon
    end
  end
  return ""
end

--- Search for a binary in node_modules/.bin/ directories upwards from the start_path.
--- If not found, return the binary name as a fallback.
---@param binary_name string e.g. "biome", "oxc_language_server"
---@param start_path? string (optional) Path to start searching from. Defaults to the directory of the current file.
---@return string binary_path Full path to the binary if found, otherwise the binary name.
function M.find_node_modules_bin(binary_name, start_path)
  local search_path = start_path or vim.fn.expand("%:p:h")

  local results = vim.fs.find("node_modules", {
    upward = true,
    path = search_path,
    type = "directory",
    limit = math.huge,
  })

  for _, node_modules_dir in ipairs(results) do
    local binary_path = node_modules_dir .. "/.bin/" .. binary_name
    if vim.fn.executable(binary_path) == 1 then
      return binary_path
    end
  end

  -- Fallback to the binary name if not found
  return binary_name
end

return M
