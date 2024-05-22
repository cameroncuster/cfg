-- Notes
--
-- LSP and formatters are installed locally
-- Exclusively supports *.cpp for c++ (*.cxx and *.cc are not supported)

-- settings
vim.opt.number = true -- show line numbers
len = 2
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
vim.opt.ls = 0 -- hide bottom panel
vim.opt.termguicolors = true
vim.g.c_no_curly_error = true -- disable curly brace error: thing[{i, j}]

-- key maps
vim.api.nvim_set_keymap('i', 'kj', '<ESC>', {noremap = true}) -- the OG keymap!
vim.api.nvim_set_keymap('i', '<TAB>', '<C-n>', {noremap = true}) -- tab completion
vim.api.nvim_set_keymap('i', '<S-TAB>', '<C-p>', {noremap = true})
vim.api.nvim_set_keymap('c', 'W', 'w', {noremap = true}) -- :W now writes

vim.api.nvim_set_keymap('n', '<F8>', '<CMD>!wl-paste > input && cat input<CR>', {noremap = true}) -- rip input from clipboard
vim.api.nvim_set_keymap('n', '<F9>', '<CMD>terminal cat > input<CR>', {noremap = true}) -- type a custom input

-- c++ specific keymaps
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'cpp',
  callback = function()
    -- compile and run
    exec = 'cat input && echo "----" && ./%:r.out < input'
    compile_flags = ' -g'
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
    vim.api.nvim_set_keymap('n', '<F4>', '<CMD>w!<CR><CMD>!g++ -std=c++20 -Wall -O2 %:r.cpp -o %:r.out && ' .. exec .. '<CR>', {noremap = true})

    -- save, quick compile, and run
    vim.api.nvim_set_keymap('n', '<F5>', '<CMD>w!<CR><CMD>!g++ -std=c++20 -Wall %:r.cpp -o %:r.out && ' .. exec .. '<CR>', {noremap = true})

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

-- kotlin specific keymaps
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'kotlin',
  callback = function()
    -- save, compile, and run
    vim.api.nvim_set_keymap('n', '<F5>', '<CMD>w!<CR><CMD>!cat input && echo "----" && kotlinc %:r.kt -jvm-target 1.8 -include-runtime -d %:r.jar && java -jar %:r.jar < input<CR>', {noremap = true})
  end,
})

-- auto commands
vim.api.nvim_create_autocmd('BufNewFile', {pattern = '*.cpp', command = '-r template.cpp'}) -- new c++ files default to template
vim.api.nvim_create_autocmd('BufNewFile', {pattern = '*.kt', command = '-r template.kt'}) -- new kotlin files default to template
vim.api.nvim_create_autocmd('BufWritePre', {pattern = '*.cpp,*.hpp,*.rs,*.kt', command = 'silent! execute \'%s/\\s\\+$//ge\''}) -- remove trailing white space during writes

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
  'neovim/nvim-lspconfig',
  'rhysd/vim-clang-format',
  'rust-lang/rust.vim',
  'simrat39/rust-tools.nvim',
  'udalov/kotlin-vim',

  -- mason
  'williamboman/mason.nvim',

  -- copilot
  { 'github/copilot.vim', branch = 'release' },
})

-- LSP
local lspconfig = require('lspconfig')
lspconfig.clangd.setup{} -- c++
lspconfig.rust_analyzer.setup {
  -- server-specific settings. See `:help lspconfig-setup`
  settings = {
    ['rust-analyzer'] = {
      checkOnSave = {
        command = 'clippy',
      },
    },
  },
} -- rust
lspconfig.kotlin_language_server.setup{} -- kotlin

local rt = require('rust-tools')
rt.setup({
  server = {
    on_attach = function(_, bufnr)
      -- hover actions
      vim.keymap.set('n', '<C-space>', rt.hover_actions.hover_actions, { buffer = bufnr })
      -- code action groups
      vim.keymap.set('n', '<Leader>a', rt.code_action_group.code_action_group, { buffer = bufnr })
    end,
  },
})

local format_sync_grp = vim.api.nvim_create_augroup('Format', {})
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.rs',
  callback = function()
    vim.lsp.buf.format({ timeout_ms = 200 })
  end,
  group = format_sync_grp,
})

-- autoformat on save
vim.cmd('autocmd FileType cpp ClangFormatAutoEnable')

-- mason Setup
require('mason').setup()

-- color the copilot suggestions
vim.cmd('highlight link CopilotSuggestion Comment')

