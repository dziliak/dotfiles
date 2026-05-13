-- ~/.config/nvim/lua/plugins/bullets.lua
return {
  {
    "bullets-vim/bullets.vim",
    ft = { "markdown", "text", "gitcommit" },

    init = function()
      -- Filetypes where bullets.vim should run
      vim.g.bullets_enabled_file_types = {
        "markdown",
        "text",
        "gitcommit",
      }

      -- Let bullets.vim work in unnamed / empty buffers too
      vim.g.bullets_enable_in_empty_buffers = 1

      -- Keep default mappings enabled
      vim.g.bullets_set_mappings = 1

      -- Useful for Markdown / Obsidian checkboxes
      vim.g.bullets_checkbox_markers = " .oOX"

      -- Delete the final empty bullet when pressing Enter on an empty bullet
      vim.g.bullets_delete_last_bullet_if_empty = 2

      -- Renumber ordered lists automatically
      vim.g.bullets_renumber_on_change = 1

      -- Outline style used when cycling bullet levels
      vim.g.bullets_outline_levels = {
        "num",
        "abc",
        "rom",
        "std-",
        "std*",
        "std+",
      }
    end,
  },
}
