-- plugin declarations (lazy.nvim)

-- bootstrap lazy.nvim
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
