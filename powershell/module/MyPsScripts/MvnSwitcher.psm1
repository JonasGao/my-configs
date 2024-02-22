$CONFIG_HOME = "$HOME\.mvn"
$MVN_LIST_FILE = "$CONFIG_HOME\mvn_install.csv"
$LATEST_USE_MVN = "$CONFIG_HOME\latest_use"

function Read-Data()
{
  if (-not (Test-Path -Path $MVN_LIST_FILE -PathType Leaf))
  {
    New-Item -Force $MVN_LIST_FILE > $null
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

function Add-MvnHome()
{
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ !$_.Contains(":") })]
    [string] $Key,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path $_ -PathType container })]
    [string] $Path
  )
  $dic = Read-Data
  $full = (Get-Item $Path).FullName
  Write-Host -ForegroundColor Green "Add maven [$Key] -> `"$full`""
  $dic[$Key] = $full
  Save-Data $dic
}

function Get-MvnHome()
{
  Read-Data
}

function Search-MvnHome()
{
  param (
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path $_ -PathType container })]
    [string] $Path = ".",
    [int] $Depth = 3,
    [Switch] $Save
  )
  $items = Get-ChildItem -Path $Path -Depth $Depth -Directory -ErrorAction Ignore
  $items = $items | Where-Object { $_.Name -eq "bin"}
  $items = $items | Where-Object { Test-Path (Join-Path $_.FullName "\mvn.cmd") }
  $items | ForEach-Object {
    if ($Save)
    {
      Add-MvnHome -Key $_.Parent.Name -Path $_.Parent.FullName
    } else
    {
      Write-Output $_.Parent.FullName
    }
  }
}

function latestuse()
{
  param([Switch]$Set, $Value)
  if ($Set)
  {
    New-Item -Force $LATEST_USE_MVN -ItemType File > $null
    Set-Content -Path $LATEST_USE_MVN -Value $Value
  } else
  {
    if (Test-Path $LATEST_USE_MVN)
    {
      Get-Content $LATEST_USE_MVN
    }
  }
}

function setupenv ()
{
  $target_path = $args[0]
  if (!$target_path)
  {
    return
  }
  $latest_path = $env:MAVEN_HOME
  $env:MAVEN_HOME = $target_path
  if ($latest_path)
  {
    if (-not (Test-Path Env:\ORIGIN_MAVEN_HOME))
    {
      $env:ORIGIN_MAVEN_HOME = $latest_path
    }
    $new_path = $env:PATH.Replace(($latest_path + "\bin;"), "")
    $env:PATH = "$target_path\bin;$new_path"
  } else
  {
    $env:PATH = "$target_path\bin;$env:PATH"
  }
  latestuse -Set -Value $target_path
}

function Use-Mvn
{
  param (
    [string]
    $Key,
    [string]
    $Path
  )
  if ($Key)
  {
    Write-Host -ForegroundColor Green "Find maven by key: $Key"
    $dic = Read-Data
    $target = $dic[$Key]
    if ($target -and (Test-Path -Path $target -PathType container))
    {
      Write-Host -ForegroundColor Green "Set MAVEN_HOME = '$target_path'"
      setupenv $target
    } else
    {
      throw "Not valid maven home path"
    }
    return
  }

  if ($Path)
  {
    Write-Host -ForegroundColor Green "Set MAVEN_HOME = '$target_path'"
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

setupenv (latestuse)

Export-ModuleMember -Function Add-MvnHome
Export-ModuleMember -Function Get-MvnHome
Export-ModuleMember -Function Use-Mvn
Export-ModuleMember -Function Search-MvnHome
Export-ModuleMember -Function Clear-MvnHome
Export-ModuleMember -Function Install-Mvn
