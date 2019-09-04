New-Alias p pnpm
New-Alias y yarn
New-Alias ll ls

Set-PSReadlineKeyHandler -Key Tab -Function Complete

Import-Module posh-git
Import-Module oh-my-posh
Import-Module posh-gvm
Set-Theme Agnoster
