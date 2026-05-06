-- lua/plugins/snacks-undo.lua
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        win = {
          input = {
            keys = {
              ["<a-c>"] = { "toggle_cwd", mode = { "n", "i" } },
            },
          },
        },
      },
    },
    keys = {
      {
        "<leader>uu",
        function()
          Snacks.picker.undo()
        end,
        desc = "Undo History",
      },
    },
  },
}
