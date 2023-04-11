$PROFILE_HOME = (Get-Item $PROFILE).Directory
$SET_ENV_NAME = "env.ps1"
$SET_ENV = "$PROFILE_HOME/$SET_ENV_NAME"

Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

Import-Module posh-git
Import-Module Terminal-Icons
Import-Module z

Set-Alias -Name vim -Value nvim
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name ls -Value Get-ChildItem

$env:LESSCHARSET = 'utf-8'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$env:POSH_GIT_ENABLED = $true

if (Test-Path "$SET_ENV")
{
  . "$SET_ENV"
}

oh-my-posh init pwsh --config $PoshConfig | Invoke-Expression
