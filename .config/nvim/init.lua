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

-- rip input from clipboard
vim.api.nvim_set_keymap('n', '<F8>', '<CMD>!wl-paste > input && cat input<CR>', {noremap = true})

-- type a custom input
vim.api.nvim_set_keymap('n', '<F9>', '<CMD>terminal cat > input<CR>', {noremap = true})

-- run
vim.api.nvim_set_keymap('n', '<F10>', '<CMD>!' .. exec .. '<CR>', {noremap = true})

-- auto commands
vim.api.nvim_create_autocmd('BufNewFile', {pattern = '*.cpp', command = '-r template.cpp'}) -- new cpp files default to template
vim.api.nvim_create_autocmd('BufWritePre', {pattern = '*.cpp,*.hpp', command = 'silent! execute \'%s/\\s\\+$//ge\''}) -- remove trailing white space during writes

-- package management
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

require('packer').startup(function() -- :PackerSync to reload (run after all changes)
  -- packer can manage itself
  use 'wbthomason/packer.nvim'

  -- lsp
  use 'neovim/nvim-lspconfig'
  use 'simrat39/rust-tools.nvim'
  use 'rust-lang/rust.vim'
  use 'rhysd/vim-clang-format'

  -- mason
  use 'williamboman/mason.nvim'

  -- copilot
  use { 'github/copilot.vim', branch = 'release' }
end)

-- LSP
local lspconfig = require('lspconfig')
lspconfig.clangd.setup{} -- CPP
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

local rt = require('rust-tools')
rt.setup({
  server = {
    on_attach = function(_, bufnr)
      -- hover actions
      vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
      -- code action groups
      vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
    end,
  },
})

local format_sync_grp = vim.api.nvim_create_augroup("Format", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.rs",
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

