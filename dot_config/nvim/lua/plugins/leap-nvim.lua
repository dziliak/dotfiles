return {
  url = "https://git.disroot.org/andyg/leap.nvim",
  name = "leap.nvim",
  event = "VeryLazy",
  config = function()
    require("leap").setup({})
  end,
}
