# 参考 https://msdn.microsoft.com/en-us/powershell/scripting/core-powershell/ise/how-to-use-profiles-in-windows-powershell-ise
# Current user, PowerShell ISE	$PROFILE.CurrentUserCurrentHost, or $PROFILE
# All users, PowerShell ISE	$PROFILE.AllUsersCurrentHost
# Current user, All hosts	$PROFILE.CurrentUserAllHosts
# All users, All hosts	$PROFILE.AllUsersAllHosts
#
# if (!(Test-Path -Path $PROFILE )) 
# { New-Item -Type File -Path $PROFILE -Force }

New-Alias p pnpm
New-Alias y yarn
New-Alias ll ls

Set-PSReadlineKeyHandler -Key Tab -Function Complete

# -- Modules --
#
# Install-Module posh-git -Scope CurrentUser
# Install-Module oh-my-posh -Scope CurrentUser
#
Import-Module posh-git
Import-Module oh-my-posh
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
