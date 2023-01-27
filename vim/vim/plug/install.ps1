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
  Resolve-Dir $AutoloadHome
  try
  {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" -OutFile "$AutoloadHome/plug.vim" -Proxy $Proxy
    Write-Host "`e[32mSuccess install to $AutoloadHome/plug.vim`e[0m"
  } catch
  {
    Write-Host "Failed to install vim-plug: $($error[0])"  -ForegroundColor Red
  }
}

function RestoreConf
{
  $src = "$ConfSrc/.vimrc"
  $dst = "$HOME/.vimrc"
  Copy-Item "$SRC" "$DST"
  Write-Host "`e[32mAlready overwrite $dst by $src`e[0m"
}

if ($Plug)
{
  InstallPlug
}

if ($Conf)
{
  RestoreConf
}

if ($Cleanup)
{
  if (Test-Path -Path $VimConfHome -PathType Container)
  {
    Remove-Item -Force -Recurse "$VimConfHome"
  } else
  {
    Remove-Item -Force "$VimConfHome"
  }
}
