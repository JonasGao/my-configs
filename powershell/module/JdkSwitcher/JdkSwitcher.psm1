$JAVA_HOME_LIST_FILE = "$HOME\.jdks\list"

function Read-Jdks()
{
  if (-not (Test-Path -Path $JAVA_HOME_LIST_FILE -PathType Leaf))
  {
    New-Item $JAVA_HOME_LIST_FILE > $null
  }
  $csv = Import-Csv $JAVA_HOME_LIST_FILE
  $table = @{}
  $csv | ForEach-Object {
    $table[$_.Key] = $_.Value
  }
  $table
}

function Save-Jdks()
{
  param (
    $Table
  )
  $Table.GetEnumerator() | Select-Object -Property Key,Value | Export-Csv -NoTypeInformation -Path $JAVA_HOME_LIST_FILE
}

function Set-JavaHome()
{
  param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ !$_.Contains(":") })]
    [string]
    $Key,
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path $_ -PathType container })]
    [string]
    $Path
  )
  $jdks = Read-Jdks
  $fullName = (Get-Item $Path).FullName
  $jdks[$Key] = $fullName
  Save-Jdks $jdks
}

function Get-JavaHome()
{
  Read-Jdks
}

function Search-JavaHome()
{
  param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path $_ -PathType container })]
    [string]
    $Path,
    [parameter()]
    [int]
    $Depth = 3
  )
  $items = Get-ChildItem -Path $Path -Depth $Depth -Directory -ErrorAction Ignore
  $items = $items | Where-Object { $_.Name -eq "bin"}
  $items = $items | Where-Object { Test-Path ($_.FullName + "\javac.exe") -PathType Leaf }
  $items | ForEach-Object {
    Write-Output $_.Parent.FullName
  }
}

function setupenv ()
{
  $target_path = $args[0]
  $latest_path = $env:JAVA_HOME
  Write-Output "Set JAVA_HOME = '$target_path'"
  $JAVA_HOME = $target_path
  $env:JAVA_HOME = $target_path
  if ($latest_path)
  {
    $new_path = $env:PATH.Replace(($latest_path + "\bin;"), "")
    $env:PATH = "$JAVA_HOME\bin;$new_path"
  } else
  {
    $env:PATH = "$JAVA_HOME\bin;$env:PATH"
  }
}

<#
.Synopsis
Set current env 'JAVA_HOME' and setup PATH.

.Parameter Path
Path to java home.

.Example
Use-JavaHome C:\xxx\java\jdk-1.8
#>
function Use-JavaHome
{
  param (
    [string]
    $Path,
    [string]
    $Key
  )
  if ($Key)
  {
    $jdks = Read-Jdks
    $jhome = $jdks[$Key]
    if ($jhome -and (Test-Path -Path $jhome -PathType container))
    {
      setupenv $jhome
    } else
    {
      throw "Not valid java home path"
    }
    return
  }

  if ($Path)
  {
    setupenv $Path
    return
  }

  throw "Please provider a key or a path!"
}

Export-ModuleMember -Function Set-JavaHome
Export-ModuleMember -Function Get-JavaHome
Export-ModuleMember -Function Use-JavaHome
Export-ModuleMember -Function Search-JavaHome
