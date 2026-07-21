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
-- Headless boxes (e.g. ssh remotes) have no kitty, so nvim can't know which
-- theme is active. Rather than plumb the name across, just follow the
-- terminal's live 16-color ANSI palette like every other ssh program: turn
-- truecolor off here and skip the plugin colorscheme in ui.lua. On kitty boxes
-- keep truecolor + the real colorschemes.
vim.g.headless_term = vim.fn.isdirectory(vim.fn.expand('~/.config/kitty')) == 0
vim.opt.termguicolors = not vim.g.headless_term
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

-- leave terminal-mode (the built-in <C-\><C-n> is awkward); single Esc still
-- reaches the underlying program (lldb/jdb), as does a slow-typed kj
vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], { desc = 'exit terminal-mode' })
vim.keymap.set('t', 'kj', [[<C-\><C-n>]], { desc = 'exit terminal-mode' })

-- :terminal opened from a keymap lands in normal mode: scroll/search the
-- output right away, q or Enter closes (Enter mimics :!'s "Press ENTER to
-- continue"), Ctrl-C interrupts a runaway process without entering
-- terminal-mode. i enters terminal-mode for interactive programs
-- (lldb/jdb), kj/EscEsc above leave it again
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.keymap.set('n', 'q', '<CMD>bd!<CR>', { buffer = true, desc = 'close terminal' })
    vim.keymap.set('n', '<CR>', '<CMD>bd!<CR>', { buffer = true, desc = 'close terminal' })
    local job = vim.bo.channel
    vim.keymap.set('n', '<C-c>', function()
      if vim.fn.jobwait({ job }, 0)[1] == -1 then
        vim.fn.chansend(job, '\003') -- still running: interrupt (SIGINT)
      else
        vim.cmd('bd!') -- already exited: close like q/Enter
      end
    end, { buffer = true, desc = 'interrupt process, or close if exited' })
  end,
})

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
