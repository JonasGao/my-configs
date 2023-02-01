param(
  [switch]$Install,
  [switch]$Init,
  [switch]$Packer,
  [switch]$Config,
  [switch]$Dependency
)

$NVIM_CONF_HOME="$HOME/AppData/Local/nvim"

if (-not(Test-Path Variable:\MY_CONFIG_HOME))
{
  throw "There is no MY_CONFIG_HOME"
}

# Prepare parent folder
New-Item -Type Container -Force "$NVIM_CONF_HOME" > $null

function Restore-InitVim
{
  $SOURCE = "$MY_CONFIG_HOME/vim/nvim/init.vim"
  $TARGET = "$NVIM_CONF_HOME/init.vim"
  nvim -d $TARGET $SOURCE
  Copy-Item $SOURCE $TARGET -Confirm
  Write-Host -ForegroundColor Green "Restore neovim config files finished."
}

function Install-Packer
{
  $D = "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim"
  if (Test-Path $D)
  {
    return
  }
  git clone https://github.com/wbthomason/packer.nvim $D
}

function Restore-Config
{
  $N = "$MY_CONFIG_HOME/vim/nvim"
  $L = "$N/lua"
  $P = "$N/plugin"
  $F = "$N/after"
  Copy-Item $L "$NVIM_CONF_HOME/" -Recurse -Force
  Copy-Item $P "$NVIM_CONF_HOME/" -Recurse -Force
  Copy-Item $F "$NVIM_CONF_HOME/" -Recurse -Force
}

function Install-Dependency
{
  scoop install cmake
  scoop install bat
  scoop install gcc
  scoop install lua-language-server

  Build-TelescopeFzfNative
}

function Build-TelescopeFzfNative
{
  Set-Location "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\telescope-fzf-native.nvim\"
  cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build
}

function Get-Nvim
{
  $NvimMsi = "$HOME\Downloads\nvim-win64.msi"
  Invoke-RestMethod -Uri "https://github.com/neovim/neovim/releases/download/nightly/nvim-win64.msi" -OutFile $NvimMsi
  Start-Process $NvimMsi
}

if ($Init)
{
  Restore-InitVim
}

if ($Packer)
{
  Install-Packer
}

if ($Config)
{
  Restore-Config
}

if ($Dependency)
{
  Install-Dependency
}

if ($Instal)
{
  Get-Nvim
}
