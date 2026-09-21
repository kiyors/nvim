return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Added: Explicitly declare the required dependency
  },
  ---@type obsidian.config
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/personal/obsidian/brain-log",
      },
    },
    daily_notes = {
      folder = "daily-note",
      date_format = "%Y-%m-%d-%A",
      alias_format = "%a %-d %B %Y",
      template = "daily note.md",
      workdays_only = false,
    },
    completion = {
      min_chars = 2,
      create_new = true,
    },
    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.date("%Y%m%d%H%M%S")) .. "-" .. suffix
    end,
    note_path_func = function(spec)
      return (spec.dir / tostring(spec.id)):with_suffix(".md")
    end,
    link = {
      style = "wiki",
      ---@param opts obsidian.link.WikiLinkOpts
      ---@return string
      wiki = function(opts)
        local header_or_block = ""
        if opts.anchor then
          header_or_block = string.format("#%s", opts.anchor.header)
        elseif opts.block then
          header_or_block = string.format("#%s", opts.block.id)
        end
        return string.format("[[%s%s]]", opts.label, header_or_block)
      end,
      ---@param opts obsidian.link.MarkdownLinkOpts
      ---@return string
      markdown = function(opts)
        return require("obsidian.util").markdown_link(opts)
      end,
    },

    frontmatter = {
      enabled = true,
      update_today = true,
    },

    templates = {
      folder = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {
        week = function()
          return tostring(os.date("%V"))
        end,
        day = function()
          return tostring(os.date("%A"))
        end,
      },
    },
    open = {
      use_advanced_uri = false,
      func = vim.ui.open,
    },
    picker = {
      name = "snacks.picker",
      notemappings = {
        new = "<C-x>",
        insert_link = "<C-l>",
      },
      tag_mappings = {
        tag_note = "<C-x>",
        insert_tag = "<C-l>",
      },
    },
    backlinks = {
      parse_headers = true,
    },
    search = {
      sort_by = "modified",
      sort_reversed = true,
      max_lines = 1000,
    },
    open_notes_in = "current",

    callbacks = {
      -- Set up buffer-local keymaps for obsidian notes
      enter_note = function(note)
        -- Improved: Use a localized options table for cleaner keymap definitions
        local map_opts = { buffer = note.bufnr, silent = true }

        vim.keymap.set(
          "n",
          "<localleader>d",
          "<cmd>ObsidianDailies 1<cr>",
          vim.tbl_extend("force", map_opts, { desc = "Show dailies" })
        )
        vim.keymap.set(
          "n",
          "<localleader>x",
          "<cmd>ObsidianToggleCheckbox<cr>",
          vim.tbl_extend("force", map_opts, { desc = "Toggle checkbox" })
        )
        vim.keymap.set(
          "n",
          "<localleader>l",
          "<cmd>ObsidianLinks<cr>",
          vim.tbl_extend("force", map_opts, { desc = "Search links" })
        )
        vim.keymap.set(
          "n",
          "<localleader>b",
          "<cmd>ObsidianBacklinks<cr>",
          vim.tbl_extend("force", map_opts, { desc = "Search backlinks" })
        )
        vim.keymap.set(
          "n",
          "<localleader>t",
          "<cmd>ObsidianTemplate<cr>",
          vim.tbl_extend("force", map_opts, { desc = "Insert Template" })
        )
        vim.keymap.set(
          "n",
          "<localleader>p",
          "<cmd>ObsidianPasteImg<cr>",
          vim.tbl_extend("force", map_opts, { desc = "Paste clipboard image" })
        )
        vim.keymap.set(
          "n",
          "<localleader>r",
          "<cmd>ObsidianRename<cr>",
          vim.tbl_extend("force", map_opts, { desc = "Rename Note" })
        )
      end,
    },

    ui = {
      enable = false, -- Disabled to allow markview.nvim to take over rendering
    },
    attachments = {
      folder = "public/",
      img_name_func = function()
        return string.format("Pasted image %s", os.date("%Y%m%d%H%M%S"))
      end,
      confirm_img_paste = true,
    },
    footer = {
      enabled = true,
      format = "{{backlinks}} backlinks  {{properties}} properties  {{words}} words  {{chars}} chars",
      hl_group = "Comment",
      separator = string.rep("-", 80),
    },
    checkbox = {
      order = { " ", "x", ">", "-", "/" },
    },
    legacy_commands = false,
  },
  keys = {
    { "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Today's Note" },
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New Note" },
    { "<leader>oo", "<cmd>ObsidianQuickSwitch<cr>", desc = "Open Quick Switcher" },
    { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search Notes" },
    { "<leader>ot", "<cmd>ObsidianTags<cr>", desc = "Search Tags" },
  },
}
