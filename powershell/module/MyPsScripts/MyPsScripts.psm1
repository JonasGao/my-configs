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

<#
 .Synopsis
  Set current env 'JAVA_HOME' and setup PATH.
 
 .Parameter Path
  Path to java home.

 .Example
  Set-JavaHome C:\xxx\java\jdk-1.8
#>
function Set-JavaHome {

  param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Path
  )
  
  Write-Output "Set JAVA_HOME = '$Path'"
  $JAVA_HOME = $Path
  $env:JAVA_HOME = $Path
  $env:PATH = "$JAVA_HOME\bin;$env:PATH"
}

<#
 .Synopsis
  Setup SBT_HOMe
 
 .Parameter Path
  Path to sbt home.
#>
function Set-SbtHome {

  param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Path
  )
  
  Write-Output "Set SBT_HOME = '$Path'"
  $SBT_HOME = $Path
  $env:SBT_HOME = $Path
  $env:PATH = "$SBT_HOME\bin;$env:PATH"
}

<#
 .Synopsis
  Setup MAVEN_HOME
 
 .Parameter Path
  Path to maven home.
#>
function Set-MvnHome {

  param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Path
  )
  
  Write-Output "Set MAVEN_HOME = '$Path'"
  $MAVEN_HOME = $Path
  $env:MAVEN_HOME = $Path
  $env:PATH = "$MAVEN_HOME\bin;$env:PATH"
}

<#
 .Synopsis
  Setup http proxy env
#>
function Set-HttpProxy ([string]$Url, [switch]$Reset) {

  if ($Reset) {
    if (Test-Path Env:HTTP_PROXY) { Remove-Item -Path Env:HTTP_PROXY }
    if (Test-Path Env:HTTPS_PROXY) { Remove-Item -Path Env:HTTPS_PROXY }
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

Export-ModuleMember -Function Copy-Sshid
Export-ModuleMember -Function Set-JavaHome
Export-ModuleMember -Function Set-SbtHome
Export-ModuleMember -Function Set-HttpProxy
Export-ModuleMember -Function Set-MvnHome
