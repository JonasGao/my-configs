param(
  [switch]$Install,
  [switch]$Packer,
  [switch]$Config,
  [switch]$Dependency,
  [switch]$BuildFzf,
  $Proxy
)

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
  $CONF_HOME="$HOME/AppData/Local/nvim"
  if (Test-Path $CONF_HOME)
  {
    Write-Host -ForegroundColor Yellow "`"$CONF_HOME`" Already exists!"
  } else
  {
    git clone "git@github.com:jonasgao/nvimrc.git" $CONF_HOME
    Write-Host -ForegroundColor Green "Restore neovim config files finished."
  }
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

if ($BuildFzf)
{
  Build-TelescopeFzfNative
}
