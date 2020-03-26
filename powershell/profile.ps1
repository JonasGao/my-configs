# 参考 https://msdn.microsoft.com/en-us/powershell/scripting/core-powershell/ise/how-to-use-profiles-in-windows-powershell-ise
# Current user, PowerShell ISE	$PROFILE.CurrentUserCurrentHost, or $PROFILE
# All users, PowerShell ISE	$PROFILE.AllUsersCurrentHost
# Current user, All hosts	$PROFILE.CurrentUserAllHosts
# All users, All hosts	$PROFILE.AllUsersAllHosts
#
# if (!(Test-Path -Path $PROFILE )) 
# { New-Item -Type File -Path $PROFILE -Force }

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
  Set-Location $env:GOPATH
}

New-Alias emv Move-ItemUsingExplorer
New-Alias ecp Copy-ItemUsingExplorer
New-Alias p pnpm
New-Alias y yarn
New-Alias ll ls
New-Alias which Get-Command
New-Alias grep findstr
New-Alias gopath Set-GoPathLocation

Set-PSReadlineKeyHandler -Key Tab -Function Complete

# -- Modules --
#
# Install-Module posh-git -Scope CurrentUser
# Install-Module oh-my-posh -Scope CurrentUser
# Install-Module DockerCompletion -Scope CurrentUser
#
Import-Module posh-git
Import-Module oh-my-posh
Import-Module DockerCompletion
# -- Optional Module --
# Import-Module posh-gvm

# -- oh-my-posh --
#
# install font:
# from https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Meslo/M/Regular/complete
# 
# install "Meslo LG M for Powerline" 
# Invoke-RestMethod https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/Meslo/M/Regular/complete/Meslo%20LG%20M%20Regular%20Nerd%20Font%20Complete%20Mono.ttf -OutFile font.ttf
# start font.ttf
# Remove-Item font.ttf
#
# setting up theme
#
Set-Theme Agnoster

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$VISUAL="'C:\Program Files (x86)\Vim\vim82\gvim.exe' -f -i NONE"
$EDITOR="$VISUAL"