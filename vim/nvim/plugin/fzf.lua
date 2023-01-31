local opts = { noremap = true, silent = true }
if (vim.fn.has('win32'))
then
  -- telescope
  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>ff', builtin.find_files, opts)
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, opts)
  vim.keymap.set('n', '<leader>fb', builtin.buffers, opts)
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, opts)
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
