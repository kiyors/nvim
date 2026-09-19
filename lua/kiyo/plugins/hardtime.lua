return {
  "m4xshen/hardtime.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    disable_mouse = false,
    restricted_keys = {
      ["j"] = false,
      ["k"] = false,
      -- optional: also unrestrict wrapped-line moves
      ["gj"] = false,
      ["gk"] = false,
    },
  },
}
