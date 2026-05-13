return {
  "okuuva/auto-save.nvim",
  version = "^1.0.0",
  cmd = "ASToggle",
  event = { "InsertLeave", "TextChanged" },
  opts = function()
    local excluded_filetypes = {
      "gitcommit",
      "NvimTree",
      "Outline",
      "TelescopePrompt",
      "alpha",
      "dashboard",
      "help",
      "lazy",
      "lazygit",
      "mason",
      "neo-tree",
      "noice",
      "notify",
      "oil",
      "prompt",
      "toggleterm",
      "Trouble",
    }

    local excluded_filenames = {
      "do-not-autosave-me.lua",
    }

    local excluded_buftypes = {
      "nofile",
      "prompt",
      "terminal",
      "quickfix",
      "help",
    }

    local function save_condition(buf)
      local filetype = vim.bo[buf].filetype
      local buftype = vim.bo[buf].buftype
      local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")

      if vim.tbl_contains(excluded_filetypes, filetype) then
        return false
      end

      if vim.tbl_contains(excluded_buftypes, buftype) then
        return false
      end

      if vim.tbl_contains(excluded_filenames, filename) then
        return false
      end

      if not vim.bo[buf].modifiable then
        return false
      end

      if vim.bo[buf].readonly then
        return false
      end

      return true
    end

    return {
      condition = save_condition,
    }
  end,
  keys = {
    { "<leader>uW", "<cmd>ASToggle<CR>", desc = "Toggle auto-save" },
  },
}

-- return {
--   "okuuva/auto-save.nvim",
--   version = "^1.0.0", -- see https://devhints.io/semver, alternatively use '*' to use the latest tagged release
--   cmd = "ASToggle", -- optional for lazy loading on command
--   event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
--   opts = {
--     enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
--     trigger_events = { -- See :h events
--       immediate_save = { "BufLeave", "FocusLost", "QuitPre", "VimSuspend" }, -- vim events that trigger an immediate save
--       defer_save = { "InsertLeave", "TextChanged" }, -- vim events that trigger a deferred save (saves after `debounce_delay`)
--       cancel_deferred_save = { "InsertEnter" }, -- vim events that cancel a pending deferred save
--     },
--     -- function that takes the buffer handle and determines whether to save the current buffer or not
--     -- return true: if buffer is ok to be saved
--     -- return false: if it's not ok to be saved
--     -- if set to `nil` then no specific condition is applied
--     condition = nil,
--     write_all_buffers = false, -- write all buffers when the current one meets `condition`
--     noautocmd = false, -- do not execute autocmds when saving
--     lockmarks = false, -- lock marks when saving, see `:h lockmarks` for more details
--     debounce_delay = 2000, -- delay after which a pending save is executed
--     -- log debug messages to 'auto-save.log' file in neovim cache directory, set to `true` to enable
--     debug = false,
--   },
-- }
