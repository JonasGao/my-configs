param(
  [Switch]$Vim,
  $SpaceVimHome = "$HOME\.SpaceVim"
)
if (Test-Path -Path $SpaceVimHome -PathType Container)
{
  Write-Output "`"$SpaceVimHome`" already exists"
} else
{
  git clone https://github.com/SpaceVim/SpaceVim.git "$HOME\.SpaceVim"
}
if ($Vim)
{
  New-Item -Path "$HOME\vimfiles" -ItemType Junction -Target "$HOME\.SpaceVim" > $null
  Write-Output "Link to vim"
}
Copy-Item "$MY_CONFIG_HOME\vim\spacevim\.SpaceVim.d" "$HOME\" -Recurse -Force
Write-Output "Overwrite SpaceVim.d"
