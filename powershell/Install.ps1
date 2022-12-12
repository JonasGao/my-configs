$USER_MODULE_HOME = $env:PSModulePath.Split(";")[0]
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
	Install-Module -Name DotNetVersionLister -Scope CurrentUser
	if (-not(Test-Path $USER_MODULE_HOME)) {
		New-Item $USER_MODULE_HOME -Force
	}
	Copy-Item -Recurse "module\MyPsScripts" $USER_MODULE_HOME
	Install-Module -Name MyPsScripts -Scope CurrentUser
	Install-Module -Name posh-git -Scope CurrentUser
	Install-Module -Name Terminal-Icons -Scope CurrentUser
	Install-Module -Name ZLocation -Scope CurrentUser
	Write-Host "Success install profile." -ForegroundColor Green
}
