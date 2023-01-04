Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

Import-Module Terminal-Icons
Import-Module ZLocation
Import-Module posh-git

Set-Alias -Name vim -Value gvim
Set-Alias -Name ll -Value Get-ChildItem

$env:LESSCHARSET = 'utf-8'
$env:POSH_GIT_ENABLED = $true

if (Test-Path "$HOME/Set-Env.ps1") { . "$HOME/Set-Env.ps1" }

oh-my-posh init pwsh --config $PoshConfig | Invoke-Expression
