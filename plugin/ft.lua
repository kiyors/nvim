vim.filetype.add({
  extension = {
    mdx = "mdx",
    -- env = "dotenv",  <-- REMOVED: This conflicts with wanting .env files to be 'sh'
    base = "yaml",
    rasi = "rasi",
    rofi = "rasi",
    wofi = "rasi",
    tf = "terraform",
    tofu = "terraform",
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
    ["docker%-compose.*%.ya?ml"] = "yaml.docker-compose",
    ["compose.*%.ya?ml"] = "yaml.docker-compose",
  },
})

-- Treesitter language aliases
vim.treesitter.language.register("bash", { "sh", "zsh", "kitty" })
vim.treesitter.language.register("ini", { "dosini", "ghostty" })
vim.treesitter.language.register("git_config", "gitconfig")
vim.treesitter.language.register("git_rebase", "gitrebase")
vim.treesitter.language.register("ssh_config", "sshconfig")
vim.treesitter.language.register("c_sharp", "cs")
vim.treesitter.language.register("tsx", { "javascriptreact", "typescriptreact" })
vim.treesitter.language.register("terraform", { "opentofu", "tf" })
vim.treesitter.language.register("yaml", { "dockercompose", "yaml.docker-compose" })
vim.treesitter.language.register("json", "jsonc")
vim.treesitter.language.register("markdown", "mdx")
