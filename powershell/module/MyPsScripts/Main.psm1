<#
 .Synopsis
  Help you get hash from string.

 .Parameter Value
  The string, you will get hash

 .PARAMETER Algorithm
  Which hash algorithm you will used
#>
function Get-StrHash()
{
  param (
    [parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Value,
    [parameter()]
    [ValidateNotNullOrEmpty()]
    $Algorithm
  )
  $stream = [System.IO.MemoryStream]::new()
  $writer = [System.IO.StreamWriter]::new($stream)
  $writer.Write($Value)
  $writer.Flush()
  $stream.Position = 0
  if ($Algorithm)
  {
      (Get-FileHash -InputStream $stream -Algorithm $Algorithm).Hash
  } else
  {
      (Get-FileHash -InputStream $stream).Hash
  }
}

function Update-Pwsh
{
  $out_dir = "$HOME\Downloads"
  $out_file = "pwsh.msi"
  $out = "$out_dir\$out_file"
  if (Test-Path $out)
  {
    Write-Output "Found `"$out`" exists"
    Remove-Item $out
    Write-Output "Removed `"$out`""
  }
  Write-Output "Will download to `"$out`""
  $h = @{ "Accept" = "application/vnd.github+json" }
  Write-Output "Calling GitHub API to get latest release."
  $r = Invoke-RestMethod "https://api.github.com/repos/powershell/powershell/releases/latest" -Headers $h
  $u = ($r.assets | Where-Object { $_.browser_download_url.endsWith("x64.msi") }).browser_download_url
  Write-Output "Got and download latest release `"$u`""
  if (Test-Path env:\GHPROXY)
  {
    $ghproxy = $env:GHPROXY
    Write-Output "Using ghproxy `"$ghproxy`""
  }
  if (Get-Command "aria2c")
  {
    Write-Output "Using aria2c downloading."
    if (Test-Path env:\ARIA2_PROXY)
    {
      Write-Output "Using proxy for aria2c: $env:ARIA2_PROXY"
    }
    aria2c -o $out_file -d $out_dir --all-proxy $env:ARIA2_PROXY "$ghproxy$u"
  } else
  {
    Invoke-RestMethod "$ghproxy$u" -OutFile $out
  }
  if (Test-Path $out)
  {
    Write-Output "Installing msi"
    msiexec /i $out /qb
    Write-Output "Finished install"
  } else
  {
    Write-Output "Not found msi file. Skip install."
  }
}

$MY_SCRIPT_SOURCE_HOME = "$env:MY_CONFIG_HOME\powershell\module\MyPsScripts"

Export-ModuleMember -Function Get-StrHash
Export-ModuleMember -Function Update-Pwsh
Export-ModuleMember -Variable MY_SCRIPT_SOURCE_HOME
