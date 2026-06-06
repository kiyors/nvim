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

-- FIXED: Project detection autocmd with proper error handling
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("project-detection", { clear = true }),
  pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.json", "*.jsonc" },
  once = true,
  callback = function()
    -- Use pcall to safely execute the detection
    local ok, result = pcall(function()
      local project_utils = require("kiyo.utils.project-utils")
      local dirname = vim.fn.expand("%:p:h")

      -- Use the detection functions that work with your smart configs
      local formatter = project_utils.detect_js_formatter(dirname)
      local linter = project_utils.detect_js_linter(dirname)

      return {
        formatter = formatter,
        linter = linter,
        dirname = dirname,
      }
    end)

    if ok and result then
      -- Only show notification in debug mode or if explicitly needed
      -- Comment out or remove this line if you don't want the notification
      -- vim.notify(
      --   string.format("Project detected - Formatter: %s, Linter: %s", result.formatter, result.linter),
      --   vim.log.levels.INFO,
      --   { title = "Project Config" }
      -- )
    end
  end,
})

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

autocmd({ "CmdWinEnter" }, {
  callback = function()
    vim.cmd("quit")
  end,
})

autocmd({ "BufWinEnter" }, {
  pattern = { "*" },
  callback = function()
    vim.cmd("checktime")
  end,
})

autocmd({ "BufWinEnter" }, {
  pattern = { "*" },
  callback = function()
    local dirname = vim.fn.getcwd():match("([^/]+)$")
    vim.opt.titlestring = dirname
  end,
})

autocmd({ "TextYankPost" }, {
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 40 })
  end,
})

autocmd({ "FileType" }, {
  pattern = { "gitcommit", "markdown", "NeogitCommitMessage" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

autocmd({ "CursorHold" }, {
  callback = function()
    if not package.loaded["luasnip"] then
      return
    end
    local luasnip = require("luasnip")
    if luasnip.expand_or_jumpable() then
      -- ask maintainer for option to make this silent
      -- luasnip.unlink_current()
      vim.cmd([[silent! lua require("luasnip").unlink_current()]])
    end
  end,
})

autocmd("BufWinLeave", {
  pattern = "?*", -- Avoid running for unnamed buffers
  callback = function()
    if vim.fn.empty(vim.fn.expand("%")) == 0 then -- Check if file has a name
      vim.cmd("silent! mkview")
    end
  end,
})

autocmd("BufWinEnter", {
  pattern = "?*", -- Avoid running for unnamed buffers
  callback = function()
    if vim.fn.empty(vim.fn.expand("%")) == 0 and vim.fn.filereadable(vim.fn.expand("%:p")) == 1 then
      vim.cmd("silent! loadview")
    end
  end,
})
