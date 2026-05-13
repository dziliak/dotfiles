return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    -- whether markdown should be rendered by default or not
    enabled = true,
    file_types = { "markdown", "telekasten" },
    heading = {
      enabled = true,
      sign = true,
      position = "overlay",
      icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
      signs = { "󰫎 " },
      width = "full",
      left_margin = 0,
      left_pad = 0,
      right_pad = 0,
      min_width = 0,
      border = true,
      border_virtual = false,
      border_prefix = false,
      above = "▄",
      below = "▀",
      backgrounds = {
        "RenderMarkdownH1Bg",
        "RenderMarkdownH2Bg",
        "RenderMarkdownH3Bg",
        "RenderMarkdownH4Bg",
        "RenderMarkdownH5Bg",
        "RenderMarkdownH6Bg",
      },
      foregrounds = {
        "RenderMarkdownH1",
        "RenderMarkdownH2",
        "RenderMarkdownH3",
        "RenderMarkdownH4",
        "RenderMarkdownH5",
        "RenderMarkdownH6",
      },
    },
    callout = {
      note = {
        raw = "[!NOTE]",
        rendered = "󰋽 Note",
        highlight = "RenderMarkdownInfo",
        category = "github",
      },
      tip = {
        raw = "[!TIP]",
        rendered = "󰌶 Tip",
        highlight = "RenderMarkdownSuccess",
        category = "github",
      },
      important = {
        raw = "[!IMPORTANT]",
        rendered = "󰅾 Important",
        highlight = "RenderMarkdownHint",
        category = "github",
      },
      warning = {
        raw = "[!WARNING]",
        rendered = "󰀪 Warning",
        highlight = "RenderMarkdownWarn",
        category = "github",
      },
      caution = {
        raw = "[!CAUTION]",
        rendered = "󰳦 Caution",
        highlight = "RenderMarkdownError",
        category = "github",
      },
      abstract = {
        raw = "[!ABSTRACT]",
        rendered = "󰨸 Abstract",
        highlight = "RenderMarkdownInfo",
        category = "obsidian",
      },
      summary = {
        raw = "[!SUMMARY]",
        rendered = "󰨸 Summary",
        highlight = "RenderMarkdownInfo",
        category = "obsidian",
      },
      tldr = {
        raw = "[!TLDR]",
        rendered = "󰨸 Tldr",
        highlight = "RenderMarkdownInfo",
        category = "obsidian",
      },
      info = {
        raw = "[!INFO]",
        rendered = "󰋽 Info",
        highlight = "RenderMarkdownInfo",
        category = "obsidian",
      },
      todo = {
        raw = "[!TODO]",
        rendered = "󰗡 Todo",
        highlight = "RenderMarkdownInfo",
        category = "obsidian",
      },
      hint = {
        raw = "[!HINT]",
        rendered = "󰌶 Hint",
        highlight = "RenderMarkdownSuccess",
        category = "obsidian",
      },
      success = {
        raw = "[!SUCCESS]",
        rendered = "󰄬 Success",
        highlight = "RenderMarkdownSuccess",
        category = "obsidian",
      },
      check = {
        raw = "[!CHECK]",
        rendered = "󰄬 Check",
        highlight = "RenderMarkdownSuccess",
        category = "obsidian",
      },
      done = {
        raw = "[!DONE]",
        rendered = "󰄬 Done",
        highlight = "RenderMarkdownSuccess",
        category = "obsidian",
      },
      question = {
        raw = "[!QUESTION]",
        rendered = "󰘥 Question",
        highlight = "RenderMarkdownWarn",
        category = "obsidian",
      },
      help = {
        raw = "[!HELP]",
        rendered = "󰘥 Help",
        highlight = "RenderMarkdownWarn",
        category = "obsidian",
      },
      faq = {
        raw = "[!FAQ]",
        rendered = "󰘥 Faq",
        highlight = "RenderMarkdownWarn",
        category = "obsidian",
      },
      attention = {
        raw = "[!ATTENTION]",
        rendered = "󰀪 Attention",
        highlight = "RenderMarkdownWarn",
        category = "obsidian",
      },
      failure = {
        raw = "[!FAILURE]",
        rendered = "󰅖 Failure",
        highlight = "RenderMarkdownError",
        category = "obsidian",
      },
      fail = {
        raw = "[!FAIL]",
        rendered = "󰅖 Fail",
        highlight = "RenderMarkdownError",
        category = "obsidian",
      },
      missing = {
        raw = "[!MISSING]",
        rendered = "󰅖 Missing",
        highlight = "RenderMarkdownError",
        category = "obsidian",
      },
      danger = {
        raw = "[!DANGER]",
        rendered = "󱐌 Danger",
        highlight = "RenderMarkdownError",
        category = "obsidian",
      },
      error = {
        raw = "[!ERROR]",
        rendered = "󱐌 Error",
        highlight = "RenderMarkdownError",
        category = "obsidian",
      },
      bug = {
        raw = "[!BUG]",
        rendered = "󰨰 Bug",
        highlight = "RenderMarkdownError",
        category = "obsidian",
      },
      example = {
        raw = "[!EXAMPLE]",
        rendered = "󰉹 Example",
        highlight = "RenderMarkdownHint",
        category = "obsidian",
      },
      quote = {
        raw = "[!QUOTE]",
        rendered = "󱆨 Quote",
        highlight = "RenderMarkdownQuote",
        category = "obsidian",
      },
      cite = {
        raw = "[!CITE]",
        rendered = "󱆨 Cite",
        highlight = "RenderMarkdownQuote",
        category = "obsidian",
      },
    },
    paragraph = {
      -- Useful context to have when evaluating values.
      -- | text | text value of the node |

      -- Turn on / off paragraph rendering.
      enabled = true,
      -- Additional modes to render paragraphs.
      render_modes = false,
      -- Amount of margin to add to the left of paragraphs.
      -- If a float < 1 is provided it is treated as a percentage of available window space.
      -- Output is evaluated depending on the type.
      -- | function | `value(context)` |
      -- | number   | `value`          |
      left_margin = 0,
      -- Amount of padding to add to the first line of each paragraph.
      -- Output is evaluated using the same logic as 'left_margin'.
      indent = 0,
      -- Minimum width to use for paragraphs.
      min_width = 0,
    },
    checkbox = {
      -- Turn on / off checkbox state rendering
      enabled = true,
      -- Determines how icons fill the available space:
      --  inline:  underlying text is concealed resulting in a left aligned icon
      --  overlay: result is left padded with spaces to hide any additional text
      position = "overlay",
      bullet = false,
      right_pad = 6,
      unchecked = {
        -- Replaces '[ ]' of 'task_list_marker_unchecked'
        icon = "󰄱 ",
        -- Highlight for the unchecked icon
        highlight = "RenderMarkdownUnchecked",
        -- Highlight for item associated with unchecked checkbox
        scope_highlight = nil,
      },
      checked = {
        -- Replaces '[x]' of 'task_list_marker_checked'
        icon = "󰱒 ",
        -- Highlight for the checked icon
        highlight = "RenderMarkdownChecked",
        -- Highlight for item associated with checked checkbox
        scope_highlight = nil,
      },
    },
    indent = {
      enabled = true,
      per_level = 4,
      skip_level = 2,
    },
    html = {
      -- Turn on / off all HTML rendering
      enabled = false,
      comment = {
        -- Turn on / off HTML comment concealing
        conceal = false,
      },
    },
    bullet = {
      -- Turn on / off list bullet rendering
      enabled = true,
      right_pad = 4,
    },
    link = {
      enabled = true,
      render_modes = false,
      footnote = {
        enabled = true,
        superscript = true,
        prefix = "",
        suffix = "",
      },
      image = "󰥶 ",
      email = "󰀓 ",
      hyperlink = "󰌹 ",
      highlight = "RenderMarkdownLink",
      wiki = {
        icon = "󱗖 ",
        body = function()
          return nil
        end,
        highlight = "RenderMarkdownWikiLink",
      },
      custom = {
        web = { pattern = "^http", icon = "󰖟 " },
        discord = { pattern = "discord%.com", icon = "󰙯 " },
        github = { pattern = "github%.com", icon = "󰊤 " },
        gitlab = { pattern = "gitlab%.com", icon = "󰮠 " },
        google = { pattern = "google%.com", icon = "󰊭 " },
        neovim = { pattern = "neovim%.io", icon = " " },
        reddit = { pattern = "reddit%.com", icon = "󰑍 " },
        stackoverflow = { pattern = "stackoverflow%.com", icon = "󰓌 " },
        wikipedia = { pattern = "wikipedia%.org", icon = "󰖬 " },
        youtube = { pattern = "youtube%.com", icon = "󰗃 " },
      },
    },
    latex = {
      enabled = false,
      render_modes = false,
      converter = "latex2text",
      highlight = "RenderMarkdownMath",
      position = "above",
      top_pad = 0,
      bottom_pad = 0,
    },
  },
}
