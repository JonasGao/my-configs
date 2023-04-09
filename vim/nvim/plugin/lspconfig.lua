local lspconfig = require 'lspconfig'

require('vim.lsp.protocol')

local on_attach = function(client, bufnr)

  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- formatting
  -- this will be update reference project 'lspconfig'
  if client.server_capabilities.documentFormattingProvider then
    local api = vim.api
    api.nvim_command [[augroup Format]]
    api.nvim_command [[autocmd! * <buffer>]]
    api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()]]
    api.nvim_command [[augroup END]]
  end

  local opts = { noremap = true, silent = true }
  vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  -- Instead by lspsaga
  -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  -- vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  -- Instead by lspsaga
  -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)
end

vim.diagnostic.config({
  update_in_insert = true,
  float = {
    source = "always"
  }
})

local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}

-- Add additional capabilities supported by nvim-cmp
local capabilities = require("cmp_nvim_lsp").default_capabilities()

lspconfig.sumneko_lua.setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
}

local pses_path = vim.fn.expand('$HOME/PowerShellEditorServices')
lspconfig.powershell_es.setup {
  on_attach = on_attach,
  bundle_path = pses_path,
  flags = lsp_flags,
  capabilities = capabilities,
}

lspconfig.bashls.setup {
  flags = lsp_flags,
  capabilities = capabilities,
}

local vimls_path = vim.fn.expand('$LOCALAPPDATA/vim-lsp-settings/servers/vim-language-server/vim-language-server.cmd')
lspconfig.vimls.setup {
  -- The lspconfig server_configuration.md provider:
  --   1. runtimepath
  --   2. vimruntime
  -- But, all they are not work.
  -- From nvim-lspconfig sourcecode, i found cmd_cwd option. And it works.
  -- See here https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua#297
  -- like "cmd_cwd = vimls_path"
  -- But, we dont know if there are any side effects
  -- Or we can set "cmd" directly
  cmd = { 'cmd.exe', '/C', vimls_path, '--stdio' }
}
