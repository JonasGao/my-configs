if (-not(Test-Path env:\MY_CONFIG_HOME))
{
  Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
  Exit 1
}
scoop install delta
Write-Output "Installed dependency: delta"
$USER_MODULE_HOME = $env:PSModulePath.Split(";")[0]
Write-Output "Will install IdeavimScripts to `"$USER_MODULE_HOME`""
New-Item "$USER_MODULE_HOME\IdeavimScripts" -Type Directory -ErrorAction Ignore | Out-Null
Copy-Item "$env:MY_CONFIG_HOME\vims\ideavim\IdeavimScripts.psm1" "$USER_MODULE_HOME\IdeavimScripts\"
Write-Output "Installed module IdeavimScripts. Please restart PWSH and run `"Update-Ideavimrc`""
