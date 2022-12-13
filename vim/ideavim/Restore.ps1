if (-not(Test-Path Variable:\MY_CONFIG_HOME)) {
  throw "There is no MY_CONFIG_HOME"
}
$SRC = "$MY_CONFIG_HOME/vim/ideavim/user.vim"
$DST = "$HOME/.ideavimrc"
nvim -d $DST $SRC
$REPLY = Read-Host -Prompt "Press [y] restore ideavim"
if ($REPLY -eq "y") {
  Copy-Item "$SRC" "$DST"
  Write-Host -ForegroundColor Green "Restore ideavimrc finished."
}
