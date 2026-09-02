return {
  "3rd/image.nvim",

  build = false,

  -- Kitty graphics are available in Kitty, but not in Neovide.
  cond = function()
    return vim.env.KITTY_WINDOW_ID ~= nil and not vim.g.neovide
  end,

  opts = {
    backend = "kitty",
    processor = "magick_cli",

    max_width_window_percentage = 80,
    max_height_window_percentage = 45,

    window_overlap_clear_enabled = true,
    editor_only_render_when_focused = true,
  },
}
