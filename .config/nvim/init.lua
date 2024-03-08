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
exec = 'cat input && echo "----" && ./%:r.out < input'
vim.api.nvim_set_keymap('n', '<F5>', -- save, compile, and run
'<CMD>w!<CR>' ..
'<CMD>!g++ -g -Wall -std=c++20 %:r.cpp -o %:r.out &&' .. exec .. '<CR>', {noremap = true})
compile_flags = '-Wall -Wextra -Wunused -Wpedantic -Wshadow -Wlogical-op -Wformat=2 -Wfloat-equal -Wcast-qual -Wcast-align -Wshift-overflow=2 -Wduplicated-cond -std=c++20 -fstack-protector -D_GLIBCXX_DEBUG -D_GLIBCXX_SANITIZE_VECTOR -D_GLIBCXX_DEBUG_PEDANTIC -D_GLIBCXX_ASSERTIONS -D_FORTIFY_SOURCE=2'
vim.api.nvim_set_keymap('n', '<F6>', -- save, compile with flags, and run
'<CMD>w!<CR>' ..
'<CMD>!g++ ' .. compile_flags .. ' %:r.cpp -o %:r.out &&' .. exec .. '<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<F7>', -- run in GDB
'<CMD>term cat input && echo "----" && gdb -q -ex \'set args < input\' %:r.out<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<F8>', '<CMD>term cat > input<CR>', {noremap = true}) -- create input file

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
  use 'wbthomason/packer.nvim' -- Packer can manage itself
  use 'neovim/nvim-lspconfig' -- language server protocol
  use 'rhysd/vim-clang-format' -- autoformat
  use { 'github/copilot.vim', branch = 'release' } -- copilot
end)

-- LSP
local lspconfig = require('lspconfig')
lspconfig.clangd.setup{} -- CPP

-- autoformat on save
vim.cmd('autocmd FileType cpp ClangFormatAutoEnable')

