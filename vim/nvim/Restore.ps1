param(
  [switch]$All,
  [switch]$Init,
  [switch]$Packer,
  [switch]$Config
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

if ($All)
{
  $Init = $true
  $Packer = $true
  $Config = $true
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

