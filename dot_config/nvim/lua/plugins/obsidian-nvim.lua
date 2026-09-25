local function get_note_date(ctx)
  -- When obsidian.nvim is creating/cloning the daily note,
  -- partial_note.id will be the filename stem, e.g. "2026-09-23".
  if ctx.partial_note and ctx.partial_note.id then
    local id = tostring(ctx.partial_note.id)

    if id:match("^%d%d%d%d%-%d%d%-%d%d$") then
      return id
    end
  end

  -- Fallback for manually inserting the template into a daily note.
  local filename = vim.fn.expand("%:t:r")

  if filename:match("^%d%d%d%d%-%d%d%-%d%d$") then
    return filename
  end

  return os.date("%Y-%m-%d")
end

local function adjacent_workday(ctx, direction)
  local date = get_note_date(ctx)

  local year, month, day = date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")

  local timestamp = os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = 12,
  })

  repeat
    local t = os.date("*t", timestamp)

    t.day = t.day + direction

    -- Keeping this at noon avoids DST boundary weirdness.
    t.hour = 12
    t.min = 0
    t.sec = 0
    t.isdst = nil

    timestamp = os.time(t)

    -- os.date("%w"):
    -- 0 = Sunday
    -- 6 = Saturday
    local weekday = tonumber(os.date("%w", timestamp))
  until weekday ~= 0 and weekday ~= 6

  return os.date("%Y-%m-%d", timestamp)
end

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = false,
  ft = "markdown",

  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
  },

  init = function()
    require("config.tasknotes").setup()
  end,

  opts = {
    legacy_commands = false,

    workspaces = {
      {
        name = "personal",
        path = "~/Documents/Obsidian/obsidian_vault/",
      },
    },

    daily_notes = {
      folder = "Dailies",
      date_format = "YYYY-MM-DD",
      default_tags = { "Daily" },
      template = "Daily Template Neovim",
      workdays_only = true,
    },

    ui = {
      enable = false,
    },

    templates = {
      folder = "Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",

      substitutions = {
        note_date = function(ctx)
          return get_note_date(ctx)
        end,

        previous_workday = function(ctx)
          return adjacent_workday(ctx, -1)
        end,

        next_workday = function(ctx)
          return adjacent_workday(ctx, 1)
        end,
      },
    },

    picker = {
      name = "snacks.picker",

      note_mappings = {
        new = "<C-x>",
        insert_link = "<C-l>",
      },

      tag_mappings = {
        tag_note = "<C-x>",
        insert_tag = "<C-l>",
      },
    },

    note_id_func = function(title)
      return title
    end,
  },
}
