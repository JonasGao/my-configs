param(
  [switch]$Install,
  [switch]$Backup
)
if (-not(Test-Path Variable:\MY_CONFIG_HOME))
{
  Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
  Exit 1
}
if ($Install)
{
  $SRC = "$MY_CONFIG_HOME/vim/ideavim/.ideavimrc"
  $DST = "$HOME/.ideavimrc"
}
if ($Backup)
{
  $DST = "$MY_CONFIG_HOME/vim/ideavim/.ideavimrc"
  $SRC = "$HOME/.ideavimrc"
}
delta $DST $SRC
$REPLY = Read-Host -Prompt "Press [y] continue..."
if ($REPLY -eq "y")
{
  Copy-Item "$SRC" "$DST"
  Write-Host -ForegroundColor Green "Finished."
  if ($Backup)
  {
    git add .
    git commit -m "Backup ideavimrc"
  }
}

