-- Notes
--
-- LSP and formatters are installed locally
-- Exclusively supports *.cpp for c++ (*.cxx and *.cc are not supported)

-- leader key (must be set before any keymaps)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- settings
vim.opt.number = true -- show line numbers
local len = 2
vim.opt.tabstop = len
vim.opt.shiftwidth = len
vim.opt.softtabstop = len
vim.opt.expandtab = true
vim.opt.ignorecase = true -- better search highlight settings
vim.opt.smartcase = true
vim.opt.cindent = true
vim.opt.cino = 'j1,(0,ws,Ws' -- handle indentation inside lambdas correctly
vim.opt.cursorline = true
vim.opt.list = true -- show '>' for tabs and '-' for trailing spaces
vim.opt.wildmode = 'list:longest' -- bash-like tab completion
vim.opt.matchpairs = '(:),{:},[:],<:>' -- <> is not included by default; useful for c++ templates
vim.opt.clipboard = 'unnamedplus' -- sync nvim and OS clipboard
vim.opt.ls = 2 -- always show statusline
vim.opt.termguicolors = true
vim.opt.wrap = true -- wrap lines
vim.opt.linebreak = true -- wrap at word boundaries, not mid-word
vim.opt.conceallevel = 2 -- conceal markup (e.g. obsidian.nvim links/formatting)

-- remember cursor position when reopening files
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})
vim.g.c_no_curly_error = true -- disable curly brace error: thing[{i, j}]
vim.g.augment_workspace_folders = {'~/augment', '~/gitgud'}

-- filetypes
vim.filetype.add({
  extension = {
    jsonnet = 'jsonnet',
    libsonnet = 'jsonnet',
  },
})

-- key maps
vim.keymap.set('i', 'kj', '<ESC>', { desc = 'the OG keymap!' })
vim.keymap.set('c', 'W', 'w')
vim.keymap.set('n', '<F8>', '<CMD>!pbpaste > input && cat input<CR>', { desc = 'Rip input from clipboard' })
vim.keymap.set('n', '<F9>', '<CMD>terminal cat > input<CR>', { desc = 'Type a custom input' })

-- c++ specific keymaps
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'cpp',
  callback = function()
    -- compile and run
    exec = 'cat input && echo "----" && ./%:r.out < input'
    compile_flags = ' -I.'
    .. ' -g'
    .. ' -Wall'
    .. ' -Wextra'
    .. ' -Wunused'
    .. ' -Wshadow'
    .. ' -Wpedantic'
    .. ' -Wformat=2'
    .. ' -Wlogical-op'
    .. ' -Wfloat-equal'
    .. ' -Wcast-qual'
    .. ' -Wcast-align'
    .. ' -Wshift-overflow=2'
    .. ' -Wduplicated-cond'
    .. ' -std=c++20'
    .. ' -fstack-protector'
    --.. ' -fsanitize=address,undefined' does not play nice with GDB
    .. ' -D_GLIBCXX_DEBUG'
    .. ' -D_GLIBCXX_SANITIZE_VECTOR'
    .. ' -D_GLIBCXX_DEBUG_PEDANTIC'
    .. ' -D_GLIBCXX_ASSERTIONS'
    .. ' -D_FORTIFY_SOURCE=2'

    -- save, compile, and quick run
    vim.api.nvim_set_keymap('n', '<F4>', '<CMD>w!<CR><CMD>!g++ -I. -std=c++20 -Wall -O2 %:r.cpp -o %:r.out && ' .. exec .. '<CR>', {noremap = true})

    -- save, quick compile, and run
    vim.api.nvim_set_keymap('n', '<F5>', '<CMD>w!<CR><CMD>!g++ -I. -std=c++20 -Wall %:r.cpp -o %:r.out && ' .. exec .. '<CR>', {noremap = true})

    -- save, debug compile, and run
    vim.api.nvim_set_keymap('n', '<F6>', '<CMD>w!<CR><CMD>!g++ ' .. compile_flags .. ' %:r.cpp -o %:r.out && ' .. exec .. '<CR>', {noremap = true})

    -- debug with GDB
    vim.api.nvim_set_keymap('n', '<F7>', '<CMD>terminal cat input && echo "----" && gdb -q -ex \'set args < input\' %:r.out<CR>', {noremap = true})

    -- run
    vim.api.nvim_set_keymap('n', '<F10>', '<CMD>!' .. exec .. '<CR>', {noremap = true})
  end,
})

-- rust specifc keymaps
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'rust',
  callback = function()
    -- save, compile, and run
    vim.api.nvim_set_keymap('n', '<F5>', '<CMD>w!<CR><CMD>!cat input && echo "----" && cargo run < input<CR>', {noremap = true})
  end,
})

-- python specifc keymaps
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'python',
  callback = function()
    -- save, compile, and run
    vim.api.nvim_set_keymap('n', '<F5>', '<CMD>w!<CR><CMD>!cat input && echo "----" && pypy3 %:r.py < input<CR>', {noremap = true})
  end,
})

-- kotlin specific keymaps
-- note: the filename must start with a capital letter as this doubles as the "class" name
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'kotlin',
  callback = function()
    -- save, compile, and run
    vim.api.nvim_set_keymap('n', '<F5>', '<CMD>w!<CR><CMD>!cat input && echo "----" && kotlinc %:r.kt && kotlin %:rKt.class < input<CR>', {noremap = true})
  end,
})

-- auto commands
vim.api.nvim_create_autocmd('BufNewFile', {pattern = '*.cpp', command = '-r template.cpp'}) -- new c++ files default to template
vim.api.nvim_create_autocmd('BufNewFile', {pattern = '*.kt', command = '-r template.kt'}) -- new kotlin files default to template
vim.api.nvim_create_autocmd('BufWritePre', {pattern = '*.cpp,*.hpp,*.rs,*.kt,*.jsonnet,*.libsonnet', command = 'silent! execute \'%s/\\s\\+$//ge\''}) -- remove trailing white space during writes

-- package management
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- lsp
  'rhysd/vim-clang-format',
  'rust-lang/rust.vim',
  { 'mrcjkb/rustaceanvim', lazy = false },
  'udalov/kotlin-vim',

  -- mason
  'williamboman/mason.nvim',

  -- augment
  'augmentcode/augment.vim',

  -- which-key (keymap discovery)
  'folke/which-key.nvim',

  -- diff viewer
  { 'sindrets/diffview.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },

  -- git signs
  'lewis6991/gitsigns.nvim',

  -- git
  'tpope/vim-fugitive',

  -- seamless vim/tmux pane navigation (C-h/j/k/l)
  'christoomey/vim-tmux-navigator',

  -- telescope (fuzzy finder)
  { 'nvim-telescope/telescope.nvim', dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  }},

  -- file explorer
  'nvim-tree/nvim-tree.lua',
  'nvim-tree/nvim-web-devicons',

  -- treesitter
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },

  -- autocompletion
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-nvim-lsp',
  'hrsh7th/cmp-buffer',
  'hrsh7th/cmp-path',
  'L3MON4D3/LuaSnip',
  'saadparwaiz1/cmp_luasnip',

  -- autopairs
  'windwp/nvim-autopairs',

  -- statusline
  'nvim-lualine/lualine.nvim',

  -- diagnostics viewer
  'folke/trouble.nvim',

  -- surround (cs"' to change, ys for add, ds to delete)
  'kylechui/nvim-surround',

  -- commenting (gcc for line, gc for selection)
  'numToStr/Comment.nvim',

  -- obsidian (note-taking in markdown vaults)
  { 'obsidian-nvim/obsidian.nvim', version = '*' },

  -- markdown renderer (active)
  'MeanderingProgrammer/render-markdown.nvim',

  -- on-demand accurate LaTeX math preview (popup; pairs with the renderer)
  'jbyuki/nabla.nvim',

  -- colorscheme
  { 'EdenEast/nightfox.nvim', lazy = false, priority = 1000 },
})

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
vim.cmd.colorscheme('nightfox')

-- LSP (vim.lsp.config for nvim 0.11+)
local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.config('clangd', { capabilities = capabilities })
vim.lsp.config('pyright', { capabilities = capabilities })
vim.lsp.config('kotlin_language_server', { capabilities = capabilities })
vim.lsp.config('gopls', { capabilities = capabilities })
vim.lsp.config('jsonnet_ls', {
  cmd = { 'jsonnet-language-server' },
  filetypes = { 'jsonnet' },
  root_markers = { { 'jsonnetfile.json', 'jsonnetfile.lock.json' }, '.git' },
  capabilities = capabilities,
})
vim.lsp.config('svelte', {
  cmd = { 'svelteserver', '--stdio' },
  filetypes = { 'svelte' },
  root_markers = { 'package.json', '.git' },
  capabilities = capabilities,
})

-- rustaceanvim manages rust-analyzer — don't add it to vim.lsp.enable
vim.lsp.enable({ 'clangd', 'pyright', 'kotlin_language_server', 'gopls', 'jsonnet_ls', 'svelte' })
vim.g.rustaceanvim = {
  server = {
    capabilities = capabilities,
    settings = {
      ['rust-analyzer'] = {
        checkOnSave = { command = 'clippy' },
      },
    },
  },
}

local format_sync_grp = vim.api.nvim_create_augroup('Format', {})
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.rs',
  callback = function() vim.lsp.buf.format({ timeout_ms = 200 })
  end,
  group = format_sync_grp,
})

-- autoformat on save
vim.cmd('autocmd FileType cpp ClangFormatAutoEnable')

-- mason Setup
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

-- hacker (matrix-green) theme, scoped to NvimTree* groups only
local function nvim_tree_hacker_theme()
  local green, dim, bright = '#00ff5f', '#00a843', '#5fff87'
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
    NvimTreeGitNew = { fg = '#87ff5f' },
    NvimTreeGitStaged = { fg = green },
    NvimTreeGitDeleted = { fg = '#ff5f5f' },
    NvimTreeCursorLine = { bg = '#0a0f0a' },
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
