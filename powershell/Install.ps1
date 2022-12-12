if (-not(Test-Path Variable:\MY_CONFIG_HOME)) {
	throw "There is no MY_CONFIG_HOME"
}
$SOURCE = "$MY_CONFIG_HOME\powershell\profiles\Microsoft.PowerShell_profile.ps1"
if (-not(Test-Path $SOURCE)) {
	throw "There is no file of `"$SOURCE`""
}
if (Test-Path $PROFILE) {
	nvim -d $PROFILE $SOURCE
}
$X = Read-Host -Prompt "Do you want install powershell profile? [y]"
if ($X -eq "y") {
	Copy-Item $SOURCE $PROFILE
	Write-Host "Success install profile." -ForegroundColor Green
}
