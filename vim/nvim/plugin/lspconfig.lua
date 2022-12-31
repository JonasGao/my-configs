local lspconfig = require'lspconfig'

require('vim.lsp.protocol')

lspconfig.sumneko_lua.setup {
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim'},
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
  bundle_path=pses_path
}

vim.diagnostic.config({
  update_in_insert = true,
  float = {
    source = "always"
  }
})
