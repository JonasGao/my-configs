<#
 .Synopsis
  Just like linux/unix "ssh-copyid xxxxx".
 
 .Parameter Host
  Remote host.

 .Patameter IdentityFile
  You will used key file

 .Example
  Copy-Sshid some_one@10.0.0.2

 .Example
  Copy-Sshid some_one@10.0.0.2 .ssh\id_rsa_other.pub
#>
function Copy-Sshid
{
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] 
    $Host, 
    [string]
    $IdentityFile = ""
  )
 
  function searchIdentity
  {
    $sshHome = "$env:USERPROFILE\.ssh" 
    if (!(Test-Path $sshHome))
    {
      throw "'$sshHome' not exists."
    }
    if (!(Test-Path $sshHome -PathType Container))
    {
      throw "'$sshHome' is not a directory."
    }
    Write-Host "Search $sshHome"
    Get-ChildItem $sshHome | ForEach-Object {
      if ($_.Name.StartsWith("id_") -and $_.Name.EndsWith(".pub"))
      {
        return $_
      }
    }
  }

  if (!$IdentityFile)
  {
    $IdentityFile = searchIdentity
  } elseif (!$IdentityFile.endsWith(".pub"))
  {
    $IdentityFile = "$IdentityFile.pub"
  }
  if (!(Test-Path -Path $IdentityFile -PathType Leaf))
  {
    throw "'$IdentityFile' file is not exists!"
  }
  Write-Host -ForegroundColor Green "Will copy '$IdentityFile' to '$Host'"
  $cmds = @(
    "[ -d .ssh ] || mkdir -p .ssh && chmod 700 .ssh"
    "[ -f .ssh/authorized_keys ] || touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys"
    "cat >> .ssh/authorized_keys"
  )
  Get-Content $IdentityFile | ssh $Host ($cmds -join "; ")
}

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
  $out = "$HOME\Downloads\pwsh.msi"
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
    $p = $env:GHPROXY
  } else
  {
    # $p = "https://mirror.ghproxy.com/"
    $p = "https://ghps.cc/"
  }
  Write-Output "Using proxy `"$p`""
  Invoke-RestMethod "$p$u" -OutFile $out
  if (Test-Path $out)
  {
    Write-Output "Installing msi"
    msiexec /i $out /qb
    Write-Output "Finished install"
  }
}

$MY_SCRIPT_SOURCE_HOME = "$env:MY_CONFIG_HOME\powershell\module\MyPsScripts"

Export-ModuleMember -Function Copy-Sshid
Export-ModuleMember -Function Get-StrHash
Export-ModuleMember -Function Update-Pwsh
Export-ModuleMember -Variable MY_SCRIPT_SOURCE_HOME
