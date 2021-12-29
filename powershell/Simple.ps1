Set-PSReadlineKeyHandler -Key Tab -Function Complete
Import-Module posh-git

Import-Module ZLocation

if (Test-Path "C:\Users\Administrator\.jabba\jabba.ps1") { . "C:\Users\Administrator\.jabba\jabba.ps1" }

function Set-JavaHome ([string]$Path){

  $ABS_PATH = Resolve-Path $Path
  Write-Output "Set JAVA_HOME = '$ABS_PATH'"
  $JAVA_HOME = $ABS_PATH
  $Env:JAVA_HOME = $JAVA_HOME
  $Env:PATH = "$JAVA_HOME\bin;$env:PATH"

}

function Set-HttpProxy ([string]$Url, [switch]$Reset) {

  if ($Reset) {
    Remove-Item -Path Env:HTTP_PROXY
    Remove-Item -Path Env:HTTPS_PROXY
    Write-Output "已清除代理配置"
    return
  }

  if (!$Url) {
    $CONF_FILE = "$HOME\.config\my-powershell\default-proxy"
    if (Test-Path -Path $CONF_FILE) {
      $Url = Get-Content $CONF_FILE
    }
  }

  if (!$Url) {
    Write-Output "没有指定 Url 参数，或者提供一个有效的 default-proxy 配置文件"
    return
  }

  Write-Output "使用代理：$Url"
  $Env:HTTP_PROXY = $Url
  $Env:HTTPS_PROXY = $Url

}

$NVIM_HOME = "$HOME\Apps\nvim-win64\Neovim"
$env:PATH = "$NVIM_HOME\bin;$env:PATH"
