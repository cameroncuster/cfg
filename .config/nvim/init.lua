-- disable netrw because nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- settings
vim.opt.number = true -- show line numbers
len = 2
vim.opt.tabstop = len
vim.opt.shiftwidth = len
vim.opt.wrap = false
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
vim.api.nvim_set_keymap('', '<C-j>', '6j', {noremap = true}) -- faster vertical navigation
vim.api.nvim_set_keymap('', '<C-k>', '6k', {noremap = true})
vim.api.nvim_set_keymap('n', '<CR>', '<CMD>nohlsearch<CR>', {noremap = true}) -- unhighlight search results
vim.api.nvim_set_keymap('n', '<F5>', -- save, remove old executable, and compile
'<CMD>w!<CR>' ..
'<CMD>!rm --force %:r.out && g++ -std=c++20 %:r.cpp -o %:r.out<CR>', {noremap = true})
compile_flags = '-Wall -Wextra -Wunused -Wpedantic -Wshadow -Wlogical-op -Wformat=2 -Wfloat-equal -Wcast-qual -Wcast-align -Wshift-overflow=2 -Wduplicated-cond -O2 -std=c++20 -fstack-protector -D_GLIBCXX_DEBUG -D_GLIBCXX_SANITIZE_VECTOR -D_GLIBCXX_DEBUG_PEDANTIC -D_GLIBCXX_ASSERTIONS -D_FORTIFY_SOURCE=2'
vim.api.nvim_set_keymap('n', '<F6>', -- save, remove old executable, and compile
'<CMD>w!<CR>' ..
'<CMD>!rm --force %:r.out && g++ ' .. compile_flags .. ' %:r.cpp -o %:r.out<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<F9>', '<CMD>!touch input && cat input && echo "----" && ./%:r.out < input<CR>', {noremap = true}) -- run code
vim.api.nvim_set_keymap('n', '<F10>', -- save, run test
'<CMD>w!<CR>' ..
'<CMD>!oj-verify run %:r.cpp<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-t>', '<CMD>NvimTreeToggle<CR>', {noremap = true}) -- open nvim tree

-- enhancements
vim.api.nvim_create_autocmd('BufWrite', { pattern = '*.cpp,*.hpp,*.lua,*.html,*.css', command = 'silent! execute \'%s/\\s\\+$//ge\'' }) -- remove trailing white space during writes

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
	use 'karb94/neoscroll.nvim' -- smooth scroll
	use 'kyazdani42/nvim-tree.lua' -- better file tree than Netrw
	use { -- better git integration
	'lewis6991/gitsigns.nvim',
	requires = {
		'nvim-lua/plenary.nvim'
	},
}
use 'norcalli/nvim-colorizer.lua' -- show color for hex codes
end)
vim.cmd('colorscheme pablo')
vim.cmd('highlight Normal guibg=none') -- transparency
require('neoscroll').setup({ mappings = {'<C-u>', '<C-d>', 'zt', 'zz', 'zb'} }) -- importantly, not <C-e> and <C-y>
-- delete ctrl-k so it uses my 6j keymap instead
-- https://github.com/nvim-tree/nvim-tree.lua/blob/master/doc/nvim-tree-lua.txt
local function my_on_attach(bufnr)
	local api = require('nvim-tree.api')
	local function opts(desc)
		return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end
	api.config.mappings.default_on_attach(bufnr)
	vim.keymap.del('n', '<C-k>', { buffer = bufnr }) -- I want C-k to do 6k
	vim.keymap.del('n', '<C-t>', { buffer = bufnr }) -- I want C-t to close nvim tree (via toggle keybinding)
	vim.keymap.del('n', '<C-e>', { buffer = bufnr }) -- I want default behavior for C-e
end
require("nvim-tree").setup({
	on_attach = my_on_attach,
})
require('gitsigns').setup()
require('colorizer').setup()
