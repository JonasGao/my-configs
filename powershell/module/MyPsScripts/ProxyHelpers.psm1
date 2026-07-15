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

  return $null
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

function Set-DotNetProxy {
  param (
    $Proxy
  )
  [net.webrequest]::DefaultWebProxy = New-Object net.webproxy $Proxy
}

function Get-DotNetProxy {
  $proxy = [net.webrequest]::DefaultWebProxy
  if ($proxy -and $proxy.Address) {
    return $proxy.Address.ToString()
  }
  return $null
}

function Get-EnvProxy {
  $snapshot = Get-ProxyEnvSnapshot
  $hasAny = $false
  foreach ($name in $script:ProxyEnvNames) {
    if ($null -ne $snapshot[$name]) {
      $hasAny = $true
      break
    }
  }

  if (-not $hasAny) {
    return $null
  }

  # Prefer uppercase canonical names (Windows Env: is case-insensitive).
  $obj = [PSCustomObject]@{
    HTTP_PROXY  = $(if ($null -ne $snapshot['HTTP_PROXY']) { $snapshot['HTTP_PROXY'] } else { $snapshot['http_proxy'] })
    HTTPS_PROXY = $(if ($null -ne $snapshot['HTTPS_PROXY']) { $snapshot['HTTPS_PROXY'] } else { $snapshot['https_proxy'] })
    ALL_PROXY   = $(if ($null -ne $snapshot['ALL_PROXY']) { $snapshot['ALL_PROXY'] } else { $snapshot['all_proxy'] })
    NO_PROXY    = $(if ($null -ne $snapshot['NO_PROXY']) { $snapshot['NO_PROXY'] } else { $snapshot['no_proxy'] })
  }
  return $obj
}

<#
 .Synopsis
  Run command or scriptblock with http proxy env temporarily set
#>
function Invoke-WithProxy {
  [CmdletBinding(DefaultParameterSetName = 'Command')]
  param (
    [string]$Url,
    [string]$NoProxy,

    [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ScriptBlock')]
    [scriptblock]$ScriptBlock,

    # Avoid naming this -Command: it steals pwsh/cmd -Command from remaining args.
    [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Command')]
    [string]$FilePath,

    [Parameter(ValueFromRemainingArguments = $true, ParameterSetName = 'Command')]
    $ArgumentList,

    [Parameter(ValueFromRemainingArguments = $true, ParameterSetName = 'ScriptBlock')]
    $ScriptArguments
  )

  $resolved = Resolve-ProxyUrl -Url $Url
  if (!$resolved) {
    Write-Error "没有指定 Url 参数，或者提供一个有效的 default-proxy 配置文件"
    return
  }

  $snapshot = Get-ProxyEnvSnapshot

  try {
    if ($PSBoundParameters.ContainsKey('NoProxy')) {
      Set-ProxyEnvVars -Url $resolved -NoProxy $NoProxy
    }
    else {
      Set-ProxyEnvVars -Url $resolved
    }

    if ($PSCmdlet.ParameterSetName -eq 'ScriptBlock') {
      if ($null -ne $ScriptArguments -and @($ScriptArguments).Count -gt 0) {
        & $ScriptBlock @ScriptArguments
      }
      else {
        & $ScriptBlock
      }
    }
    else {
      & $FilePath @ArgumentList
    }
  }
  finally {
    Restore-ProxyEnvSnapshot -Snapshot $snapshot
  }
}

Export-ModuleMember -Function Set-EnvProxy
Export-ModuleMember -Function Get-EnvProxy
Export-ModuleMember -Function Set-DotNetProxy
Export-ModuleMember -Function Get-DotNetProxy
Export-ModuleMember -Function Invoke-WithProxy
