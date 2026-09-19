vim.g.mapleader = " " -- change leader to a space
vim.g.maplocalleader = " " -- change localleader to a space

vim.loader.enable() -- Lua module bytecode cache

-- Prevent plugins (e.g. catppuccin detect_integrations) from initializing unused
-- Neovim 0.12 vim.pack (which creates an empty site/pack/core/opt directory triggering lazy/vim.pack warnings)
if vim.pack and type(vim.pack.get) == "function" then
  vim.pack.get = function()
    return {}
  end
end

-- Prevent E95 / E5009 errors on repeated :checkhealth calls and auto-load lazy plugins
if vim.health and type(vim.health._check) == "function" then
  local orig_health_check = vim.health._check
  vim.health._check = function(mods, plugin_names)
    -- Force-wipe any existing health:// buffers so vim.cmd.file('health://') never collides with E95
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf):find("health://") then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end

    -- If specific plugins are requested (e.g. :checkhealth nvim-treesitter), ensure lazy loads them
    if plugin_names and plugin_names ~= "" then
      local ok, lazy = pcall(require, "lazy")
      if ok then
        local names = vim.split(plugin_names, "%s+", { trimempty = true })
        for _, name in ipairs(names) do
          local clean_name = name:gsub("%..*$", "")
          pcall(lazy.load, { plugins = { clean_name } })
        end
      end
    end

    return orig_health_check(mods, plugin_names)
  end
end

-- Prepend Mason bin directory to PATH so language servers and formatters are immediately available
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if vim.fn.isdirectory(mason_bin) == 1 then
  vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
end

-- Ensure tools packaged in Home Manager's Neovim wrapper (e.g. imagemagick, ghostscript)
-- are accessible in PATH even if Neovim was launched from an unwrapped system binary
if vim.fn.executable("magick") == 0 then
  local hm_nvim = "/etc/profiles/per-user/" .. (vim.env.USER or "gaurav") .. "/bin/nvim"
  local f = io.open(hm_nvim, "r")
  if f then
    local content = f:read("*all")
    f:close()
    local seen = {}
    for p in content:gmatch("(/nix/store/[^/]+/bin)") do
      if not seen[p] and vim.uv.fs_stat(p) then
        seen[p] = true
        vim.env.PATH = p .. ":" .. vim.env.PATH
      end
    end
  end
end

-- Disable language providers you don't use
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

vim.g.loaded_netrw = 1 -- disable netrw
vim.g.loaded_netrwPlugin = 1 --  disable netrw

vim.opt.incsearch = true -- make search act like search in modern browsers
vim.opt.backup = false -- creates a backup file

-- Clipboard Configuration (schedule to avoid synchronous pbcopy IPC during initial startup)
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

vim.opt.cmdheight = 1 -- more space in the neovim command line for displaying messages
vim.opt.completeopt = { "menu", "menuone", "noselect" } -- mostly just for cmp
vim.opt.conceallevel = 0 -- so that `` is visible in markdown files
vim.opt.hlsearch = true -- highlight all matches on previous search pattern
vim.opt.ignorecase = true -- ignore case in search patterns

-- Mouse Settings
vim.opt.mouse = "a"
vim.opt.mousescroll = "ver:1,hor:1"
vim.opt.mousemoveevent = true -- enable for better mouse support, matching nvf config

vim.opt.pumheight = 10 -- pop up menu height
vim.opt.showmode = false -- we don't need to see things like -- INSERT -- anymore
vim.opt.showtabline = 0 -- always show tabs
vim.opt.smartcase = true -- smart case
vim.opt.smartindent = true -- make indenting smarter again
vim.opt.splitbelow = true -- force all horizontal splits to go below current window
vim.opt.splitright = true -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false -- creates a swapfile
vim.opt.termguicolors = true -- set term gui colors (most terminals support this)
vim.opt.background = "dark" -- explicit background prevents DSR query delays (E1568)

vim.opt.timeoutlen = 1000 -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.undofile = true -- enable persistent undo
vim.opt.updatetime = 100 -- faster completion (4000ms default)
vim.opt.writebackup = false -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited

-- Diff options (Histogram algorithm + linematch alignment for superior diffs)
vim.opt.diffopt =
  { "internal", "filler", "closeoff", "indent-heuristic", "linematch:60", "algorithm:histogram" }

-- Tab, Indent
vim.opt.tabstop = 2
vim.opt.smarttab = true
vim.opt.shiftwidth = 2 -- the number of spaces inserted for each indentation
vim.opt.softtabstop = 2
vim.opt.breakindent = false
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
vim.opt.foldcolumn = "1" -- keep fold arrows in a stable column beside line numbers
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.fillchars = {
  eob = "‿",
  fold = " ",
  foldopen = "",
  foldsep = "⸽",
  foldclose = "",
}
