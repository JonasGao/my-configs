Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
Import-Module MyPsScripts
Import-Module posh-git
Import-Module Terminal-Icons
Import-Module ZLocation

$Env:LESSCHARSET = 'utf-8'

Set-Alias -Name vim -Value gvim



if (Test-Path "C:\Users\Administrator\.jabba\jabba.ps1") { . "C:\Users\Administrator\.jabba\jabba.ps1" }

function Prompt {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal] $identity
  $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

  $prefix = @()

  if (Test-Path variable:/PSDebugContext) { $prefix += 'DBG' }
  if ($principal.IsInRole($adminRole)) { $prefix += 'ADMIN' }
  if ((Test-Path Env:HTTP_PROYX) -or (Test-Path Env:HTTPS_PROXY)) { $prefix += 'PROXY' }

  $PMT_PREFIX = if ($prefix.Count -eq 0) { '' } else { '[' + ($prefix -join '/') + ']: ' }

  $prompt = Write-Prompt ($PMT_PREFIX + "PS ")
  $prompt += & $GitPromptScriptBlock
  if ($NestedPromptLevel -ge 1) { $prompt += Write-Prompt '>>' }

  "$prompt"
}

$NVIM_HOME = "$HOME\Apps\nvim-win64\Neovim"
$env:PATH = "$NVIM_HOME\bin;$env:PATH"
