local ready, whichkey = pcall(require, "which-key")
if (not ready) then return end

vim.o.timeout = true
vim.o.timeoutlen = 500
whichkey.setup {
  plugins = {
    registers = true,
    presets = {
      motions = true,
      windows = true,
      nav = true,
      text_objects = true,
    },
  },
  hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " },
  triggers_blacklist = {
    -- list of mode / prefixes that should never be hooked by WhichKey
    -- this is mostly relevant for key maps that start with a native binding
    -- most people should not need to change this
    i = { "j", "k" },
    v = { "j", "k" },
  },
  -- disable the WhichKey popup for certain buf types and file types.
  -- Disabled by deafult for Telescope
  disable = {
    buftypes = {},
    filetypes = { "TelescopePrompt" },
  },
}
