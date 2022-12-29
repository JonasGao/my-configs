Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

Import-Module MyPsScripts
Import-Module Terminal-Icons
Import-Module ZLocation

Set-Alias -Name vim -Value gvim
Set-Alias -Name ll -Value Get-ChildItem

$Env:LESSCHARSET = 'utf-8'

if (Test-Path "$HOME/Set-Env.ps1") { . "$HOME/Set-Env.ps1" }

oh-my-posh init pwsh --config $PoshConfig | Invoke-Expression
