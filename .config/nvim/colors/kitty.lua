-- kitty: colorscheme derived from the active kitty palette.
-- parses ~/.config/kitty/theme.conf (the symlink managed by the `theme`
-- zsh command) and builds highlights from foreground/background + the 16
-- ANSI colors, so nvim matches the terminal exactly. used in ui.lua for
-- kitty themes with no close plugin colorscheme (halloween, cobol, far).

local function parse_kitty_theme()
  local p = {}
  -- read the live kitty symlink (managed by the `theme` zsh command).
  -- resolve to the real absolute path first: theme.conf is often a *relative*
  -- symlink (-> theme-<name>.conf), and io.open would resolve that against the
  -- process CWD, not the symlink's directory, so it fails whenever nvim's CWD
  -- isn't ~/.config/kitty. an empty parse leaves every color nil, which used
  -- to abort the whole colorscheme (and drop diffs onto nvim's defaults).
  local path = vim.fn.expand('~/.config/kitty/theme.conf')
  path = vim.uv.fs_realpath(path) or path
  local f = io.open(path)
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
-- blend two #rrggbb colors by ratio t (0 = a, 1 = b). used to build subtle
-- diff backgrounds by mixing an accent into the theme's surface tone so diff
-- mode tints the line without hiding treesitter syntax colors. nil-safe: if
-- either color is missing or malformed (a partial palette parse), fall back
-- to whichever color is present rather than throwing — a thrown error here
-- would abort the whole colorscheme load and drop us onto nvim defaults.
local function blend(a, b, t)
  local ar, ag, ab = (a or ''):match('#(%x%x)(%x%x)(%x%x)')
  local br, bg_, bb = (b or ''):match('#(%x%x)(%x%x)(%x%x)')
  if not (ar and br) then return a or b end
  local function mix(x, y)
    return math.floor(tonumber(x, 16) * (1 - t) + tonumber(y, 16) * t + 0.5)
  end
  return string.format('#%02x%02x%02x', mix(ar, br), mix(ag, bg_), mix(ab, bb))
end
-- diff backgrounds: mix each accent into `surface` (the same tone used for
-- CursorLine/Pmenu, e.g. the theme's dark base ANSI slot) rather than into
-- the true background. blending against surface keeps the tint in the theme's
-- own color family so it reads as a subtle highlight instead of a dark block
-- against the (transparent) terminal background.
local diff_mix = vim.o.background == 'light' and 0.55 or 0.68
local diff_add_bg = blend(c(2), surface, diff_mix)
local diff_del_bg = blend(c(1), surface, diff_mix)
local diff_chg_bg = blend(c(3), surface, diff_mix)
-- DiffText (the changed region within a changed line) sits on top of
-- DiffChange, so tint it a touch stronger for contrast.
local diff_txt_bg = blend(c(3), surface, diff_mix - 0.22)

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
  -- diff-mode groups (used by :diffthis and diffview) tint the whole line, so
  -- set only a subtle background and leave fg unset — treesitter syntax colors
  -- then show through instead of the line flattening to one accent color.
  DiffAdd = { bg = diff_add_bg },
  DiffChange = { bg = diff_chg_bg },
  DiffDelete = { fg = c(8), bg = diff_del_bg },
  DiffText = { bg = diff_txt_bg },
  -- Added/Changed/Removed (inline git text, e.g. gitsigns previews) stay
  -- foreground-only — they mark short spans, not whole lines.
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
