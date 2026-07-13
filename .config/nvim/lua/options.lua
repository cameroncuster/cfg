-- editor settings, general keymaps, and misc autocommands

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

vim.g.c_no_curly_error = true -- disable curly brace error: thing[{i, j}]
vim.g.rust_recommended_style = 0 -- don't force 4-space indent; rustfmt is configured for 2
vim.g.augment_workspace_folders = {'~/augment', '~/gitgud'}

-- filetypes
vim.filetype.add({
  extension = {
    jsonnet = 'jsonnet',
    libsonnet = 'jsonnet',
  },
})

-- general keymaps
vim.keymap.set('i', 'kj', '<ESC>', { desc = 'the OG keymap!' })
vim.keymap.set('c', 'W', 'w')

-- remember cursor position when reopening files
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- remove trailing white space during writes (cpp/rs/kt handled by LSP format)
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.hpp,*.jsonnet,*.libsonnet',
  command = 'silent! execute \'%s/\\s\\+$//ge\'',
})
