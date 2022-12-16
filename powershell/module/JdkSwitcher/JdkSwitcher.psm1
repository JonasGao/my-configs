$JAVA_HOME_LIST_FILE = "$HOME\.jdks\list"

function Get-AllJavaHomeTable() {
  $table = @{}
  Get-Content -Path $JAVA_HOME_LIST_FILE | ForEach-Object {
    if ($_) {
      $pair = $_.Split(": ")
      $table.Add($pair[0], $pair[1])
    }
  }
  $table
}

function Add-JavaHome() {
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
  if (-not (Test-Path -Path $JAVA_HOME_LIST_FILE -PathType Leaf)) {
    New-Item $JAVA_HOME_LIST_FILE > $null
  }
  $table = Get-AllJavaHomeTable
  $fullName = (Get-Item $Path).FullName
  Add-Content -Path $JAVA_HOME_LIST_FILE -Value ($Key + ": $fullName")
}

function Get-AllJavaHome() {
  Get-Content -Path $JAVA_HOME_LIST_FILE
}

function Search-JavaHome() {
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

function setupenv () {
  $target_path = $args[0]
    $latest_path = $env:JAVA_HOME
    Write-Output "Set JAVA_HOME = '$target_path'"
    $JAVA_HOME = $target_path
    $env:JAVA_HOME = $target_path
    if ($latest_path) {
      $new_path = $env:PATH.Replace(($latest_path + "\bin;"), "")
        $env:PATH = "$JAVA_HOME\bin;$new_path"
    } else {
      $env:PATH = "$JAVA_HOME\bin;$env:PATH"
    }
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
    [string]
    $Path,
    [string]
    $Key
  )
  if ($Key) {
    $jhome = (Get-AllJavaHomeTable)[$Key]
    setupenv $jhome
    return
  }

  if ($Path) {
    setupenv $Path
  }

  throw "Please provider a key or a path!"
}

Export-ModuleMember -Function Add-JavaHome
Export-ModuleMember -Function Get-AllJavaHome
Export-ModuleMember -Function Set-JavaHome
Export-ModuleMember -Function Search-JavaHome
