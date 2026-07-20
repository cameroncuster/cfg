-- plugin setup: colorscheme, git, telescope, tree, completion, statusline, notes

-- transparent background (use terminal bg, keep syntax colors)
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = 'NONE' })
  end,
})

-- follow the kitty theme: the `theme` zsh command points the
-- ~/.config/kitty/theme.conf symlink at one of the theme-<name>.conf
-- palettes; each maps to a colorscheme here (keep in sync when adding one)
local themes = {
  hacker = { colorscheme = 'nightfox', background = 'dark' },
  day = { colorscheme = 'tokyonight-day', background = 'light' },
  macchiato = { colorscheme = 'catppuccin-macchiato', background = 'dark' },
  latte = { colorscheme = 'catppuccin-latte', background = 'light' },
  kgb = { colorscheme = 'carbonfox', background = 'dark' },
  cia = { colorscheme = 'tokyonight-day', background = 'light' },
  amber = { colorscheme = 'carbonfox', background = 'dark' },
  everforest = { colorscheme = 'everforest', background = 'dark' },
  redshift = { colorscheme = 'carbonfox', background = 'dark' },
  eink = { colorscheme = 'kitty', background = 'light' },
  einkdark = { colorscheme = 'kitty', background = 'dark' },
  nocturne = { colorscheme = 'carbonfox', background = 'dark' },
  spring = { colorscheme = 'kitty', background = 'light' },
  summer = { colorscheme = 'kitty', background = 'light' },
  autumn = { colorscheme = 'kitty', background = 'dark' },
  winter = { colorscheme = 'kitty', background = 'dark' },
  christmas = { colorscheme = 'kitty', background = 'dark' },
  -- 'kitty' (colors/kitty.lua) mirrors the active kitty palette exactly;
  -- used where no plugin colorscheme comes close
  halloween = { colorscheme = 'kitty', background = 'dark' },
  cobol = { colorscheme = 'kitty', background = 'dark' },
  google = { colorscheme = 'tokyonight-day', background = 'light' },
  far = { colorscheme = 'kitty', background = 'dark' },
  fardark = { colorscheme = 'kitty', background = 'dark' },
  nordic = { colorscheme = 'nord', background = 'dark' },
  bourne = { colorscheme = 'kitty', background = 'dark' },
  ice = { colorscheme = 'kitty', background = 'light' },
  sleep = { colorscheme = 'kitty', background = 'dark' },
  darkforest = { colorscheme = 'kitty', background = 'dark' },
  codeforces = { colorscheme = 'kitty', background = 'light' },
  coffee = { colorscheme = 'kitty', background = 'dark' },
  thanksgiving = { colorscheme = 'kitty', background = 'dark' },
  valentine = { colorscheme = 'kitty', background = 'dark' },
  abyss = { colorscheme = 'kitty', background = 'dark' },
  blueprint = { colorscheme = 'kitty', background = 'dark' },
  easter = { colorscheme = 'kitty', background = 'light' },
  apollo = { colorscheme = 'kitty', background = 'dark' },
}
local function apply_kitty_theme()
  local link = vim.uv.fs_readlink(vim.fn.expand('~/.config/kitty/theme.conf'))
  local name = link and link:match('theme%-(%w+)%.conf')
  local theme = themes[name] or themes.hacker
  local prev = vim.g.kitty_theme
  vim.g.kitty_theme = themes[name] and name or 'hacker'
  -- re-apply on kitty-theme change even if the colorscheme is shared
  -- (e.g. day/cia) so the ColorScheme autocmd refreshes the accents
  if vim.g.colors_name ~= theme.colorscheme or prev ~= vim.g.kitty_theme then
    vim.o.background = theme.background
    vim.cmd.colorscheme(theme.colorscheme)
  end
end
apply_kitty_theme()
-- live-follow `theme` runs in other windows: recheck when nvim regains focus
vim.api.nvim_create_autocmd('FocusGained', { callback = apply_kitty_theme })

-- mason
require('mason').setup()

-- gitsigns
require('gitsigns').setup({
  current_line_blame = true,
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol',
    delay = 300,
    ignore_whitespace = false,
  },
  current_line_blame_formatter = '  <author>, <author_time:%Y-%m-%d> - <summary>',
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local opts = function(desc) return { buffer = bufnr, noremap = true, desc = desc } end

    -- navigation
    vim.keymap.set('n', ']c', function() gs.nav_hunk('next') end, opts('Next hunk'))
    vim.keymap.set('n', '[c', function() gs.nav_hunk('prev') end, opts('Prev hunk'))

    -- actions
    vim.keymap.set('n', '<leader>hs', gs.stage_hunk, opts('Stage hunk'))
    vim.keymap.set('n', '<leader>hr', gs.reset_hunk, opts('Reset hunk'))
    vim.keymap.set('n', '<leader>hu', gs.undo_stage_hunk, opts('Undo stage hunk'))
    vim.keymap.set('n', '<leader>hp', gs.preview_hunk, opts('Preview hunk'))
    vim.keymap.set('n', '<leader>hb', function() gs.blame_line({ full = true }) end, opts('Blame line'))
    vim.keymap.set('n', '<leader>hd', gs.diffthis, opts('Diff against index'))
  end,
})

-- diffview setup
--
-- Workaround: select_entry() should focus the diff pane after opening a file,
-- but focus stays in the file panel instead. The root cause is unclear — the
-- diffview source does call nvim_set_current_win() to focus the diff pane,
-- but something in the async flow (coroutine yield/resume) causes focus to
-- end up back in the file panel. vim.schedule runs our wincmd l on the next
-- event loop tick, after everything has settled, so it gets the last word on
-- where focus lands.
local diffview_actions = require('diffview.actions')
require('diffview').setup({
  file_panel = {
    win_config = { width = 50 },
  },
  keymaps = {
    file_panel = {
      { 'n', '<cr>', function()
        diffview_actions.select_entry()
        vim.schedule(function() vim.cmd('wincmd l') end)
      end, { desc = 'Open and focus diff' } },
    },
  },
})

-- diffview keymaps
vim.keymap.set('n', '<leader>do', '<CMD>DiffviewOpen<CR>', { desc = 'Diff vs index' })
vim.keymap.set('n', '<leader>dc', '<CMD>DiffviewClose<CR>', { desc = 'Close diff view' })
vim.keymap.set('n', '<leader>dh', '<CMD>DiffviewFileHistory %<CR>', { desc = 'File history (current file)' })
vim.keymap.set('n', '<leader>dH', '<CMD>DiffviewFileHistory<CR>', { desc = 'File history (all files)' })
vim.keymap.set('n', '<leader>dp', '<CMD>DiffviewOpen origin/main...HEAD<CR>', { desc = 'PR review (vs main)' })
vim.keymap.set('n', '<leader>dm', '<CMD>DiffviewOpen origin/master...HEAD<CR>', { desc = 'PR review (vs master)' })

-- telescope
local actions = require('telescope.actions')
require('telescope').setup({
  defaults = {
    mappings = {
      i = {
        ['<C-j>'] = actions.move_selection_next,
        ['<C-k>'] = actions.move_selection_previous,
      },
    },
  },
})
require('telescope').load_extension('fzf')
local telescope_builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', telescope_builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', telescope_builtin.live_grep, { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', telescope_builtin.buffers, { desc = 'Find buffers' })
vim.keymap.set('n', '<leader>fr', telescope_builtin.oldfiles, { desc = 'Recent files' })
vim.keymap.set('n', '<leader>fc', telescope_builtin.git_commits, { desc = 'Git commits' })
vim.keymap.set('n', '<leader>fs', telescope_builtin.git_status, { desc = 'Git status' })
vim.keymap.set('n', '<leader>fB', telescope_builtin.git_branches, { desc = 'Git branches' })
vim.keymap.set('n', '<leader>fw', function()
  telescope_builtin.live_grep({ default_text = vim.fn.expand('<cword>') })
end, { desc = 'Live grep word under cursor' })
vim.keymap.set('x', '<leader>fw', function()
  local saved, saved_type = vim.fn.getreg('v'), vim.fn.getregtype('v')
  vim.cmd('noautocmd silent normal! "vy')
  local sel = vim.fn.getreg('v'):gsub('\n', ' ')
  vim.fn.setreg('v', saved, saved_type)
  telescope_builtin.live_grep({ default_text = sel })
end, { desc = 'Live grep visual selection' })

-- nvim-tree
require('nvim-tree').setup({
  update_focused_file = {
    enable = true,
    update_root = false,
  },
  -- route icons through NvimTree highlight groups so they pick up the theme below
  renderer = {
    icons = {
      web_devicons = {
        file = { enable = true, color = false },
        folder = { enable = true, color = false },
      },
    },
  },
})
vim.keymap.set('n', '<leader>e', '<CMD>NvimTreeToggle<CR>', { desc = 'Toggle file explorer' })

-- hacker theme, scoped to NvimTree* groups only; matrix green for the
-- phantom-green kitty theme, ice blue for kgb, nothing otherwise (the
-- active colorscheme's own NvimTree groups apply)
-- { fg, dim, bright, cursorline-bg (kitty background) }
local hacker_accents = {
  hacker = { '#00ff41', '#00a82b', '#39ff14', '#0a0a0a' }, -- phantom green
  kgb = { '#00b3ff', '#0072a8', '#33ccff', '#0a0e14' }, -- ice blue
  cia = { '#0b3d66', '#5f7a91', '#0066cc', '#c3d4e3' }, -- navy ink
  amber = { '#ffb000', '#b08d55', '#ffd280', '#0d0a04' }, -- vt220 phosphor
  redshift = { '#ff3b3b', '#b35959', '#ff9e9e', '#0d0404' }, -- red phosphor
  eink = { '#333333', '#999999', '#222222', '#cfccc6' }, -- charcoal ink
  nocturne = { '#a89a7e', '#6a6152', '#bfb096', '#0e0d0b' }, -- candlelight
}
local function nvim_tree_hacker_theme()
  local accent = hacker_accents[vim.g.kitty_theme]
  if not accent then return end
  local green, dim, bright = accent[1], accent[2], accent[3]
  local hl = {
    NvimTreeNormal = { fg = green, bg = 'NONE' },
    NvimTreeNormalNC = { fg = green, bg = 'NONE' },
    NvimTreeEndOfBuffer = { fg = 'NONE', bg = 'NONE' },
    NvimTreeWinSeparator = { fg = dim, bg = 'NONE' },
    NvimTreeRootFolder = { fg = bright, bold = true },
    NvimTreeFolderName = { fg = green },
    NvimTreeOpenedFolderName = { fg = bright, bold = true },
    NvimTreeEmptyFolderName = { fg = dim },
    NvimTreeFolderIcon = { fg = green },
    NvimTreeFileIcon = { fg = dim },
    NvimTreeOpenedFile = { fg = bright, bold = true },
    NvimTreeSymlink = { fg = bright },
    NvimTreeIndentMarker = { fg = dim },
    NvimTreeGitDirty = { fg = bright },
    NvimTreeGitNew = { fg = bright },
    NvimTreeGitStaged = { fg = green },
    NvimTreeGitDeleted = { fg = '#ff0033' },
    NvimTreeCursorLine = { bg = accent[4] },
  }
  for name, val in pairs(hl) do
    vim.api.nvim_set_hl(0, name, val)
  end
end
nvim_tree_hacker_theme()
vim.api.nvim_create_autocmd('ColorScheme', { callback = nvim_tree_hacker_theme })


-- treesitter (built-in in nvim 0.11+, plugin manages parser installs)
vim.api.nvim_create_autocmd('FileType', {
  callback = function() pcall(vim.treesitter.start) end,
})

-- nvim-cmp
local cmp = require('cmp')
local luasnip = require('luasnip')
cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  }),
})

-- autopairs (integrates with cmp)
local autopairs = require('nvim-autopairs')
autopairs.setup()
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

-- lualine
require('lualine').setup({
  options = { theme = 'auto' },
  sections = {
    lualine_b = { 'branch', 'diff', 'diagnostics' },
  },
})

-- which-key
require('which-key').setup()

-- trouble
require('trouble').setup()
vim.keymap.set('n', '<leader>xx', '<CMD>Trouble diagnostics toggle<CR>', { desc = 'Diagnostics' })
vim.keymap.set('n', '<leader>xd', '<CMD>Trouble diagnostics toggle filter.buf=0<CR>', { desc = 'Buffer diagnostics' })
vim.keymap.set('n', '<leader>xl', '<CMD>Trouble loclist toggle<CR>', { desc = 'Location list' })
vim.keymap.set('n', '<leader>xq', '<CMD>Trouble qflist toggle<CR>', { desc = 'Quickfix list' })

-- surround
require('nvim-surround').setup()

-- commenting
require('Comment').setup()

-- obsidian
-- NOTE: point `path` at your Obsidian vault (the folder containing your notes)
-- only load on machines where the vault exists (obsidian errors without one)
local obsidian_vault = vim.fn.expand('~/notes')
if vim.fn.isdirectory(obsidian_vault) == 1 then
  require('obsidian').setup({
    legacy_commands = false,
    workspaces = {
      {
        name = 'notes',
        path = '~/notes',
      },
    },
    -- the markdown renderer handles in-buffer rendering, so disable obsidian's own
    -- UI layer to avoid the two fighting over the same elements.
    ui = { enable = false },
  })
end

-- render-markdown (full in-buffer markdown rendering)
-- latex math is rendered to Unicode via the `latex2text` CLI (pylatexenc);
-- requires the `latex` treesitter parser + latex2text on PATH.
require('render-markdown').setup({
  preset = 'obsidian',
  latex = { enabled = true },
})

-- nabla: on-demand accurate math preview of the equation under the cursor.
-- render-markdown's latex is a Unicode approximation; nabla gives a faithful
-- ASCII-art popup for matrices/aligns/etc. with zero background cost.
vim.keymap.set('n', '<leader>p', function() require('nabla').popup() end, { desc = 'Math: nabla popup' })
