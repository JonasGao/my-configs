$args | Foreach-Object {
  scp statusline.vim "${_}:/usr/share/vim/vimfiles/plugin/statusline.vim"
}
