param (
  [Switch]$Plug,
  [Switch]$Conf,
  $Proxy
)

$VimConfHome="$HOME/vimfiles"

function Resolve-Dir
{
  param (
    $Path
  )
  if (-not(Test-Path -Path "$Path" -PathType Container))
  {
    New-Item $Path -ItemType Container -Force >$null
  }
}

function InstallPlug
{
  $AutoloadHome = "$VimConfHome/autoload"
  Write-Output "Installing plug-vim"
  Resolve-Dir $AutoloadHome
  try
  {
    $OutFile = "$AutoloadHome/plug.vim"
    if (Test-Path -Path $OutFile)
    {
      Write-Output "$OutFile already exists!"
      return 1
    }
    Write-Output "Downloading to $OutFile"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" -OutFile $OutFile -Proxy $Proxy
    Write-Host "`e[32mSuccess install to $AutoloadHome/plug.vim`e[0m"
  } catch
  {
    Write-Host "Failed to install vim-plug: $($error[0])"  -ForegroundColor Red
  }
}

function RestoreConf
{
  git clone "git@github.com:jonasgao/vimfiles.git" $VimConfHome
  Write-Host "`e[32mAlready overwrite.`e[0m"
}

if ($Plug)
{
  InstallPlug
}

if ($Conf)
{
  RestoreConf
}
