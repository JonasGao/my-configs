Set-PSReadlineKeyHandler -Key Tab -Function Complete
Import-Module posh-git

Import-Module ZLocation

if (Test-Path "C:\Users\Administrator\.jabba\jabba.ps1") { . "C:\Users\Administrator\.jabba\jabba.ps1" }

function Set-JavaHome {

  param (
    $Path
  )
  
  $ABS_PATH = Resolve-Path $Path
  echo "Set JAVA_HOME = '$ABS_PATH'"
  $JAVA_HOME = $ABS_PATH
  $env:JAVA_HOME = $JAVA_HOME
  $env:PATH = "$JAVA_HOME\bin;$env:PATH"

}

function Set-HttpProxy {

  param (
    $Url
  )

  $env:HTTP_PROXY = $Url
  $env:HTTPS_PROXY = $Url

}

$NVIM_HOME = "$HOME\Apps\nvim-win64\Neovim"
$env:PATH = "$NVIM_HOME\bin;$env:PATH"
