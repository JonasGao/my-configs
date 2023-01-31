local opts = { noremap = true, silent = true }
if (vim.fn.has('win32'))
then
  -- telescope
  vim.keymap.set('n', '<leader>ff', ':Files<CR>', opts)
else
  -- fzf
  vim.keymap.set('n', '<leader>ff', ':Files<CR>', opts)
  vim.keymap.set('n', '<leader>fg', ':GFiles<CR>', opts)
  vim.keymap.set('n', '<leader>fa', ':Ag<CR>', opts)
  vim.keymap.set('n', '<leader>fr', ':Rg<CR>', opts)
  vim.keymap.set('n', '<leader>fb', ':Buffers<CR>', opts)
  vim.keymap.set('n', '<leader>fc', ':Colors<CR>', opts)
  vim.keymap.set('n', '<leader>fw', ':Windows<CR>', opts)
  vim.keymap.set('n', '<leader>fh', ':History:<CR>', opts)
end
