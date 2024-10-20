$MY_CONFIG_HOME = $env:MY_CONFIG_HOME

if (!$MY_CONFIG_HOME) {
    $scriptPath = Split-Path -Path $PSScriptRoot -Parent
    $MY_CONFIG_HOME = Split-Path -Path $scriptPath -Parent
    Write-Host "MY_CONFIG_HOME 设置为：$MY_CONFIG_HOME"
}

Install-Module -Name posh-git -Scope CurrentUser
Install-Module -Name PSFzf -Scope CurrentUser -RequiredVersion 2.5.22
Write-Host "Success install Modules." -ForegroundColor Green


if (-not (Get-Command scoop -ErrorAction SilentlyContinue))
{
  Write-Host "Not found command scoop. Will install scoop."
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  Invoke-RestMethod get.scoop.sh -Proxy $PROXY | Invoke-Expression
  scoop config aria2-warning-enabled false
  Write-Host "Success install scoop." -ForegroundColor Green
}

if ($PROXY)
{
    scoop config proxy $PROXY
    scoop config https_proxy $PROXY
}
try
{
    scoop install delta eza oh-my-posh aria2 ripgrep fzf fd zoxide
} finally 
{
    if ($PROXY)
    {
        scoop config rm proxy
        scoop config rm https_proxy
    }
}
Write-Host "Success install components from scroop." -ForegroundColor Green

$PROFILE_HOME = Split-Path -Path $PROFILE -Parent
New-Item -ItemType Directory -Path $PROFILE_HOME -Force
Copy-Item "$MY_CONFIG_HOME\powershell\omp\Microsoft.PowerShell_profile.ps1" $PROFILE
if (Test-Path "$PROFILE_HOME\Env.ps1")
{
  Write-Host "Skip init Env.ps1, already exists."
} else
{
  Copy-Item "$MY_CONFIG_HOME\powershell\omp\Env.ps1" 
}
Write-Host "Success install Profiles." -ForegroundColor Green
