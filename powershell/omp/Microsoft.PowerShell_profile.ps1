$env:PROFILE_HOME = (Get-Item $PROFILE).Directory
$env:ENV_FILENAME = "Env.ps1"
$env:ENV_FILE = "$env:PROFILE_HOME/$env:ENV_FILENAME"
$env:NVIM_CONF = "$env:LOCALAPPDATA\nvim"
$env:NVIM_HOME = "$env:NVIM_HOME"

Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

Set-Alias -Name vim -Value nvim
Set-Alias -Name lg -Value lazygit
Set-Alias -Name ar -Value aria2c
function ll
{
  eza -l $args
}
function ls
{
  eza -l $args
}

$env:LESSCHARSET = 'utf-8'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$env:POSH_GIT_ENABLED = $true

# Source custom env file
. "$env:ENV_FILE"

$env:PATH = "$HOME\bin;$HOME\.local\bin;$env:PATH"
$env:PATH = "$env:MAVEN_HOME\bin;$env:PATH"
$env:PATH = "$env:NVIM_HOME\bin;$env:PATH"

Import-Module posh-git
Import-Module PSFzf
Import-Module Terminal-Icons
Import-Module "$env:MY_CONFIG_HOME\powershell\module\MyPsScripts"

# Source local custom function
. "$HOME\function.ps1"

oh-my-posh init pwsh --config $env:POSH_CONFIG | Invoke-Expression

# Import zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Setup PSFzf
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

# Custom ssh completion
Register-ArgumentCompleter -CommandName ssh -Native -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  Get-Content ${Env:HOMEPATH}\.ssh\config `
  | Select-String -Pattern "^Host "
  | ForEach-Object { $_ -replace "host ", "" }
  | Where-Object { $_ -like "${wordToComplete}*" } `
  | Sort-Object -Unique
}
