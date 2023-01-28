vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- LSP and Diagnostic
  use 'neovim/nvim-lspconfig'
  use {
    'folke/trouble.nvim',
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup {}
    end
  }

  -- Colorschema
  use {
    'svrana/neosolarized.nvim',
    requires = 'tjdevries/colorbuddy.nvim'
  }

  -- Statusline
  use {
    'hoob3rt/lualine.nvim',
    requires = {
      'kyazdani42/nvim-web-devicons',
      opt = true
    }
  }

  -- Easy motion
  use 'easymotion/vim-easymotion'

  -- fzf
  use {
    'junegunn/fzf',
    run = ":call fzf#install()"
  }
  use 'junegunn/fzf.vim'

  -- Visual Multi
  use 'mg979/vim-visual-multi'

  -- Autocompletion
  use 'onsails/lspkind-nvim'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
  use 'L3MON4D3/LuaSnip' -- Snippets plugin
end)
