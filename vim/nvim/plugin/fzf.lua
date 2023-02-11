local opts = { noremap = true, silent = true }
if vim.fn.has('win32') == 1
then
  local telescope = require('telescope')
  telescope.setup({
    defaults = {
      mappings = {
        i = {
          ["<C-h>"] = "which_key"
        }
      }
    },
    pickers = {
      colorscheme = {
        enable_preview = true
      }
    },
    extensions = {
      file_browser = {
        theme = "ivy",
        -- disables netrw and use telescope-file-browser in its place
        hijack_netrw = true,
        mappings = {
          ["i"] = {
            -- your custom insert mode mappings
          },
          ["n"] = {
            -- your custom normal mode mappings
          },
        },
      },
      fzf = {
        fuzzy = true, -- false will only do exact matching
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = "smart_case", -- or "ignore_case" or "respect_case"
        -- the default case_mode is "smart_case"
      }
    }
  })
  telescope.load_extension "file_browser"
  telescope.load_extension "fzf"
  -- telescope
  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>ff', builtin.find_files, opts)
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, opts)
  vim.keymap.set('n', '<leader>fb', builtin.buffers, opts)
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, opts)
  vim.keymap.set('n', '<leader>fv', builtin.git_files, opts)
  vim.keymap.set('n', '<leader>fe', builtin.oldfiles, opts)
  vim.keymap.set('n', '<leader>fc', builtin.commands, opts)
  vim.keymap.set('n', '<leader>fH', builtin.command_history, opts)
  vim.keymap.set('n', '<leader>fr', builtin.registers, opts)
  vim.keymap.set('n', '<leader>fC', builtin.colorscheme, opts)
else
  -- fzf
  vim.keymap.set('n', '<leader>ff', ':Files<CR>', opts)
  vim.keymap.set('n', '<leader>fv', ':GFiles<CR>', opts)
  vim.keymap.set('n', '<leader>fa', ':Ag<CR>', opts)
  vim.keymap.set('n', '<leader>fr', ':Rg<CR>', opts)
  vim.keymap.set('n', '<leader>fb', ':Buffers<CR>', opts)
  vim.keymap.set('n', '<leader>fc', ':Colors<CR>', opts)
  vim.keymap.set('n', '<leader>fw', ':Windows<CR>', opts)
  vim.keymap.set('n', '<leader>fh', ':History:<CR>', opts)
end
