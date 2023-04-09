local ready, whichkey = pcall(require, "which-key")
if (not ready) then return end

vim.o.timeout = true
vim.o.timeoutlen = 500
whichkey.setup {
  plugins = {
    marks = true,
    registers = true,
    presets = {
      motions = true,
      windows = true,
      nav = true,
      text_objects = true,
    },
  },
  hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "^call ", "^lua ", "^:", "^ " },
  triggers_blacklist = {
    -- list of mode / prefixes that should never be hooked by WhichKey
    -- this is mostly relevant for key maps that start with a native binding
    -- most people should not need to change this
    i = { "j", "k" },
    v = { "j", "k" },
  },
  show_help = true,
  show_keys = true,
  -- disable the WhichKey popup for certain buf types and file types.
  -- Disabled by deafult for Telescope
  disable = {
    buftypes = {},
    filetypes = { "TelescopePrompt" },
  },
}

whichkey.register({
  f = {
    name = "Fuzzy Finder",
    f = { "<cmd>Telescope find_files<cr>", "find_files" },
    g = { "<cmd>Telescope live_grep<cr>", "live_grep" },
    b = { "<cmd>Telescope buffers<cr>", "buffers" },
    h = { "<cmd>Telescope help_tags<cr>", "help_tags" },
    v = { "<cmd>Telescope git_files<cr>", "git_files" },
    e = { "<cmd>Telescope oldfiles<cr>", "oldfiles" },
    c = { "<cmd>Telescope commands<cr>", "commands" },
    H = { "<cmd>Telescope command_history<cr>", "command_history" },
    r = { "<cmd>Telescope registers<cr>", "registers" },
    C = { "<cmd>Telescope colorscheme<cr>", "colorscheme" },
  }
}, { prefix = "<leader>" })
