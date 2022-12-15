$VIM_CONF_HOME="$HOME/vimfiles"
$PACK_HOME="$VIM_CONF_HOME/pack"
$PACK_START="$PACK_HOME/packages/start"

if (-not(Test-Path Variable:\MY_CONFIG_HOME)) {
  throw "Can not found MY_CONFIG_HOME"
}

nvim -d "$MY_CONFIG_HOME/vim/vim/vimrc" "$HOME/.vimrc"

$REPLY = Read-Host -Prompt "Press [y] restore vimrc"
if ($REPLY -eq "y") {
  Copy-Item -Force "$MY_CONFIG_HOME/vim/vim/vimrc" "$HOME/.vimrc"
  Write-Host -ForegroundColor Green "Restore vimrc finished."
}

function Install-Plugin {
  param(
    $Name,
    $Repo
  )
  $REPLY = Read-Host -Prompt "Press [y] install `"$Name`""
  if ($REPLY -eq "y") {
  	New-Item -Force -Type Container "$PACK_START/" > $null
  	git clone "git@github.com:$Repo.git" "$PACK_START/$Name"
  } 
}

Install-Plugin -Name airline -Repo vim-airline/vim-airline
Install-Plugin -Name easymotion -Repo easymotion/vim-easymotion
Install-Plugin -Name fzf -Repo junegunn/fzf
Install-Plugin -Name fzf.vim -Repo junegunn/fzf.vim
Install-Plugin -Name vim-visual-multi -Repo mg979/vim-visual-multi

#if echo && read -qs REPLY\?"Press [y] install airline: "; then
#	mkdir -p "$HOME/.vim/pack/dist/start/"
#	git clone git@github.com:vim-airline/vim-airline.git "$HOME/.vim/pack/dist/start/vim-airline"
#elif echo && read -qs REPLY\?"Press [y] install custom statusline: "; then
#	cp "$MY_CONFIG_HOME/vim/vim/statusline.vim" "$HOME/.vim/autoload/"
#fi

