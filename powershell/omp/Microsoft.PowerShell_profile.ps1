$env:PROFILE_HOME = (Get-Item $PROFILE).Directory
$env:ENV_FILENAME = "Env.ps1"
$env:ENV_FILE = "$env:PROFILE_HOME/$env:ENV_FILENAME"
$env:NVIM_CONF = "$env:LOCALAPPDATA\nvim"
$env:NVIM_HOME = "$env:NVIM_HOME"

Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

Set-Alias -Name vim -Value nvim
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name ls -Value Get-ChildItem

$env:LESSCHARSET = 'utf-8'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$env:POSH_GIT_ENABLED = $true

. "$env:ENV_FILE"

$env:PATH = "$HOME\bin;$HOME\.local\bin;" + $env:PATH
$env:PATH = "$env:MAVEN_HOME;" + $env:PATH
$env:PATH = "$env:NVIM_HOME\bin;$env:PATH"

Import-Module posh-git
Import-Module Terminal-Icons
Import-Module "$env:MY_CONFIG_HOME\powershell\module\MyPsScripts"

oh-my-posh init pwsh --config $env:POSH_CONFIG | Invoke-Expression
