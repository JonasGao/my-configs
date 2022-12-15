$NVIM_CONF_HOME="$HOME/AppData/Local/nvim"
$PACK_HOME="$NVIM_CONF_HOME/pack"
$PACK_START="$PACK_HOME/dist/start"

if (-not(Test-Path Variable:\MY_CONFIG_HOME)) {
	throw "There is no MY_CONFIG_HOME"
}
New-Item -Type Container -Force "$NVIM_CONF_HOME"
Copy-Item "$MY_CONFIG_HOME/vim/nvim/init.vim" "$NVIM_CONF_HOME/init.vim"
Write-Host -ForegroundColor Green "Restore neovim config files finished."

function Install-Plugin {
  param(
    $Name,
    $Repo
  )
  $REPLY = Read-Host -Prompt "Press [y] install `"$Name`""
  if ($REPLY -eq "y") {
  	New-Item -Force -Type Container "$PACK_START/"
  	git clone "git@github.com:$Repo.git" "$PACK_START/$Name"
  } 
}

Install-Plugin -Name airline -Repo vim-airline/vim-airline
Install-Plugin -Name easymotion -Repo easymotion/vim-easymotion
Install-Plugin -Name fzf -Repo junegunn/fzf
Install-Plugin -Name fzf.vim -Repo junegunn/fzf.vim
Install-Plugin -Name vim-visual-multi -Repo mg979/vim-visual-multi

