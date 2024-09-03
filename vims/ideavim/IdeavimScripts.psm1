function prepare()
{
  if (-not(Test-Path Env:\MY_CONFIG_HOME))
  {
    Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
    Exit 1
  }
  $rcSrc = "vims/ideavim/.ideavimrc"
  $rcDst = ".ideavimrc"
  $script:repo = "$env:MY_CONFIG_HOME/$rcSrc"
  $script:user = "$HOME/$rcDst"
}

function Update-Ideavimrc()
{
  if (-not(Test-Path Env:\MY_CONFIG_HOME))
  {
    Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
    Exit 1
  }
  prepare
  delta $script:repo $script:user
  $REPLY = Read-Host -Prompt "Press [y] continue..."
  if ($REPLY -eq "y")
  {
    Copy-Item "$script:repo" "$script:user"
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
  prepare
  delta  $script:user  $script:repo
  $REPLY = Read-Host -Prompt "Press [y] continue..."
  if ($REPLY -eq "y")
  {
    Copy-Item "$script:user" "$script:repo"
    Write-Host -ForegroundColor Green "Finished."
    Push-Location "$env:MY_CONFIG_HOME/vims/ideavim"
    git add .
    git commit -m "Backup ideavimrc"
    git push
    Pop-Location
  }
}

Export-ModuleMember -Function Update-Ideavimrc
Export-ModuleMember -Function Save-Ideavimrc
