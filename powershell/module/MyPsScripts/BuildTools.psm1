<#
 .Synopsis
  Setup SBT_HOMe
 
 .Parameter Path
  Path to sbt home.
#>
function Set-SbtHome
{

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
function Set-MvnHome
{

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

Export-ModuleMember -Function Set-SbtHome
Export-ModuleMember -Function Set-MvnHome
