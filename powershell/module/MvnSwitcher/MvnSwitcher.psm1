$MVN_LIST_FILE = "$HOME\.mvn\mvn_install.csv"

function Read-Data()
{
  if (-not (Test-Path -Path $MVN_LIST_FILE -PathType Leaf))
  {
    New-Item $MVN_LIST_FILE > $null
  }
  $csv = Import-Csv $MVN_LIST_FILE
  $table = @{}
  $csv | ForEach-Object {
    $table[$_.Key] = $_.Value
  }
  $table
}

function Save-Data()
{
  param (
    $Table
  )
  $Table.GetEnumerator() | Select-Object -Property Key,Value | Export-Csv -NoTypeInformation -Path $MVN_LIST_FILE
}

function Set-MvnHome()
{
  param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty]
    [ValidateScript({ !$_.Contains(":") })]
    [string]
    $Key,
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty]
    [ValidateScript({ Test-Path -Path $_ -PathType container })]
    [string]
    $Path
  )
  $dic = Read-Data
  $fullName = (Get-Item $Path).FullName
  $dic[$Key] = $fullName
  Save-Data $dic
}

function Get-MvnHome()
{
  Read-Data
}

function Search-MvnHome()
{
  param (
    [parameter]
    [ValidateNotNullOrEmpty]
    [ValidateScript({ Test-Path -Path $_ -PathType container })]
    [string]
    $Path = ".",
    [parameter]
    [int]
    $Depth = 3
  )
  $items = Get-ChildItem -Path $Path -Depth $Depth -Directory -ErrorAction Ignore
  $items = $items | Where-Object { $_.Name -eq "bin"}
  $items = $items | Where-Object { Test-Path ($_.FullName + "\mvn.exe") -PathType Leaf }
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
function Use-Mvn
{
  param (
    [string]
    $Path,
    [string]
    $Key
  )
  if ($Key)
  {
    $dic = Read-Data
    $target = $dic[$Key]
    if ($target -and (Test-Path -Path $target -PathType container))
    {
      setupenv $target
    } else
    {
      throw "Not valid maven home path"
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

function Clear-MvnHome()
{
  Remove-Item $JAVA_HOME_LIST_FILE -Force
}

function Install-Mvn()
{
  $v = "3.9.5"
  $u = "https://dlcdn.apache.org/maven/maven-3/$v/binaries/apache-maven-$v-bin.zip"
  $out = "$HOME\Downloads\apache-maven-$v-bin.zip"
  if (Test-Path $out)
  {
    Write-Output "Found `"$out`" exists"
  } else
  {
    Write-Output "Will download `"$u`" to `"$out`""
    Invoke-RestMethod $u -OutFile $out
    Write-Output "Downloaded `"$out`""
  }
  Expand-Archive -Path $out -DestinationPath "D:/Maven/"
  Write-Output "Expanded"
}

Export-ModuleMember -Function Set-MvnHome
Export-ModuleMember -Function Get-MvnHome
Export-ModuleMember -Function Use-Mvn
Export-ModuleMember -Function Search-MvnHome
Export-ModuleMember -Function Clear-MvnHome
Export-ModuleMember -Function Install-Mvn
