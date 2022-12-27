$BgDarkBlue = "`e[48;2;0;0;139m"
$BgDarkBlueOff = "`e[49m"
$FgDarkBlue = "`e[38;2;0;0;139m"
$BgBlue = "`e[48;2;0;0;255m"
$BgBlueOff = "`e[49m"
$FgBlue = "`e[38;2;0;0;255m"
$BgYel = "`e[48;2;153;124;0m"
$BgYelOff = "`e[49m"
$FgYel = "`e[38;2;153;124;0m"
$BgGray = "`e[48;2;118;118;118m"
$BgGrayOff = "`e[49m"
$FgGray = "`e[38;2;118;118;118m"
$FgOff = "`e[39m"


Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

Import-Module posh-git
Import-Module MyPsScripts
Import-Module Terminal-Icons
Import-Module ZLocation

function Get-JavaVersion {
  (Get-Command java).Version.Major.ToString()
}

function Get-JavaSegment {
  "${BgYel}  $(Get-JavaVersion) ${BgYelOff}${BgDarkBlue}${FgYel}${FgOff} "
}

function Get-PromptPrefix {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal] $identity
  $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

  $prefix = @()

  if (Test-Path variable:/PSDebugContext) { $prefix += 'DBG' }
  if ($principal.IsInRole($adminRole)) { $prefix += 'ADMIN' }
  if ((Test-Path Env:HTTP_PROYX) -or (Test-Path Env:HTTPS_PROXY)) { $prefix += 'PROXY' }

  $PMT_PREFIX = if ($prefix.Count -eq 0) { '' } else { '[' + ($prefix -join '/') + ']: ' }

  "${FgDarkBlue}${BgYel}${BgYelOff}${FgOff}$(Get-JavaSegment)"
}

function Setup-GitPrompt {
  $GitPromptSettings.DefaultPromptPrefix.Text = '$(Get-PromptPrefix)'
  $GitPromptSettings.DefaultPromptPath.BackgroundColor = 'DarkBlue'
  $GitPromptSettings.AfterPath.Text = "$BgDarkBlue ${BgDarkBlueOff}${FgDarkBlue}${FgOff}"
  $GitPromptSettings.PathStatusSeparator.Text = ""
  $GitPromptSettings.DefaultPromptSuffix = " "
}

Setup-GitPrompt

$Env:LESSCHARSET = 'utf-8'

Set-Alias -Name vim -Value gvim

if (Test-Path "$HOME/Set-Env.ps1") { . "$HOME/Set-Env.ps1" }

if (Test-Path "C:\Users\Administrator\.jabba\jabba.ps1") { . "C:\Users\Administrator\.jabba\jabba.ps1" }
$NVIM_HOME = "$HOME\Apps\nvim-win64\Neovim"
$env:PATH = "$NVIM_HOME\bin;$env:PATH"
