Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

Import-Module posh-git
Import-Module MyPsScripts
Import-Module Terminal-Icons
Import-Module ZLocation

function Get-PromptPrefix {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal] $identity
  $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

  $prefix = @()

  if (Test-Path variable:/PSDebugContext) { $prefix += 'DBG' }
  if ($principal.IsInRole($adminRole)) { $prefix += 'ADMIN' }
  if ((Test-Path Env:HTTP_PROYX) -or (Test-Path Env:HTTPS_PROXY)) { $prefix += 'PROXY' }

  $PMT_PREFIX = if ($prefix.Count -eq 0) { '' } else { '[' + ($prefix -join '/') + ']: ' }

  "${PMT_PREFIX} PS "
}

$GitPromptSettings.DefaultPromptPrefix.Text = $(Get-PromptPrefix)
$GitPromptSettings.DefaultPromptPrefix.BackgroundColor = 'Blue'
$GitPromptSettings.BeforePath.Text = " "
$GitPromptSettings.BeforePath.ForegroundColor = 'Blue'
$GitPromptSettings.BeforePath.BackgroundColor = 'DarkBlue'
$GitPromptSettings.DefaultPromptPath.BackgroundColor = 'DarkBlue'
$GitPromptSettings.AfterPath.Text = "`e[48;2;0;0;139m `e[49m`e[38;2;0;0;139m`e[39m"
$GitPromptSettings.PathStatusSeparator.Text = ""
$GitPromptSettings.DefaultPromptSuffix = " "

$Env:LESSCHARSET = 'utf-8'

Set-Alias -Name vim -Value gvim

if (Test-Path "$HOME/Set-Env.ps1") { . "$HOME/Set-Env.ps1" }

if (Test-Path "C:\Users\Administrator\.jabba\jabba.ps1") { . "C:\Users\Administrator\.jabba\jabba.ps1" }
$NVIM_HOME = "$HOME\Apps\nvim-win64\Neovim"
$env:PATH = "$NVIM_HOME\bin;$env:PATH"
