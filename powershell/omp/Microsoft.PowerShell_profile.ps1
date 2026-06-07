$env:PROFILE_HOME = (Get-Item $PROFILE).Directory
$env:ENV_FILENAME = "Env.ps1"
$env:ENV_FILE = "$env:PROFILE_HOME/$env:ENV_FILENAME"
$env:NVIM_CONF = "$env:LOCALAPPDATA\nvim"

Set-PSReadlineKeyHandler -Key Tab -Function Complete
# Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView

Set-Alias -Name vim -Value nvim
Set-Alias -Name lg -Value lazygit
Set-Alias -Name ar -Value aria2c
Set-Alias -Name ls -Value eza
function ll
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

# posh-git 延迟加载：等 PowerShell 空闲后再加载，不阻塞启动
$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Import-Module posh-git -Global
}

# Import-Module Terminal-Icons
Import-Module "$env:MY_CONFIG_HOME\powershell\module\MyPsScripts"

# oh-my-posh init pwsh --config $env:POSH_CONFIG | Invoke-Expression

# Import zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# PSFzf 延迟加载：首次按 Ctrl+T 或 Ctrl+R 时才加载
$Global:PSFzfLazyLoaded = $false
function Global:Invoke-LazyPSFzf {
    if (-not $Global:PSFzfLazyLoaded) {
        Import-Module PSFzf -Global
        Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        $Global:PSFzfLazyLoaded = $true
    }
}
# 劫持快捷键，首次触发时加载 PSFzf 再执行原功能
Set-PSReadLineKeyHandler -Key Ctrl+t -ScriptBlock { Invoke-LazyPSFzf; Invoke-FzfPsReadlineHandlerProvider }
Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock { Invoke-LazyPSFzf; Invoke-FzfPsReadlineHandlerHistory }

# Custom ssh completion
Register-ArgumentCompleter -CommandName ssh -Native -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  Get-Content ${Env:HOMEPATH}\.ssh\config `
  | Select-String -Pattern "^Host "
  | ForEach-Object { $_ -replace "host ", "" }
  | Where-Object { $_ -like "${wordToComplete}*" } `
  | Sort-Object -Unique
}

# Source local custom function
. "$HOME\.func.ps1"
