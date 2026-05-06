-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

vim.g.python3_host_prog = vim.fn.expand("~/Documents/Python Venv/neovim_venv/.venv/bin/python3")

if vim.g.neovide then
  vim.o.guifont = "JetBrainsMono Nerd Font:h14"
  vim.g.neovide_window_blurred = true
  vim.g.neovide_floating_blur_amount_x = 2.0
  vim.g.neovide_floating_blur_amount_y = 2.0
  vim.g.neovide_opacity = 0.8
  vim.g.neovide_normal_opacity = 0.8
end

vim.g.lazyvim_picker = "auto"

vim.opt.undofile = true
vim.opt.undolevels = 10000

local undodir = vim.fn.stdpath("state") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir
