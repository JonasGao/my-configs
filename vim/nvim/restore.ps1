param(
  [switch]$Install,
  [switch]$Packer,
  [switch]$Config,
  [switch]$Dependency,
  $Proxy
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
  Copy-Item $SOURCE $TARGET
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
  Restore-InitVim
  $N = "$MY_CONFIG_HOME/vim/nvim"
  $L = "$N/lua"
  $P = "$N/plugin"
  $F = "$N/after"
  Copy-Item $L "$NVIM_CONF_HOME/" -Recurse -Force
  Copy-Item $P "$NVIM_CONF_HOME/" -Recurse -Force
  Copy-Item $F "$NVIM_CONF_HOME/" -Recurse -Force
  Write-Host -ForegroundColor Green "Restore neovim config files finished."
}

function Install-Dependency
{
  # For telescope-fzf-native
  scoop install cmake
  # For treesitter
  scoop install gcc
  # For lsp
  scoop install lua-language-server
  # Maybe for telescope preview
  scoop install bat
  # For fuzzy finder (like telescope and fzf ...)
  scoop install ripgrep
  scoop install fd

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
  Write-Output "Downloading msi"
  Invoke-RestMethod -Uri "https://github.com/neovim/neovim/releases/download/stable/nvim-win64.msi" -OutFile $NvimMsi -Proxy $Proxy
  Write-Output "Downloaded"
  Start-Process $NvimMsi
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

if ($Install)
{
  Get-Nvim
}
