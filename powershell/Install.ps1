$USER_MODULE_HOME = $env:PSModulePath.Split(";")[0]

function Use-Module {
	param(
		$Name,
		$Path
	)
	if ($Name) {
		Write-Output "Install online module `"$Name`""
		Install-Module -Name $Name -Scope CurrentUser
	} elseif ($Path) {
		Write-Output "Install local module `"$Path`""
		Copy-Item -Recurse $Path $USER_MODULE_HOME
	}
}

function Install-Simple {
	$Source = "$MY_CONFIG_HOME\powershell\profiles\Microsoft.PowerShell_profile.ps1"
	if (-not(Test-Path $Source)) {
		throw "There is no file of `"$Source`""
	}
	if (Test-Path $PROFILE) {
		nvim -d $PROFILE $Source
	}
	$Reply = Read-Host -Prompt "Do you want install powershell profile? [y]"
	if ($Reply -eq "y") {
		Copy-Item $Source $PROFILE
		Install-Module -Name DotNetVersionLister -Scope CurrentUser
		if (-not(Test-Path $USER_MODULE_HOME)) {
			New-Item $USER_MODULE_HOME -Force > $null
		}
		Use-Module -Path "module\MyPsScripts"
		Use-Module -Path "module\JdkSwitcher"
		Use-Module -Name MyPsScripts
		Use-Module -Name posh-git
		Use-Module -Name Terminal-Icons
		Use-Module -Name ZLocation
		Write-Host "Success install profile." -ForegroundColor Green
	}
}

if (-not(Test-Path Variable:\MY_CONFIG_HOME)) {
	throw "There is no MY_CONFIG_HOME"
}
Write-Output "Which you want install?"
Write-Output "1: simple"
Write-Output "2: oh-my-posh"
$Reply = Read-Host -Prompt "[1/2]: "
Switch ($Reply) {
	1 {
		# Simple
		Install-Simple
	}
	2 {
		# Oh my posh
		Write-Output "Not implemented."
	}
	default {
		Write-Output "Non matched. Finish install."
	}
}
