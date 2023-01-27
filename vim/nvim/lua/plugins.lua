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
end)
