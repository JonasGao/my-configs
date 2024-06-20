function prepare()
{
  if (-not(Test-Path Env:\MY_CONFIG_HOME))
  {
    Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
    Exit 1
  }
  $rcSrc = "vims/ideavim/.ideavimrc"
  $rcDst = ".ideavimrc"
  $script:src = "$env:MY_CONFIG_HOME/$rcSrc"
  $script:dst = "$HOME/$rcDst"
}

function Compare-Ideavimrc()
{
  if (-not(Test-Path Env:\MY_CONFIG_HOME))
  {
    Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
    Exit 1
  }
  prepare
  delta $script:dst $Script:src
}

function Update-Ideavimrc()
{
  if (-not(Test-Path Env:\MY_CONFIG_HOME))
  {
    Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
    Exit 1
  }
  prepare
  delta $script:dst $Script:src
  $REPLY = Read-Host -Prompt "Press [y] continue..."
  if ($REPLY -eq "y")
  {
    Copy-Item "$script:src" "$script:dst"
    Write-Host -ForegroundColor Green "Finished."
  }
}

function Save-Ideavimrc()
{
  if (-not(Test-Path Env:\MY_CONFIG_HOME))
  {
    Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
    Exit 1
  }
  delta $script:dst $script:src
  $REPLY = Read-Host -Prompt "Press [y] continue..."
  if ($REPLY -eq "y")
  {
    Copy-Item "$script:src" "$script:dst"
    Write-Host -ForegroundColor Green "Finished."
    Push-Location "$env:MY_CONFIG_HOME/vim/ideavim"
    git add .
    git commit -m "Backup ideavimrc"
    git push
    Pop-Location
  }
}

Export-ModuleMember -Function Update-Ideavimrc
Export-ModuleMember -Function Save-Ideavimrc
Export-ModuleMember -Function Compare-Ideavimrc
