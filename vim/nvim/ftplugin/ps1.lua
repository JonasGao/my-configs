local lspconfig = require'lspconfig'

require('vim.lsp.protocol')

lspconfig.powershell_es.setup {
  bundle_path='d:/PowerShellEditorServices'
}

vim.diagnostic.config({
  update_in_insert = true,
  float = {
    source = "always"
  }
})
