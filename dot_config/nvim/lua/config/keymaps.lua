-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local opts = { noremap = true, silent = true }

vim.keymap.set("i", "jk", "<esc>")
vim.keymap.set("i", "kj", "<esc>")
vim.keymap.set("i", "JK", "<esc>")
vim.keymap.set("i", "KJ", "<esc>")

-- Oil
vim.keymap.set("n", "-", ":Oil<CR>", opts)

-- Source and run Lua files
-- vim.keymap.set("n", "<space>rx", "<cmd>source %<CR>")
-- vim.keymap.set("n", "<space>r", ":.lua<CR>")
-- vim.keymap.set("v", "<space>r", ":lua<CR>")
