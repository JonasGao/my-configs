$script:ProxyEnvNames = @(
  'HTTP_PROXY', 'http_proxy',
  'HTTPS_PROXY', 'https_proxy',
  'ALL_PROXY', 'all_proxy',
  'NO_PROXY', 'no_proxy'
)

function New-ProxyEnvSnapshotTable {
  # Case-sensitive: Linux treats HTTP_PROXY and http_proxy as distinct.
  return New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
}

function Resolve-ProxyUrl {
  param ([string]$Url)

  if ($Url) {
    return $Url.Trim()
  }

  $confFile = "$HOME\.config\my-powershell\default-proxy"
  if (Test-Path -Path $confFile) {
    $fromFile = (Get-Content $confFile -Raw).Trim()
    if ($fromFile) {
      return $fromFile
    }
  }

  foreach ($name in @('HTTP_PROXY', 'http_proxy', 'HTTPS_PROXY', 'https_proxy', 'ALL_PROXY', 'all_proxy')) {
    $path = "Env:$name"
    if (Test-Path -LiteralPath $path) {
      $value = (Get-Item -LiteralPath $path).Value
      if ($value) {
        return $value.Trim()
      }
    }
  }

  # Same default as bash `.proxy_funcs` / git config in this repo.
  return 'http://proxy0.lan:7890'
}

function Get-ProxyEnvSnapshot {
  $snapshot = New-ProxyEnvSnapshotTable
  foreach ($name in $script:ProxyEnvNames) {
    $path = "Env:$name"
    if (Test-Path $path) {
      $snapshot[$name] = (Get-Item -LiteralPath $path).Value
    }
    else {
      $snapshot[$name] = $null
    }
  }
  return $snapshot
}

function Set-ProxyEnvVars {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Url,
    [string]$NoProxy
  )

  Set-Item -LiteralPath Env:HTTP_PROXY -Value $Url
  Set-Item -LiteralPath Env:http_proxy -Value $Url
  Set-Item -LiteralPath Env:HTTPS_PROXY -Value $Url
  Set-Item -LiteralPath Env:https_proxy -Value $Url
  Set-Item -LiteralPath Env:ALL_PROXY -Value $Url
  Set-Item -LiteralPath Env:all_proxy -Value $Url

  if ($PSBoundParameters.ContainsKey('NoProxy')) {
    if ([string]::IsNullOrEmpty($NoProxy)) {
      Remove-Item -LiteralPath Env:NO_PROXY, Env:no_proxy -ErrorAction SilentlyContinue
    }
    else {
      Set-Item -LiteralPath Env:NO_PROXY -Value $NoProxy
      Set-Item -LiteralPath Env:no_proxy -Value $NoProxy
    }
  }
}

function Clear-ProxyEnvVars {
  foreach ($name in $script:ProxyEnvNames) {
    Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
  }
}

function Restore-ProxyEnvSnapshot {
  param (
    [Parameter(Mandatory = $true)]
    [hashtable]$Snapshot
  )

  foreach ($name in $script:ProxyEnvNames) {
    $path = "Env:$name"
    $value = $Snapshot[$name]
    if ($null -eq $value) {
      Remove-Item -LiteralPath $path -ErrorAction SilentlyContinue
    }
    else {
      Set-Item -LiteralPath $path -Value $value
    }
  }
}

<#
 .Synopsis
  Setup http proxy env
#>
function Set-EnvProxy {
  param (
    [string]$Url,
    [string]$NoProxy,
    [switch]$Reset
  )

  if ($Reset) {
    Clear-ProxyEnvVars
    Write-Output "已清除代理配置"
    return
  }

  $resolved = Resolve-ProxyUrl -Url $Url
  if (!$resolved) {
    Write-Output "没有指定 Url 参数，或者提供一个有效的 default-proxy 配置文件"
    return
  }

  Write-Output "使用代理：$resolved"
  if ($PSBoundParameters.ContainsKey('NoProxy')) {
    Set-ProxyEnvVars -Url $resolved -NoProxy $NoProxy
  }
  else {
    Set-ProxyEnvVars -Url $resolved
  }
}

<#
 .Synopsis
  Set .NET default proxy for both WebRequest (WebClient, Windows PowerShell)
  and HttpClient (PowerShell 7+ Invoke-RestMethod/Invoke-WebRequest).
  Pass empty string to clear/reset.
#>
function Set-DotNetProxy {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [AllowEmptyString()]
    [string]$Url
  )

  if ([string]::IsNullOrWhiteSpace($Url)) {
    [System.Net.WebRequest]::DefaultWebProxy = $null
    try {
      [System.Net.Http.HttpClient]::DefaultProxy = $null
    }
    catch { }
    return
  }

  $trimmed = $Url.Trim()
  [System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy $trimmed
  try {
    [System.Net.Http.HttpClient]::DefaultProxy = New-Object System.Net.WebProxy $trimmed
  }
  catch { }
}

<#
 .Synopsis
  Get .NET default proxy addresses from both WebRequest and HttpClient.
  Returns a PSCustomObject with WebRequestProxy and HttpClientProxy properties.
#>
function Get-DotNetProxy {
  [CmdletBinding()]
  param ()

  $webRequestProxy = $null
  $proxy = [System.Net.WebRequest]::DefaultWebProxy
  if ($proxy -and $proxy.Address) {
    $webRequestProxy = $proxy.Address.ToString()
  }

  $httpClientProxy = $null
  try {
    $proxy = [System.Net.Http.HttpClient]::DefaultProxy
    if ($proxy -and $proxy.Address) {
      $httpClientProxy = $proxy.Address.ToString()
    }
  }
  catch { }

  return [PSCustomObject]@{
    WebRequestProxy  = $webRequestProxy
    HttpClientProxy  = $httpClientProxy
  }
}

function Get-EnvProxy {
  $snapshot = Get-ProxyEnvSnapshot

  $httpProxy = if ($null -ne $snapshot['HTTP_PROXY']) { $snapshot['HTTP_PROXY'] } else { $snapshot['http_proxy'] }
  $httpsProxy = if ($null -ne $snapshot['HTTPS_PROXY']) { $snapshot['HTTPS_PROXY'] } else { $snapshot['https_proxy'] }
  $allProxy = if ($null -ne $snapshot['ALL_PROXY']) { $snapshot['ALL_PROXY'] } else { $snapshot['all_proxy'] }
  $noProxy = if ($null -ne $snapshot['NO_PROXY']) { $snapshot['NO_PROXY'] } else { $snapshot['no_proxy'] }

  if (-not ($httpProxy -or $httpsProxy -or $allProxy)) {
    return $null
  }

  return [PSCustomObject]@{
    HTTP_PROXY  = $httpProxy
    HTTPS_PROXY = $httpsProxy
    ALL_PROXY   = $allProxy
    NO_PROXY    = $noProxy
  }
}

Export-ModuleMember -Function Set-EnvProxy
Export-ModuleMember -Function Get-EnvProxy
Export-ModuleMember -Function Set-DotNetProxy
Export-ModuleMember -Function Get-DotNetProxy
