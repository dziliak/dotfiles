local function supports_inline_images()
  -- image.nvim's Kitty backend works in Kitty, but not in Neovide.
  return vim.env.KITTY_WINDOW_ID ~= nil and not vim.g.neovide and vim.fn.has("win32") == 0
end

local function jupytext_sync()
  if vim.fn.executable("jupytext") ~= 1 then
    vim.notify("jupytext is not on PATH; install it with `uv tool install jupytext`", vim.log.levels.ERROR)
    return
  end

  local filename = vim.api.nvim_buf_get_name(0)

  if filename == "" then
    vim.notify("The current buffer has no filename", vim.log.levels.WARN)
    return
  end

  vim.cmd("silent write")

  vim.system({ "jupytext", "--sync", filename }, { text = true }, function(result)
    vim.schedule(function()
      local message = vim.trim(table.concat({
        result.stdout or "",
        result.stderr or "",
      }, "\n"))

      if result.code == 0 then
        vim.notify(message ~= "" and message or "Jupytext pair synchronized")
        vim.cmd("checktime")
      else
        vim.notify(message ~= "" and message or "jupytext --sync failed", vim.log.levels.ERROR)
      end
    end)
  end)
end

local function open_jupyterlab()
  -- This opens your existing single JupyterLab server rather than
  -- accidentally launching another server on port 8889.
  vim.ui.open("http://127.0.0.1:8888/lab")
end

return {
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",

    dependencies = {
      "3rd/image.nvim",
    },

    init = function()
      -- Keep output unobtrusive until explicitly entered.
      vim.g.molten_auto_open_output = false

      -- Inline text output.
      vim.g.molten_output_virt_lines = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_text_max_lines = 20
      vim.g.molten_virt_lines_off_by_1 = true

      -- Floating output window.
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_wrap_output = true
      vim.g.molten_output_show_exec_time = true
      vim.g.molten_use_border_highlights = true

      -- Faster polling makes interrupting and receiving output feel better.
      vim.g.molten_tick_rate = 200

      -- Inline plots in Kitty. In Neovide, use MoltenImagePopup instead.
      vim.g.molten_image_provider = supports_inline_images() and "image.nvim" or "none"

      vim.g.molten_image_location = "both"
    end,

    keys = {
      {
        "<leader>ji",
        "<cmd>MoltenInit<cr>",
        desc = "Initialize Jupyter kernel",
      },
      {
        "<leader>jl",
        "<cmd>MoltenEvaluateLine<cr>",
        desc = "Evaluate current line",
      },
      {
        "<leader>jv",
        ":<C-u>MoltenEvaluateVisual<cr>gv",
        mode = "v",
        desc = "Evaluate selection",
      },
      {
        "<leader>jr",
        "<cmd>MoltenReevaluateCell<cr>",
        desc = "Re-evaluate Molten cell",
      },
      {
        "<leader>jo",
        "<cmd>noautocmd MoltenEnterOutput<cr>",
        desc = "Enter output window",
      },
      {
        "<leader>jh",
        "<cmd>MoltenHideOutput<cr>",
        desc = "Hide output",
      },
      {
        "<leader>jx",
        "<cmd>MoltenInterrupt<cr>",
        desc = "Interrupt kernel",
      },
      {
        "<leader>jR",
        "<cmd>MoltenRestart!<cr>",
        desc = "Restart kernel and clear output",
      },
      {
        "<leader>jO",
        "<cmd>MoltenOpenInBrowser<cr>",
        desc = "Open HTML output in browser",
      },
      {
        "<leader>jp",
        "<cmd>MoltenImagePopup<cr>",
        desc = "Open image in system viewer",
      },
      {
        "<leader>jE",
        "<cmd>MoltenExportOutput!<cr>",
        desc = "Export output to paired ipynb",
      },
      {
        "<leader>jI",
        "<cmd>MoltenImportOutput<cr>",
        desc = "Import output from paired ipynb",
      },
      {
        "<leader>js",
        jupytext_sync,
        desc = "Synchronize Jupytext pair",
      },
      {
        "<leader>jL",
        open_jupyterlab,
        desc = "Open JupyterLab",
      },
    },
  },

  {
    "GCBallesteros/NotebookNavigator.nvim",

    dependencies = {
      "benlubas/molten-nvim",
    },

    ft = {
      "python",
    },

    opts = {
      repl_provider = "molten",
      syntax_highlight = true,
    },

    keys = {
      {
        "]j",
        function()
          require("notebook-navigator").move_cell("d")
        end,
        desc = "Next notebook cell",
      },
      {
        "[j",
        function()
          require("notebook-navigator").move_cell("u")
        end,
        desc = "Previous notebook cell",
      },
      {
        "<leader>jc",
        function()
          require("notebook-navigator").run_cell()
        end,
        desc = "Run notebook cell",
      },
      {
        "<leader>jn",
        function()
          require("notebook-navigator").run_and_move()
        end,
        desc = "Run cell and move",
      },
      {
        "<leader>ja",
        function()
          require("notebook-navigator").run_all_cells()
        end,
        desc = "Run all notebook cells",
      },
      {
        "<leader>jB",
        function()
          require("notebook-navigator").run_cells_below()
        end,
        desc = "Run notebook cells below",
      },
    },
  },

  {
    "GCBallesteros/jupytext.nvim",

    -- Direct .ipynb files must be intercepted before Neovim displays JSON.
    lazy = false,

    opts = {
      style = "percent",
      output_extension = "auto",
      force_ft = nil,
    },
  },

  {
    "folke/which-key.nvim",

    opts = {
      spec = {
        {
          "<leader>j",
          group = "jupyter",
          icon = "󰠮",
        },
      },
    },
  },

  {
    "nvim-lualine/lualine.nvim",

    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      table.insert(opts.sections.lualine_x, 1, {
        function()
          local ok, status = pcall(require, "molten.status")

          if not ok then
            return ""
          end

          return status.kernels() or ""
        end,

        cond = function()
          return vim.bo.filetype == "python"
        end,
      })
    end,
  },
}
