local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- General autocommands
local general = augroup("General", { clear = true })

-- don't auto comment new line
autocmd("BufEnter", {
  group = general,
  command = [[set formatoptions-=cro]],
  desc = "Disable auto-commenting on new lines",
})

-- wrap words "softly" (no carriage return) in mail buffer
autocmd("Filetype", {
  pattern = "mail",
  callback = function()
    vim.opt.textwidth = 0
    vim.opt.wrapmargin = 0
    vim.opt.wrap = true
    vim.opt.linebreak = true
    vim.opt.columns = 80
    vim.opt.colorcolumn = "80"
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "SnacksPicker", { bg = "none", nocombine = true })
    vim.api.nvim_set_hl(0, "SnacksPickerBorder", { bg = "none", nocombine = true })
  end,
})

local project_utils = require("kiyo.utils.project-utils")
project_utils.setup_commands()
project_utils.setup_cache_invalidation()

-- auto close brackets
-- this
autocmd("FileType", { pattern = "man", command = [[nnoremap <buffer><silent> q :quit<CR>]] })

-- Enable spell checking for certain file types
autocmd(
  { "BufRead", "BufNewFile" },
  -- { pattern = { "*.txt", "*.md", "*.tex" }, command = [[setlocal spell<cr> setlocal spelllang=en,de<cr>]] }
  {
    pattern = { "*.txt", "*.md", "*.tex" },
    callback = function()
      vim.opt.spell = true
      vim.opt.spelllang = "en"
    end,
  }
)

-- close some filetypes with <q>
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = {
    "PlenaryTestPopup",
    "DressingSelect",
    "Jaq",
    "checkhealth",
    "git",
    "help",
    "lir",
    "lspinfo",
    "man",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "netrw",
    "notify",
    "oil",
    "qf",
    "query",
    "spectre_panel",
    "startuptime",
    "tsplayground",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- fix terraform and hcl comment string
autocmd("FileType", {
  group = augroup("FixTerraformCommentString", { clear = true }),
  callback = function(ev)
    vim.bo[ev.buf].commentstring = "# %s"
  end,
  pattern = { "terraform", "hcl" },
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  group = general,
  pattern = "*",
  callback = function()
    if not vim.bo.modifiable or vim.bo.filetype == "diff" or vim.bo.filetype == "gitcommit" then
      return
    end
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
  desc = "Remove trailing whitespace",
})

-- Auto-resize splits across all tabs when window is resized
autocmd("VimResized", {
  group = general,
  pattern = "*",
  command = "tabdo wincmd =",
  desc = "Auto-resize splits across tabs",
})

-- Return to last edit position when opening files
autocmd("BufReadPost", {
  group = general,
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
  desc = "Return to last edit position",
})

-- Create directories when saving a file if they don't exist
autocmd("BufWritePre", {
  group = general,
  pattern = "*",
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
  desc = "Auto-create directories",
})

autocmd("CmdWinEnter", {
  group = general,
  callback = function()
    vim.cmd("quit")
  end,
  desc = "Prevent accidental command-line window",
})

autocmd("BufWinEnter", {
  group = general,
  pattern = "*",
  callback = function()
    vim.cmd("checktime")
  end,
  desc = "Check if file changed on disk",
})

local function update_title()
  local dirname = vim.fn.getcwd():match("([^/]+)$")
  if dirname then
    vim.opt.titlestring = dirname
  end
end
update_title()

autocmd("DirChanged", {
  group = general,
  callback = update_title,
  desc = "Update titlestring on directory change",
})

autocmd("TextYankPost", {
  group = general,
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 40 })
  end,
  desc = "Highlight yanked text",
})

autocmd("FileType", {
  group = general,
  pattern = { "gitcommit", "markdown", "NeogitCommitMessage" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
  desc = "Wrap and spell for prose buffers",
})

-- Ensure filetype detection runs if skipped by eventignore or picker window transitions
autocmd({ "BufEnter", "BufWinEnter" }, {
  group = general,
  callback = function(args)
    local buf = args.buf
    if vim.bo[buf].buftype == "" and vim.bo[buf].filetype == "" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and vim.uv.fs_stat(name) then
        vim.cmd("filetype detect")
      end
    end
  end,
  desc = "Recover missing filetype detection after picker transitions",
})

-- Start Treesitter syntax highlighting and folding for supported filetypes
local function start_treesitter(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  local ft = vim.bo[buf].filetype
  -- If filetype is empty for a real file (e.g. eventignore race during picker close), detect it
  if ft == "" and vim.bo[buf].buftype == "" then
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" then
      local detected = vim.filetype.match({ buf = buf, filename = name })
      if detected and detected ~= "" then
        vim.bo[buf].filetype = detected
        ft = detected
      end
    end
  end

  if
    ft == ""
    or ft == "help"
    or ft == "checkhealth"
    or ft == "lazy"
    or ft == "snacks_dashboard"
    or ft == "snacks_notif"
    or ft == "snacks_picker_input"
    or ft == "snacks_picker_preview"
  then
    return
  end

  local lang = vim.treesitter.language.get_lang(ft) or ft
  local ok = pcall(vim.treesitter.start, buf, lang)
  if ok then
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(win) == buf then
      vim.wo[win].foldmethod = "expr"
      vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end
  elseif ft ~= "" and vim.bo[buf].syntax == "" then
    -- Fallback to regex syntax highlighting if treesitter parser is unavailable
    vim.bo[buf].syntax = ft
  end
end

autocmd({ "FileType", "BufEnter", "BufWinEnter" }, {
  group = general,
  callback = function(args)
    start_treesitter(args.buf)
  end,
  desc = "Start Treesitter syntax highlighting and folding",
})

-- Ensure the initial buffer (if opened directly from CLI) has Treesitter highlighting active
start_treesitter(vim.api.nvim_get_current_buf())
