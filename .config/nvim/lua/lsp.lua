-- language servers, diagnostics, and format-on-save

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- query-driver lets clangd extract system includes from Homebrew GCC, so
-- libstdc++-only headers like <bits/stdc++.h> resolve in the editor
vim.lsp.config('clangd', {
  cmd = { 'clangd', '--query-driver=/opt/homebrew/bin/g++*,/opt/homebrew/Cellar/gcc/**' },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
  capabilities = capabilities,
})
vim.lsp.config('pyright', {
  filetypes = { 'python' },
  capabilities = capabilities,
})
vim.lsp.config('kotlin_language_server', {
  cmd = { 'kotlin-language-server' },
  filetypes = { 'kotlin' },
  -- fall back to the file's directory so standalone files (no gradle/maven project) still get diagnostics
  root_dir = function(bufnr, on_dir)
    local markers = { 'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts', 'pom.xml' }
    local path = vim.api.nvim_buf_get_name(bufnr)
    on_dir(vim.fs.root(bufnr, markers) or vim.fs.dirname(path))
  end,
  capabilities = capabilities,
})
vim.lsp.config('gopls', {
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  capabilities = capabilities,
})
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

-- rustaceanvim hardcodes an INFO notification every time a standalone .rs
-- file opens ("No project root found. Starting ... in detached/standalone
-- mode"); there's no config option for it, so filter it out of vim.notify
local notify = vim.notify
---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function(msg, ...)
  if type(msg) == 'string' and msg:find('detached/standalone mode', 1, true) then
    return
  end
  return notify(msg, ...)
end

vim.g.rustaceanvim = {
  server = {
    capabilities = capabilities,
    -- silence "Failed to load workspaces" health popups (harmless in single-file mode)
    status_notify_level = false,
    settings = function(project_root)
      -- cargo-based checks only work inside a cargo project; in single-file
      -- (detached) mode they fail loudly, so disable them there
      local has_cargo = project_root and vim.uv.fs_stat(project_root .. '/Cargo.toml') ~= nil
      return {
        ['rust-analyzer'] = {
          checkOnSave = has_cargo,
          check = { command = 'clippy' }, -- lint with clippy on save, like clangd's diagnostics
        },
      }
    end,
  },
}

-- autoformat on save via LSP (minimal-diff edits; clangd for cpp, rust-analyzer for rust, kotlin-language-server for kt)
local format_sync_grp = vim.api.nvim_create_augroup('Format', {})
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.rs', '*.cpp', '*.kt' },
  callback = function() vim.lsp.buf.format({ timeout_ms = 3000 }) -- kotlin-language-server (JVM) can be slow right after startup
  end,
  group = format_sync_grp,
})
