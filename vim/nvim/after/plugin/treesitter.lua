local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

ts.setup {
  -- A list of parser names, or "all" (the four listed parsers should always be installed)
  ensure_installed = {
    "lua",
    "vim",
    "help",
    "java",
    "markdown",
    "tsx",
    "toml",
    "fish",
    "php",
    "json",
    "yaml",
    "css",
    "html",
    "ini",
    "rust",
    "go",
    "bash",
  },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  -- List of parsers to ignore installing (for "all")
  ignore_install = { "javascript" },

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    -- `false` will disable the whole extension
    enable = true,

    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    disable = {},

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },

  indent = {
    enable = true,
    disable = {},
  },

  autotag = {
    enable = true,
  },
}

-- Current has bug when open file with telescope
-- See here: https://github.com/nvim-telescope/telescope.nvim/issues/699
-- The issue provider some workaround
--
-- 1.
-- vim.api.nvim_create_autocmd({ "BufEnter" }, {
--     pattern = { "*" },
--     command = "normal zx zR",
-- })
--
-- 2.
-- After open file by telescope, run :e again.
--
-- If want default no fold, set:
-- vim.opt.foldenable = false

vim.api.nvim_create_user_command('TSFold', function()
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
end, {
  desc = 'Enable fold based on tree-sitter'
})

vim.keymap.set('n', '<leader>zt', ':TSFold<CR>', { noremap = true })
