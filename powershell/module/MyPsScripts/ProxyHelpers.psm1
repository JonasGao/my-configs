<#
 .Synopsis
  Setup http proxy env
#>
function Set-HttpProxy ([string]$Url, [switch]$Reset)
{

  if ($Reset)
  {
    if (Test-Path Env:HTTP_PROXY)
    { 
      Remove-Item -Path Env:HTTP_PROXY 
    }
    if (Test-Path Env:HTTPS_PROXY)
    { 
      Remove-Item -Path Env:HTTPS_PROXY 
    }
    Write-Output "已清除代理配置"
    return
  }

  if (!$Url)
  {
    $CONF_FILE = "$HOME\.config\my-powershell\default-proxy"
    if (Test-Path -Path $CONF_FILE)
    {
      $Url = Get-Content $CONF_FILE
    }
  }

  if (!$Url)
  {
    Write-Output "没有指定 Url 参数，或者提供一个有效的 default-proxy 配置文件"
    return
  }

  Write-Output "使用代理：$Url"
  $Env:HTTP_PROXY = $Url
  $Env:HTTPS_PROXY = $Url

}

function Set-Proxy
{
  param (
    $Proxy
  )
  [net.webrequest]::DefaultWebProxy = New-Object net.webproxy $Proxy
}

function Get-Proxy
{
  [net.webrequest]::DefaultWebProxy
}

Export-ModuleMember -Function Set-HttpProxy
Export-ModuleMember -Function Set-Proxy
Export-ModuleMember -Function Get-Proxy
