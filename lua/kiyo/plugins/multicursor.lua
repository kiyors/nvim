return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- Add or skip cursor above/below the main cursor.
    set({ "n", "x" }, "<up>", function() mc.lineAddCursor(-1) end, { desc = "MC: add cursor above" })
    set({ "n", "x" }, "<down>", function() mc.lineAddCursor(1) end, { desc = "MC: add cursor below" })
    set({ "n", "x" }, "<leader><up>", function() mc.lineSkipCursor(-1) end, { desc = "MC: skip line up" })
    set({ "n", "x" }, "<leader><down>", function() mc.lineSkipCursor(1) end, { desc = "MC: skip line down" })

    -- Match-based cursor add/skip. Moved under <leader>m to avoid clashing with
    -- snacks's <leader>s* search prefix and the <leader>n notifications/noice binding.
    set({ "n", "x" }, "<leader>mn", function() mc.matchAddCursor(1) end, { desc = "MC: match next" })
    set({ "n", "x" }, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "MC: match skip next" })
    set({ "n", "x" }, "<leader>mN", function() mc.matchAddCursor(-1) end, { desc = "MC: match prev" })
    set({ "n", "x" }, "<leader>mS", function() mc.matchSkipCursor(-1) end, { desc = "MC: match skip prev" })

    -- Add a cursor for every match of the word/selection in the buffer.
    set({ "n", "x" }, "<leader>mA", mc.matchAllAddCursors, { desc = "MC: match all" })

    -- Restore last cursor set if you cleared by accident.
    set("n", "<leader>mr", mc.restoreCursors, { desc = "MC: restore cursors" })

    -- Mouse cursor add/remove.
    set("n", "<c-leftmouse>", mc.handleMouse)
    set("n", "<c-leftdrag>", mc.handleMouseDrag)
    set("n", "<c-leftrelease>", mc.handleMouseRelease)

    -- Disable/enable cursors (only main cursor moves while disabled).
    set({ "n", "x" }, "<c-q>", mc.toggleCursor, { desc = "MC: toggle cursors" })

    -- Layer keymaps only apply while multiple cursors are active.
    mc.addKeymapLayer(function(layerSet)
      layerSet({ "n", "x" }, "<left>", mc.prevCursor, { desc = "MC: prev cursor" })
      layerSet({ "n", "x" }, "<right>", mc.nextCursor, { desc = "MC: next cursor" })
      layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor, { desc = "MC: delete main cursor" })
      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    -- Highlight groups.
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { reverse = true })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
    hl(0, "MultiCursorDisabledCursor", { reverse = true })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
  end,
}
