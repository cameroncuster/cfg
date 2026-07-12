-- Notes
--
-- LSP and formatters are installed locally
-- Exclusively supports *.cpp for c++ (*.cxx and *.cc are not supported)
--
-- modules (lua/):
--   options  editor settings, general keymaps, misc autocommands
--   plugins  plugin declarations (lazy.nvim)
--   lsp      language servers, diagnostics, format-on-save
--   cp       competitive programming: F4-F10 keymaps + templates
--   ui       plugin setup: colorscheme, git, telescope, completion, ...

-- leader key (must be set before any keymaps)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('options')
require('plugins')
require('lsp')
require('cp').setup()
require('ui')
