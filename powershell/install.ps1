param (
  [Switch]$Scoop,
  [Switch]$OhMyPosh,
  [Switch]$Profiles,
  [Switch]$Modules,
  $Proxy
)

$USER_MODULE_HOME = $env:PSModulePath.Split(";")[0]

function Use-Module
{
  param(
    $Name,
    $Path
  )
  if ($Name)
  {
    Write-Output "Install online module `"$Name`""
    Install-Module -Name $Name -Scope CurrentUser
  } elseif ($Path)
  {
    Write-Output "Install local module `"$Path`""
    Copy-Item -Force -Recurse $Path $USER_MODULE_HOME
  }
}

function Install-Modules
{
  if ($Modules)
  {
    #Install-Module -Name DotNetVersionLister -Scope CurrentUser
    Use-Module -Path "module\MyPsScripts"
    Use-Module -Path "module\JdkSwitcher"
    Use-Module -Name posh-git
    Use-Module -Name Terminal-Icons
    #Use-Module -Name ZLocation
    Use-Module -Name z
    Write-Host "Success install Modules." -ForegroundColor Green
  }
}

function Install-OmpProfile
{
  if ($Profiles)
  {
    $PROFILE_HOME = (Get-Item $PROFILE).Directory
    Copy-Item "$MY_CONFIG_HOME\powershell\omp\Microsoft.PowerShell_profile.ps1" $PROFILE
    Copy-Item "$MY_CONFIG_HOME\powershell\omp\env.ps1" "$PROFILE_HOME\env.ps1"
    Write-Host "Success install Profiles." -ForegroundColor Green
  }
}

function Install-Scoop
{
  if ($Scoop)
  {
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    scoop install delta
    scoop install lua-language-server
  }
}

function Install-OhMyPosh
{
  if ($OhMyPosh)
  {
    winget install JanDeDobbeleer.OhMyPosh -s winget
  }
}

if (-not(Test-Path Variable:\MY_CONFIG_HOME))
{
  throw "There is no MY_CONFIG_HOME"
}

Install-Scoop
Install-OhMyPosh
Install-OmpProfile
Install-Modules
