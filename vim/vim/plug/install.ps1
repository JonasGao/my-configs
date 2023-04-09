param (
  [Switch]$Plug,
  [Switch]$Conf,
  [Switch]$Clean,
  $Proxy
)

if (-not(Test-Path -Path "$MY_CONFIG_HOME" -PathType Container))
{
  $ErrorMsg="There is no MY_CONFIG_HOME(Value:$MY_CONFIG_HOME)"
  throw $ErrorMsg
}

$VimConfHome="$HOME/vimfiles"
$PackHome="$VimConfHome/pack"
$PackStart="$PackHome/packages/start"
$ConfSrc = "$MY_CONFIG_HOME/vim/vim/plug"
$AutoloadHome = "$VimConfHome/autoload"

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

Resolve-Dir $PackStart

function InstallPlug
{
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
  Copy-Item "$ConfSrc/.vimrc" "$HOME/.vimrc"
  Copy-Item "$ConfSrc/vimfiles/plugin" "$HOME/vimfiles/plugin" -Recurse
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

if ($Clean)
{
  Write-Output "Do Cleanup..."
  if (Test-Path -Path $VimConfHome -PathType Container)
  {
    Write-Output "Force remove $VimConfHome"
    Remove-Item -Force -Recurse "$VimConfHome"
  } else
  {
    Write-Output "Force remove $VimConfHome"
    Remove-Item -Force "$VimConfHome"
  }
}
