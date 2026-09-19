local set = vim.opt_local

set.cursorline = true
set.wrap = true
set.breakindent = true
set.foldenable = true
set.foldmethod = "expr"
set.foldexpr = "v:lua.vim.treesitter.foldexpr()"
set.foldlevel = 99 -- Start with all hunks unfolded

local bufnr = vim.api.nvim_get_current_buf()

-- Which-key group registration for diff/patch buffers
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({
    { "<leader>p", group = "Patch", icon = " ", buffer = bufnr },
  })
end

-- Quick navigation between diff hunks and files
vim.keymap.set("n", "]c", function()
  vim.fn.search("^@@", "W")
end, { buffer = bufnr, desc = "Diff: Next Hunk" })

vim.keymap.set("n", "[c", function()
  vim.fn.search("^@@", "bW")
end, { buffer = bufnr, desc = "Diff: Prev Hunk" })

vim.keymap.set("n", "]f", function()
  vim.fn.search("^\\%(diff --git\\|--- \\)", "W")
end, { buffer = bufnr, desc = "Diff: Next File" })

vim.keymap.set("n", "[f", function()
  vim.fn.search("^\\%(diff --git\\|--- \\)", "bW")
end, { buffer = bufnr, desc = "Diff: Prev File" })

-- Helper to extract file path from a diff line
local function extract_file_path(line)
  if not line then
    return nil
  end
  local path = line:match("^diff %-%-git%s+.-%s+[b]/(.+)")
    or line:match("^diff %-%-git%s+[a]/(.+)%s+")
    or line:match("^%+%+%+%s+[ab]/(.+)")
    or line:match("^%+%+%+%s+(.+)")
    or line:match("^%-%-%-%s+[ab]/(.+)")
    or line:match("^%-%-%-%s+(.+)")

  if path and not path:match("^/dev/null") then
    path = path:match("^[^\t]+") or path
    return (path:gsub("^[\"']", ""):gsub("[\"']$", ""))
  end
  return nil
end

-- Jump to the source file at the exact line under cursor
local function jump_to_source()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor_pos[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor_row, false)
  local current_line = lines[cursor_row] or ""

  -- If cursor is directly on a file header line, jump to line 1 of that file
  local header_file = extract_file_path(current_line)
  if
    header_file
    and (
      current_line:match("^diff %-%-git")
      or current_line:match("^%+%+%+")
      or current_line:match("^%-%-%-")
    )
  then
    if vim.fn.filereadable(header_file) == 1 then
      vim.cmd(string.format("edit +1 %s", vim.fn.fnameescape(header_file)))
      return
    end
  end

  -- Find nearest preceding hunk header: @@ -A,B +C,D @@
  local hunk_start_row = nil
  local target_start_line = nil
  for i = #lines, 1, -1 do
    local l = lines[i]
    local start_num = l:match("^@@%s+%-%d+,?%d*%s+%+(%d+)")
    if start_num then
      hunk_start_row = i
      target_start_line = tonumber(start_num)
      break
    end
  end

  if not hunk_start_row then
    -- If no hunk header above, try finding any file header above
    for i = cursor_row, 1, -1 do
      local path = extract_file_path(lines[i])
      if path and vim.fn.filereadable(path) == 1 then
        vim.cmd(string.format("edit +1 %s", vim.fn.fnameescape(path)))
        return
      end
    end
    vim.notify("Diff: No hunk or file header found above cursor", vim.log.levels.WARN)
    return
  end

  -- Find nearest preceding file header: +++ b/<path> or --- a/<path>
  local file_path = nil
  for i = hunk_start_row - 1, 1, -1 do
    local l = lines[i]
    local path = extract_file_path(l)
    if path then
      file_path = path
      break
    end
  end

  if not file_path then
    vim.notify("Diff: No target file header found for this hunk", vim.log.levels.WARN)
    return
  end

  -- Count line offset (skip deleted lines starting with -)
  local line_offset = 0
  for i = hunk_start_row + 1, cursor_row do
    local l = lines[i]
    if l and not l:match("^%-") then
      line_offset = line_offset + 1
    end
  end

  local final_line = math.max(1, target_start_line + math.max(0, line_offset - 1))

  if vim.fn.filereadable(file_path) == 1 then
    vim.cmd(string.format("edit +%d %s", final_line, vim.fn.fnameescape(file_path)))
  else
    vim.notify(string.format("Diff: File not found locally: %s", file_path), vim.log.levels.WARN)
  end
end

vim.keymap.set("n", "gf", jump_to_source, { buffer = bufnr, desc = "Diff: Jump to source line" })
vim.keymap.set("n", "<CR>", jump_to_source, { buffer = bufnr, desc = "Diff: Jump to source line" })

-- Yank current diff hunk to system clipboard
local function yank_hunk()
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, total_lines, false)

  -- Find start of current hunk
  local hunk_start = nil
  for i = cursor_row, 1, -1 do
    if lines[i]:match("^@@") then
      hunk_start = i
      break
    end
  end

  if not hunk_start then
    vim.notify("Diff: Not inside a diff hunk", vim.log.levels.WARN)
    return
  end

  -- Find end of current hunk (next @@ or diff or EOF)
  local hunk_end = total_lines
  for i = hunk_start + 1, total_lines do
    if lines[i]:match("^@@") or lines[i]:match("^diff %-%-git") or lines[i]:match("^%-%-%- ") then
      hunk_end = i - 1
      break
    end
  end

  local hunk_lines = vim.api.nvim_buf_get_lines(bufnr, hunk_start - 1, hunk_end, false)
  local text = table.concat(hunk_lines, "\n") .. "\n"
  vim.fn.setreg('"', text)
  vim.fn.setreg("+", text)
  vim.notify(
    string.format("Yanked hunk (%d lines) to clipboard", #hunk_lines),
    vim.log.levels.INFO,
    { title = "Git Patch" }
  )
end

vim.keymap.set("n", "<leader>py", yank_hunk, { buffer = bufnr, desc = "Patch: Yank current hunk" })

-- Populate Quickfix list with all files and hunks in the patch
local function populate_quickfix()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local qf_list = {}
  local current_file = nil

  for _, line in ipairs(lines) do
    local path = extract_file_path(line)
    if path and (line:match("^%+%+%+") or line:match("^diff %-%-git")) then
      current_file = path
    elseif path and line:match("^%-%-%-") and not current_file then
      current_file = path
    end

    local start_num, hunk_desc = line:match("^@@%s+%-%d+,?%d*%s+%+(%d+),?%d*%s+@@%s*(.*)")
    if start_num and current_file then
      table.insert(qf_list, {
        filename = current_file,
        lnum = tonumber(start_num),
        text = hunk_desc ~= "" and hunk_desc or line,
      })
    end
  end

  if #qf_list > 0 then
    vim.fn.setqflist(qf_list, "r")
    vim.fn.setqflist({}, "a", { title = "Patch Hunks: " .. vim.fn.expand("%:t") })
    vim.cmd("copen")
    vim.notify(
      string.format("Loaded %d hunk(s) into Quickfix", #qf_list),
      vim.log.levels.INFO,
      { title = "Git Patch" }
    )
  else
    vim.notify("No diff hunks found in buffer", vim.log.levels.WARN, { title = "Git Patch" })
  end
end

vim.keymap.set(
  "n",
  "<leader>pq",
  populate_quickfix,
  { buffer = bufnr, desc = "Patch: Load hunks into Quickfix" }
)

-- Helper to run git apply commands on the current buffer
local function run_git_apply(args, action_name)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" or vim.bo[bufnr].modified then
    vim.cmd("write")
    file = vim.api.nvim_buf_get_name(bufnr)
  end

  local cmd = string.format("git apply %s %s", args, vim.fn.shellescape(file))
  local output = vim.fn.system(cmd)
  local code = vim.v.shell_error

  if code == 0 then
    local msg = output ~= "" and output or (action_name .. " successful!")
    vim.notify(msg, vim.log.levels.INFO, { title = "Git Patch" })
  else
    vim.notify(
      output ~= "" and output or (action_name .. " failed with error " .. code),
      vim.log.levels.ERROR,
      { title = "Git Patch" }
    )
  end
end

-- Patch operations for patch/diff files
vim.keymap.set("n", "<leader>pc", function()
  run_git_apply("--check", "Patch check")
end, { buffer = bufnr, desc = "Patch: Check if applies cleanly" })

vim.keymap.set("n", "<leader>pa", function()
  run_git_apply("", "Patch apply")
end, { buffer = bufnr, desc = "Patch: Apply to repository" })

vim.keymap.set("n", "<leader>ps", function()
  run_git_apply("--cached", "Patch stage")
end, { buffer = bufnr, desc = "Patch: Apply to Git index (stage)" })

vim.keymap.set("n", "<leader>pr", function()
  run_git_apply("--reverse", "Reverse patch apply")
end, { buffer = bufnr, desc = "Patch: Reverse apply" })

vim.keymap.set("n", "<leader>p3", function()
  run_git_apply("-3", "3-way patch apply")
end, { buffer = bufnr, desc = "Patch: 3-way apply" })
