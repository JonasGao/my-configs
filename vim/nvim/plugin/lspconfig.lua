local lspconfig = require 'lspconfig'

require('vim.lsp.protocol')

local on_attach = function(client, bufnr)
  -- formatting
  -- this will be update reference project 'lspconfig'
  if client.server_capabilities.documentFormattingProvider then
    local api = vim.api
    api.nvim_command [[augroup Format]]
    api.nvim_command [[autocmd! * <buffer>]]
    api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()]]
    api.nvim_command [[augroup END]]
  end
end

lspconfig.sumneko_lua.setup {
  on_attach = on_attach,
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
}

vim.diagnostic.config({
  update_in_insert = true,
  float = {
    source = "always"
  }
})

lspconfig.bashls.setup {}
