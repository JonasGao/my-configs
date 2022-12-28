Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

Import-Module MyPsScripts
Import-Module Terminal-Icons
Import-Module ZLocation

oh-my-posh init pwsh --config "$HOME\.mytheme.omp.json" | Invoke-Expression

Set-Alias -Name vim -Value gvim

$Env:LESSCHARSET = 'utf-8'
if (Test-Path "$HOME/Set-Env.ps1") { . "$HOME/Set-Env.ps1" }
