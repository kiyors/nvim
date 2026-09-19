return {
  "folke/todo-comments.nvim",
  cmd = { "TodoTrouble", "TodoTelescope", "TodoLocList", "TodoQuickFix", "TodoFzfLua" },
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    signs = true,
    sign_priority = 8,
    keywords = {
      FIX = {
        icon = " ",
        color = "#f38ba8",
        alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
      },
      TODO = { icon = " ", color = "#89b4fa" },
      HACK = { icon = " ", color = "#fab387", alt = { "DONT SKIP" } },
      WARN = { icon = " ", color = "#f9e2af", alt = { "WARNING", "XXX" } },
      PERF = { icon = " ", color = "#cba6f7", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
      NOTE = { icon = " ", color = "#94e2d5", alt = { "INFO", "READ", "COLORS" } },
      TEST = { icon = "⏲ ", color = "#f5c2e7", alt = { "TESTING", "PASSED", "FAILED" } },
    },
    gui_style = {
      fg = "BOLD",
      bg = "BOLD",
    },
    merge_keywords = true,
    highlight = {
      multiline = true,
      multiline_context = 10,
      before = "",
      keyword = "wide",
      after = "fg",
      pattern = { [[.*<(KEYWORDS)\s*:]], [[.*<(KEYWORDS)\s+]] },
      comments_only = true,
      max_line_len = 400,
      exclude = {},
    },
    colors = {
      error = { "#f38ba8", "DiagnosticError", "ErrorMsg" },
      warning = { "#f9e2af", "DiagnosticWarn", "WarningMsg" },
      info = { "#89b4fa", "DiagnosticInfo" },
      hint = { "#94e2d5", "DiagnosticHint" },
      default = { "#cba6f7", "Identifier" },
      test = { "#f5c2e7", "Identifier" },
    },
    search = {
      command = "rg",
      args = {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
      },
      pattern = [[\b(KEYWORDS):]],
    },
  },
  config = function(_, opts)
    local tc = require("todo-comments")
    tc.setup(opts)

    local H = require("todo-comments.highlight")
    local C = require("todo-comments.config")
    if not C.loaded then
      C._setup()
    end

    -- Allow scratch preview buffers (e.g. Trouble, Snacks picker) to be highlighted
    local orig_is_valid_buf = H.is_valid_buf
    H.is_valid_buf = function(buf)
      if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return false
      end
      local buftype = vim.bo[buf].buftype
      if buftype == "nofile" then
        local ft = vim.bo[buf].filetype
        if ft and ft ~= "" and ft ~= "trouble" and ft ~= "snacks_picker_input" then
          return true
        end
      end
      return orig_is_valid_buf(buf)
    end

    -- Support all comment captures (comment.line, comment.block, comment.doc), markdown, and comment prefix syntax
    local orig_is_comment = H.is_comment
    H.is_comment = function(buf, row, col)
      if vim.bo[buf].filetype == "markdown" then
        return true
      end
      if vim.treesitter.highlighter.active[buf] then
        pcall(function()
          local parser = vim.treesitter.get_parser(buf)
          if parser then
            parser:parse()
          end
        end)
        local captures = vim.treesitter.get_captures_at_pos(buf, row, col)
        for _, c in ipairs(captures) do
          if c.capture and c.capture:find("^comment") then
            return true
          end
        end
      end
      -- Fallback: check standard code comment prefixes on the line
      local line = (vim.api.nvim_buf_get_lines(buf, row, row + 1, false) or {})[1]
      if line then
        local trimmed = line:match("^%s*(.-)$") or ""
        if
          trimmed:find("^//")
          or trimmed:find("^#")
          or trimmed:find("^%-%-")
          or trimmed:find("^/%*")
          or trimmed:find("^%*")
          or trimmed:find("^<!%-%-")
          or trimmed:find("^;")
        then
          return true
        end
      end
      return orig_is_comment(buf, row, col)
    end

    local icon_ns = vim.api.nvim_create_namespace("todo_inline_icons")
    local orig_hl = H.highlight

    -- Render inline icon badge inside the wide background box next to the keyword
    H.highlight = function(buf, first, last, event)
      orig_hl(buf, first, last, event)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      vim.api.nvim_buf_clear_namespace(buf, icon_ns, first, last + 1)
      local marks = vim.api.nvim_buf_get_extmarks(
        buf,
        C.ns,
        { first, 0 },
        { math.max(last, first), -1 },
        { details = true }
      )
      for _, m in ipairs(marks) do
        local hl_group = m[4].hl_group or ""
        if hl_group:find("^TodoBg") then
          local kw = hl_group:gsub("^TodoBg", "")
          local kw_opts = C.options.keywords[kw]
          if kw_opts and kw_opts.icon then
            local line = (vim.api.nvim_buf_get_lines(buf, m[2], m[2] + 1, false) or {})[1]
            if line then
              local s = line:find(kw, m[3] + 1, true)
              local col = s and (s - 1) or m[3]
              vim.api.nvim_buf_set_extmark(buf, icon_ns, m[2], col, {
                virt_text = { { kw_opts.icon .. " ", hl_group } },
                virt_text_pos = "inline",
                priority = 350,
              })
            end
          end
        end
      end
    end

    local orig_stop = H.stop
    H.stop = function()
      orig_stop()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          pcall(vim.api.nvim_buf_clear_namespace, buf, icon_ns, 0, -1)
        end
      end
    end

    -- Ensure newly loaded or switched buffers in any existing window get highlighted immediately
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
      group = vim.api.nvim_create_augroup("TodoCommentsBufferRecovery", { clear = true }),
      callback = function(args)
        local buf = args.buf
        if not vim.api.nvim_buf_is_valid(buf) or not H.is_valid_buf(buf) then
          return
        end
        local win = vim.api.nvim_get_current_win()
        H.attach(win, true)
        H.invalidate(buf, 0, -1)
        pcall(H.highlight, buf, 0, vim.api.nvim_buf_line_count(buf))
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) and H.is_valid_buf(buf) then
            pcall(H.highlight, buf, 0, vim.api.nvim_buf_line_count(buf))
          end
        end)
      end,
    })
  end,
  keys = {
    {
      "]t",
      function()
        require("todo-comments").jump_next()
      end,
      desc = "Next Todo Comment",
    },
    {
      "[t",
      function()
        require("todo-comments").jump_prev()
      end,
      desc = "Previous Todo Comment",
    },
    { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
    {
      "<leader>xT",
      "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>",
      desc = "Todo/Fix/Fixme (Trouble)",
    },
    { "<leader>st", "<cmd>TodoQuickFix<cr>", desc = "Todo (QuickFix)" },
    { "<leader>sT", "<cmd>TodoLocList<cr>", desc = "Todo (LocList)" },
  },
}
