function Copy-ItemUsingExplorer {
  param(
    [string]$Source,
    [string]$Destination,
    [int]$CopyFlags = 0
  )

  if (!$Source) {
    Write-Output "There is no source"
    return 1
  }

  if (!$Destination) {
    Write-Output "There is no destination"
    return 2
  }

  $objShell = New-Object -ComObject 'Shell.Application'    
  $objFolder = $objShell.NameSpace((Get-Item $Destination).FullName)
  $objFolder.CopyHere((Get-Item $Source).FullName, $CopyFlags.ToString('{0:x}'))
}

function Move-ItemUsingExplorer {
  param(
    [string]$Source,
    [string]$Destination,
    [int]$MoveFlags = 0
  )

  if (!$Source) {
    Write-Output "There is no source"
    return 1
  }

  if (!$Destination) {
    Write-Output "There is no destination"
    return 2
  }

  $objShell = New-Object -ComObject 'Shell.Application'    
  $objFolder = $objShell.NameSpace((Get-Item $Destination).FullName)
  $objFolder.MoveHere((Get-Item $Source).FullName, $MoveFlags.ToString('{0:x}'))
}

function Set-GoPathLocation {
  cd $env:GOPATH
}

function Set-JavaHome {

  param (
    $Path
  )
  
  Write-Output "Set JAVA_HOME = '$Path'"
  $JAVA_HOME = $Path
  $env:JAVA_HOME = $Path
  $env:PATH = "$JAVA_HOME\bin;$env:PATH"
}

$DLOCALAPPDATA = "D:\Users\Jonas\AppData\Local"

New-Alias emv Move-ItemUsingExplorer
New-Alias ecp Copy-ItemUsingExplorer
New-Alias p pnpm
New-Alias y yarn
New-Alias ll ls
New-Alias which Get-Command
New-Alias grep findstr
New-Alias gopath Set-GoPathLocation

Set-PSReadlineKeyHandler -Key Tab -Function Complete

Import-Module posh-git
Import-Module oh-my-posh
Import-Module DockerCompletion
Set-Theme Agnoster

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$VISUAL="'C:\Program Files (x86)\Vim\vim82\gvim.exe' -f -i NONE"
$EDITOR="$VISUAL"
