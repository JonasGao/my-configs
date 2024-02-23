$MY_CONFIG_HOME = $env:MY_CONFIG_HOME

if (!$MY_CONFIG_HOME)
{
  throw "There is no MY_CONFIG_HOME"
}

Install-Module -Name posh-git -Scope CurrentUser
Write-Host "Success install Modules." -ForegroundColor Green

if (-not (Get-Command scoop))
{
  Write-Host "Not found command scoop. Will install scoop."
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  Invoke-RestMethod get.scoop.sh | Invoke-Expression
  Write-Host "Success install scoop." -ForegroundColor Green
}

scoop install delta
scoop install eza
scoop install oh-my-posh
scoop install aria2
scoop install ripgrep
scoop install fd
Write-Host "Success install delta/eza/oh-my-posh." -ForegroundColor Green

$PROFILE_HOME = (Get-Item $PROFILE).Directory
Copy-Item "$MY_CONFIG_HOME\powershell\omp\Microsoft.PowerShell_profile.ps1" $PROFILE
if (Test-Path "$PROFILE_HOME\Env.ps1")
{
  Write-Host "Skip init Env.ps1, already exists."
} else
{
  Copy-Item "$MY_CONFIG_HOME\powershell\omp\Env.ps1" 
}
Write-Host "Success install Profiles." -ForegroundColor Green
