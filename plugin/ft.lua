vim.filetype.add({
  extension = {
    mdx = "mdx",
    -- env = "dotenv",  <-- REMOVED: This conflicts with wanting .env files to be 'sh'
    base = "yaml",
    rasi = "rasi",
    rofi = "rasi",
    wofi = "rasi",
    tf = "terraform",
    patch = "diff",
    diff = "diff",
  },
  filename = {
    [".env"] = "sh",
    [".envrc"] = "sh",
    [".base"] = "yaml",
    ["vifmrc"] = "vim",
  },
  pattern = {
    ["[jt]sconfig.*%.json"] = "jsonc",
    [".*/waybar/config"] = "jsonc",
    [".*/mako/config"] = "dosini",
    [".*/kitty/.+%.conf"] = "kitty",
    [".*/hypr/.+%.conf"] = "hyprlang",
    [".*/git/config"] = "gitconfig",
    ["%.env%.[%w_.-]+"] = "sh",
    [".*%.env$"] = "sh",
    [".*%.envrc$"] = "sh",
    [".*/ghostty/.*"] = "ghostty",
  },
})
