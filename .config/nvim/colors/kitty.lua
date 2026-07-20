-- kitty: colorscheme derived from the active kitty palette.
-- parses ~/.config/kitty/theme.conf (the symlink managed by the `theme`
-- zsh command) and builds highlights from foreground/background + the 16
-- ANSI colors, so nvim matches the terminal exactly. used in ui.lua for
-- kitty themes with no close plugin colorscheme (halloween, cobol, far).

local function parse_kitty_theme()
  local p = {}
  local f = io.open(vim.fn.expand('~/.config/kitty/theme.conf'))
  if not f then return p end
  for line in f:lines() do
    local k, v = line:match('^(%S+)%s+(#%x%x%x%x%x%x)')
    if k then p[k] = v end
  end
  f:close()
  return p
end

local p = parse_kitty_theme()
local function c(n) return p['color' .. n] end
local bg = p.background or '#000000'
local fg = p.foreground or '#ffffff'
-- surface for cursorline/pmenu/statusline: ANSI black works on dark
-- palettes, but on light ones use ANSI white (ui.lua sets 'background'
-- before loading the colorscheme)
local surface = vim.o.background == 'light' and c(7) or c(0)
-- grayscale palettes (eink) can't distinguish syntax by hue, so lean on
-- typography: detect achromatic slots and bold the keyword/function tiers
local function achromatic(hex)
  if not hex then return true end
  local r, g, b = hex:match('#(%x%x)(%x%x)(%x%x)')
  r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
  return math.max(r, g, b) - math.min(r, g, b) <= 12
end
local mono = achromatic(c(1)) and achromatic(c(2)) and achromatic(c(4))

vim.cmd.highlight('clear')
vim.g.colors_name = 'kitty'

for i = 0, 15 do
  vim.g['terminal_color_' .. i] = c(i)
end

local hl = {
  -- ui
  Normal = { fg = fg, bg = bg },
  NormalFloat = { fg = fg, bg = bg },
  FloatBorder = { fg = c(8) },
  Cursor = { fg = p.cursor_text_color, bg = p.cursor },
  CursorLine = { bg = surface },
  CursorLineNr = { fg = c(3), bold = true },
  LineNr = { fg = c(8) },
  SignColumn = { bg = 'NONE' },
  ColorColumn = { bg = surface },
  Visual = { fg = p.selection_foreground, bg = p.selection_background },
  Search = { fg = bg, bg = c(3) },
  IncSearch = { fg = bg, bg = c(11) },
  CurSearch = { link = 'IncSearch' },
  MatchParen = { fg = c(11), bold = true, underline = true },
  Pmenu = { fg = fg, bg = surface },
  PmenuSel = { fg = bg, bg = c(4) },
  PmenuSbar = { bg = surface },
  PmenuThumb = { bg = c(8) },
  StatusLine = { fg = fg, bg = surface },
  StatusLineNC = { fg = c(8), bg = surface },
  WinSeparator = { fg = c(8) },
  VertSplit = { link = 'WinSeparator' },
  TabLine = { fg = fg, bg = surface },
  TabLineSel = { fg = bg, bg = c(4) },
  TabLineFill = { bg = bg },
  Folded = { fg = c(8), bg = surface },
  NonText = { fg = c(8) },
  Whitespace = { fg = c(8) },
  SpecialKey = { fg = c(8) },
  Directory = { fg = c(4) },
  Title = { fg = c(4), bold = true },
  Question = { fg = c(2) },
  MoreMsg = { fg = c(2) },
  ModeMsg = { fg = fg, bold = true },
  ErrorMsg = { fg = c(1), bold = true },
  WarningMsg = { fg = c(3) },
  WildMenu = { fg = bg, bg = c(4) },

  -- syntax (treesitter @groups default-link to these)
  Comment = { fg = c(8), italic = true },
  Constant = { fg = c(5) },
  String = { fg = c(2) },
  Character = { fg = c(2) },
  Number = { fg = c(5) },
  Boolean = { fg = c(5) },
  Float = { fg = c(5) },
  Identifier = { fg = c(6) },
  Function = { fg = c(4), bold = mono },
  Statement = { fg = c(1), bold = mono },
  Keyword = { fg = c(1), bold = mono },
  Conditional = { fg = c(1), bold = mono },
  Repeat = { fg = c(1), bold = mono },
  Operator = { fg = fg },
  PreProc = { fg = c(5) },
  Type = { fg = c(3), italic = mono },
  Special = { fg = c(6) },
  Delimiter = { fg = fg },
  Underlined = { fg = c(4), underline = true },
  Error = { fg = c(1), bold = true },
  Todo = { fg = bg, bg = c(3), bold = true },

  -- diff / git
  DiffAdd = { fg = c(2) },
  DiffChange = { fg = c(3) },
  DiffDelete = { fg = c(1) },
  DiffText = { fg = bg, bg = c(3) },
  Added = { fg = c(2) },
  Changed = { fg = c(3) },
  Removed = { fg = c(1) },
  GitSignsAdd = { fg = c(2) },
  GitSignsChange = { fg = c(3) },
  GitSignsDelete = { fg = c(1) },

  -- diagnostics
  DiagnosticError = { fg = c(1) },
  DiagnosticWarn = { fg = c(3) },
  DiagnosticInfo = { fg = c(4) },
  DiagnosticHint = { fg = c(6) },
  DiagnosticUnderlineError = { sp = c(1), undercurl = true },
  DiagnosticUnderlineWarn = { sp = c(3), undercurl = true },
  DiagnosticUnderlineInfo = { sp = c(4), undercurl = true },
  DiagnosticUnderlineHint = { sp = c(6), undercurl = true },
}

for group, opts in pairs(hl) do
  vim.api.nvim_set_hl(0, group, opts)
end
