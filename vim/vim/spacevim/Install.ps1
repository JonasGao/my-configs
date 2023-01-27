git clone https://github.com/SpaceVim/SpaceVim.git "$HOME\.SpaceVim"
New-Item -Path "$HOME\vimfiles" -ItemType Junction -Target "$HOME\.SpaceVim"
