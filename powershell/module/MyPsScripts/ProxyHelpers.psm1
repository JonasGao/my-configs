<#
 .Synopsis
  Setup http proxy env
#>
function Set-EnvProxy ([string]$Url, [switch]$Reset)
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

function Set-DotNetProxy
{
  param (
    $Proxy
  )
  [net.webrequest]::DefaultWebProxy = New-Object net.webproxy $Proxy
}

function Get-DotNetProxy
{
  $proxy = [net.webrequest]::DefaultWebProxy
  if ($proxy -and $proxy.Address)
  {
    return $proxy.Address.ToString()
  }
  return $null
}

function Get-EnvProxy
{
  $httpProxy = if (Test-Path Env:HTTP_PROXY) { $Env:HTTP_PROXY } else { $null }
  $httpsProxy = if (Test-Path Env:HTTPS_PROXY) { $Env:HTTPS_PROXY } else { $null }
  
  if ($httpProxy -or $httpsProxy)
  {
    return [PSCustomObject]@{
      HTTP_PROXY = $httpProxy
      HTTPS_PROXY = $httpsProxy
    }
  }
  return $null
}

<#
 .Synopsis
  Run command with http proxy env temporarily set
#>
function Invoke-WithProxy {
  param (
    [string]$Url,
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)]
    $Arguments
  )

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
    Write-Error "没有指定 Url 参数，或者提供一个有效的 default-proxy 配置文件"
    return
  }

  $oldHttpProxy = if (Test-Path Env:HTTP_PROXY) { $Env:HTTP_PROXY } else { $null }
  $oldHttpsProxy = if (Test-Path Env:HTTPS_PROXY) { $Env:HTTPS_PROXY } else { $null }

  try
  {
    $Env:HTTP_PROXY = $Url
    $Env:HTTPS_PROXY = $Url
    & $Command @Arguments
  }
  finally
  {
    if ($null -eq $oldHttpProxy)
    {
      Remove-Item -Path Env:HTTP_PROXY -ErrorAction SilentlyContinue
    }
    else
    {
      $Env:HTTP_PROXY = $oldHttpProxy
    }

    if ($null -eq $oldHttpsProxy)
    {
      Remove-Item -Path Env:HTTPS_PROXY -ErrorAction SilentlyContinue
    }
    else
    {
      $Env:HTTPS_PROXY = $oldHttpsProxy
    }
  }
}

Export-ModuleMember -Function Set-EnvProxy
Export-ModuleMember -Function Get-EnvProxy
Export-ModuleMember -Function Set-DotNetProxy
Export-ModuleMember -Function Get-DotNetProxy
Export-ModuleMember -Function Invoke-WithProxy
