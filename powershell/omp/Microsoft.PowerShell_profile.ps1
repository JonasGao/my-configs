$PROFILE_HOME = (Get-Item $PROFILE).Directory
$ENV_FILENAME = "Env.ps1"
$ENV_FILE = "$PROFILE_HOME/$ENV_FILENAME"
$NVIM_CONF = "$env:LOCALAPPDATA\nvim"
$NVIM_HOME = "$env:NVIM_HOME"

function Update-Env
{
  if (Test-Path "$ENV_FILE")
  {
    . "$ENV_FILE"
  }
}

Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

Set-Alias -Name vim -Value nvim
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name ls -Value Get-ChildItem

$env:LESSCHARSET = 'utf-8'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$env:POSH_GIT_ENABLED = $true

Update-Env

$env:PATH = "$HOME\bin;$HOME\.local\bin;" + $env:PATH
$env:PATH = "$MAVEN_HOME;" + $env:PATH
$env:PATH = "$NVIM_HOME\bin;$env:PATH"

Import-Module posh-git
Import-Module Terminal-Icons
Import-Module z
Import-Module "$MY_CONFIG_HOME\powershell\module\MyPsScripts"

oh-my-posh init pwsh --config $PoshConfig | Invoke-Expression
