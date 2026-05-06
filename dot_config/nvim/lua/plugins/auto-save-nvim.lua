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
    { "<leader>n", "<cmd>ASToggle<CR>", desc = "Toggle auto-save" },
  },
}
