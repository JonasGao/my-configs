# 参考 https://msdn.microsoft.com/en-us/powershell/scripting/core-powershell/ise/how-to-use-profiles-in-windows-powershell-ise
# Current user, PowerShell ISE	$PROFILE.CurrentUserCurrentHost, or $PROFILE
# All users, PowerShell ISE	$PROFILE.AllUsersCurrentHost
# Current user, All hosts	$PROFILE.CurrentUserAllHosts
# All users, All hosts	$PROFILE.AllUsersAllHosts

if (!(Test-Path -Path $PROFILE )) 
{ New-Item -Type File -Path $PROFILE -Force }
