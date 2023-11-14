if (-not(Test-Path Variable:\MY_CONFIG_HOME))
{
  Write-Host "There is no MY_CONFIG_HOME" -ForegroundColor Red
  Exit 1
}
$USER_MODULE_HOME = $env:PSModulePath.Split(";")[0]
scoop install delta
New-Item "$USER_MODULE_HOME\IdeavimScripts" -Type Directory -ErrorAction Ignore | Out-Null
Copy-Item "$MY_CONFIG_HOME\vim\ideavim\IdeavimScripts.psm1" "$USER_MODULE_HOME\IdeavimScripts\"
Write-Output "Installed module IdeavimScripts"
