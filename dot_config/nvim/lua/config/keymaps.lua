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

vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)")
vim.keymap.set("n", "S", "<Plug>(leap-from-window)")

vim.keymap.set("n", "<leader>ob", ":Obsidian backlinks<CR>", opts)
vim.keymap.set("n", "<leader>od", ":Obsidian today<CR>", opts)
vim.keymap.set("n", "<leader>op", ":ObsidianBridgePickCommand<CR>", opts)
vim.keymap.set("n", "<leader>oo", ":Obsidian<CR>", opts)
vim.keymap.set("n", "<leader>os", ":Obsidian search<CR>", opts)
vim.keymap.set("n", "<leader>ot", ":Obsidian tomorrow<CR>", opts)
vim.keymap.set("n", "<leader>oq", ":Obsidian quick_switch<CR>", opts)
vim.keymap.set("v", "<leader>ox", ":ObsidianExtractNote", opts)
vim.keymap.set("n", "<leader>oy", ":Obsidian yesterday<CR>", opts)

-- Helper: build the WebReq markdown link from the clipboard URL
local function paste_webreq_link()
  -- Get the clipboard contents (works with the system clipboard on most platforms)
  local url = vim.fn.getreg("+")
  if url == "" then
    vim.notify("Clipboard is empty – cannot create WebReq link", vim.log.levels.ERROR)
    return
  end

  -- Extract the poID number from the URL (e.g. poID=69696)
  local id = url:match("poID=(%d+)")
  if not id then
    vim.notify("Clipboard does not contain a valid WebReq URL", vim.log.levels.ERROR)
    return
  end

  -- Build the markdown link
  local md = string.format("[WebReq - %s](%s)", id, url)

  -- Insert it at the cursor position in normal mode
  vim.api.nvim_put({ md }, "c", true, true)
end

-- Map <leader>Pw to the function above
vim.keymap.set(
  "n",
  "<leader>Pw",
  paste_webreq_link,
  { noremap = true, silent = true, desc = "Paste WebReq markdown link from clipboard" }
)

-- local Snacks = require("snacks")
--
-- Snacks.toggle({
--   name = "Autosave",
--   get = function()
--     return require("auto-save").state()
--   end,
--   set = function(state)
--     if state then
--       require("auto-save").toggle()
--     else
--       require("auto-save").toggle()
--     end
--   end,
-- }):map("<leader>uW")
