local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<space>ff', ':Files', opts)
vim.keymap.set('n', '<space>fg', ':GFiles', opts)
vim.keymap.set('n', '<space>fa', ':Ag', opts)
vim.keymap.set('n', '<space>fr', ':Rg', opts)
