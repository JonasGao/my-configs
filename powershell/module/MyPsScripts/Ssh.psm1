function New-SshProxy
{
  param($Name, $Port, $SshTarget)
  $FullName = "Start-${Name}Proxy"
  Set-Item -Path function:global:$FullName -Value {
    Write-Output "Startuping ssh @$Port"
    ssh -CND 127.0.0.1:$Port $SshTarget
    Write-Output "Finish"
  }.GetNewClosure()
}

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

Export-ModuleMember -Function New-SshProxy
Export-ModuleMember -Function Copy-Sshid
