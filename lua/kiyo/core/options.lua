vim.g.mapleader = " " -- change leader to a space
vim.g.maplocalleader = " " -- change localleader to a space

vim.loader.enable() -- Lua module bytecode cache

-- Disable language providers you don't use
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

vim.g.loaded_netrw = 1 -- disable netrw
vim.g.loaded_netrwPlugin = 1 --  disable netrw

vim.opt.incsearch = true -- make search act like search in modern browsers
vim.opt.backup = false -- creates a backup file

-- Clipboard Configuration
-- Using unnamedplus to sync with system clipboard
-- OSC 52 is used as a fallback/primary in Tmux/SSH
vim.opt.clipboard = "unnamedplus"

-- If in Tmux or SSH, explicitly enable OSC 52
if vim.env.TMUX or vim.env.SSH_CONNECTION then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end

vim.opt.cmdheight = 1 -- more space in the neovim command line for displaying messages
vim.opt.completeopt = { "menu", "menuone", "noselect" } -- mostly just for cmp
vim.opt.conceallevel = 0 -- so that `` is visible in markdown files
vim.opt.hlsearch = true -- highlight all matches on previous search pattern
vim.opt.ignorecase = true -- ignore case in search patterns

-- Mouse Settings
vim.opt.mouse = "a" -- allow the mouse to be used in neovim
vim.opt.mousemodel = "extend" -- use 'extend' model for mouse selection
vim.opt.selection = "inclusive" -- selection should be inclusive
vim.opt.mousescroll = "ver:1,hor:1"
vim.opt.mousemoveevent = false -- disable to reduce latency in multiplexers like Tmux

vim.opt.pumheight = 10 -- pop up menu height
vim.opt.showmode = false -- we don't need to see things like -- INSERT -- anymore
vim.opt.showtabline = 0 -- always show tabs
vim.opt.smartcase = true -- smart case
vim.opt.smartindent = true -- make indenting smarter again
vim.opt.splitbelow = true -- force all horizontal splits to go below current window
vim.opt.splitright = true -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false -- creates a swapfile
vim.opt.termguicolors = true -- set term gui colors (most terminals support this)

vim.opt.timeoutlen = 1000 -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.undofile = true -- enable persistent undo
vim.opt.updatetime = 100 -- faster completion (4000ms default)
vim.opt.writebackup = false -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited

-- Tab, Indent
vim.opt.tabstop = 2
vim.opt.smarttab = true
vim.opt.shiftwidth = 2 -- the number of spaces inserted for each indentation
vim.opt.softtabstop = 2
vim.opt.breakindent = true -- wrap lines with indent
vim.opt.autoindent = true
vim.opt.expandtab = true -- convert tabs to spaces

vim.opt.number = true -- set numbered lines
vim.opt.relativenumber = true -- set relative numbered lines
vim.opt.numberwidth = 1 -- set number column width to 2 {default 4}
vim.opt.signcolumn = "yes" -- match nvf 'yes' instead of 'yes:1'
vim.opt.wrap = false -- match nvf default wrap = false
vim.opt.textwidth = 120 -- display lines as 120
vim.opt.scroll = 10
vim.opt.scrolloff = 8 -- Makes sure there are always eight lines of context
-- vim.opt.sidescrolloff = 8                               -- Makes sure there are always eight lines of context
vim.opt.showcmd = false -- Don't show the command in the last line
vim.opt.ruler = true -- Don't show the ruler
vim.opt.guifont = "monospace:h17" -- the font used in graphical neovim applications
vim.opt.title = true -- set the title of window to the value of the titlestring
vim.opt.confirm = true -- confirm to save changes before exiting modified buffer
vim.opt.winborder = "single" -- https://neovim.io/doc/user/options.html#'winborder'

-- Fold
vim.opt.foldcolumn = "auto:1" -- match nvf auto:1
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.fillchars = {
  eob = "‿",
  fold = " ",
  foldopen = "▼",
  foldsep = "⸽",
  foldclose = "⏵",
} -- match nvf fillchars exactly
