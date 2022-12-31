local ok, lualine = pcall(require, 'lualine')
if not ok then
  print("Not load lualine")
  return
end

lualine.setup {
  options = {
    icons_enabled = true,
    theme = 'solarized_dark'
  }
}
