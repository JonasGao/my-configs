function Compare-Ideavimrc()
{
  if (-not(Test-Path Env:\MY_CONFIG_HOME))
  {
    Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
    Exit 1
  }
  $SRC = "$env:MY_CONFIG_HOME/vim/ideavim/.ideavimrc"
  $DST = "$HOME/.ideavimrc"
  delta $DST $SRC
}

function Update-Ideavimrc()
{
  if (-not(Test-Path Env:\MY_CONFIG_HOME))
  {
    Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
    Exit 1
  }
  $SRC = "$env:MY_CONFIG_HOME/vim/ideavim/.ideavimrc"
  $DST = "$HOME/.ideavimrc"
  delta $DST $SRC
  $REPLY = Read-Host -Prompt "Press [y] continue..."
  if ($REPLY -eq "y")
  {
    Copy-Item "$SRC" "$DST"
    Write-Host -ForegroundColor Green "Finished."
  }
}

function Backup-Ideavimrc()
{
  if (-not(Test-Path Env:\MY_CONFIG_HOME))
  {
    Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
    Exit 1
  }
  $DST = "$env:MY_CONFIG_HOME/vim/ideavim/.ideavimrc"
  $SRC = "$HOME/.ideavimrc"
  delta $DST $SRC
  $REPLY = Read-Host -Prompt "Press [y] continue..."
  if ($REPLY -eq "y")
  {
    Copy-Item "$SRC" "$DST"
    Write-Host -ForegroundColor Green "Finished."
    Push-Location "$env:MY_CONFIG_HOME/vim/ideavim"
    git add .
    git commit -m "Backup ideavimrc"
    git push
    Pop-Location
  }
}

Export-ModuleMember -Function Update-Ideavimrc
Export-ModuleMember -Function Backup-Ideavimrc
Export-ModuleMember -Function Compare-Ideavimrc
