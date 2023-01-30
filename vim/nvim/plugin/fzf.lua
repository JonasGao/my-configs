local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<space>ff', ':Files<CR>', opts)
vim.keymap.set('n', '<space>fg', ':GFiles<CR>', opts)
vim.keymap.set('n', '<space>fa', ':Ag<CR>', opts)
vim.keymap.set('n', '<space>fr', ':Rg<CR>', opts)
