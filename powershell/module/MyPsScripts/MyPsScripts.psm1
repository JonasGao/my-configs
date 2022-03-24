<#
 .Synopsis
  Just like linux/unix "ssh-copyid xxxxx".
 
 .Parameter Target
  Remote host.

 .Patameter KeyFile
  You will used key file

 .Example
  Copy-Sshid some_one@10.0.0.2

 .Example
  Copy-Sshid some_one@10.0.0.2 .ssh\id_rsa_other.pub
#>
function Copy-Sshid {
    param(
      [parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]
      [string] 
      $Target, 
      [string]
      $KeyFile = ""
    )
    if (!$KeyFile) { $KeyFile = "$env:USERPROFILE\.ssh\id_rsa.pub" }
    if (!$KeyFile.endsWith(".pub")) { $KeyFile = "$KeyFile.pub" }
    if (!(Test-Path -Path $KeyFile -PathType Leaf)) {
      throw "'$KeyFile' file is not exists!"
    }
    Write-Output "Will copy '$KeyFile' to '$Target'"
    Get-Content $keyFile | ssh $Target "mkdir -p .ssh; chmod 700 .ssh; cat >> .ssh/authorized_keys"
  }
  Export-ModuleMember -Function Copy-Sshid
