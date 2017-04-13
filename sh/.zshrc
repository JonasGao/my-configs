# Path to your oh-my-zsh installation.
export ZSH=/Users/jonas/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="agnoster"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git osx svn docker)

# User configuration

# export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export DEFAULT_USER=$USER

alias flushDns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; say DNS cache flushed;"

alias npm1="npm --registry=https://registry.npm.taobao.org \
--cache=$HOME/.npm/.cache/cnpm \
--disturl=https://npm.taobao.org/mirrors/node \
--userconfig=$HOME/.cnpmrc"

alias npm1g="sudo npm --global --registry=https://registry.npm.taobao.org \
--cache=$HOME/.npm/.cache/cnpm \
--disturl=https://npm.taobao.org/mirrors/node \
--userconfig=$HOME/.cnpmrc"

alias update-cnpm="npm --global update cnpm --registry=https://registry.npm.taobao.org"

export GRADLE_HOME=/Users/jonas/.sdkman/candidates/gradle/current/bin
# add yarn global to PATH
export PATH="$PATH:$HOME/.config/yarn/global/node_modules/.bin"
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_112.jdk/Contents/Home/"
export ANDROID_HOME="/usr/local/share/android-sdk"
export REPO_OS_OVERRIDE="macosx"

#SVN THEME
prompt_svn() {
  local rev branch
  if in_svn; then
    rev=$(svn_get_rev_nr)
    branch=$(svn_get_branch_name)
    if [[ $(svn_dirty_choose_pwd 1 0) -eq 1 ]]; then
      prompt_segment yellow black
      echo -n "$rev" # "$rev@$branch"
      echo -n "±"
    else
      prompt_segment green black
      echo -n "$rev" # "$rev@$branch"
    fi
  fi
}

build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_bzr
  prompt_hg
  prompt_end
#  echo -n "\n$"
}
#SVN THEME END

#CUSTOM FUNCTIONS

proxy() {
  case "$1" in
    on)
      export HTTP_PROXY="http://127.0.0.1:8899"
      export HTTPS_PROXY="http://127.0.0.1:8899"
      echo "HTTP(S) PROXY => 127.0.0.1:8899"
      ;;
    off)
      unset HTTP_PROXY
      unset HTTPS_PROXY
      echo "unset HTTP(S) PROXY"
      ;;
    *)
      echo "Usage: $0 {on|off}"
      ;;
  esac
}

thereIsGoPath() {
  export GOPATH=$(pwd)
  export PATH="$PATH:$GOPATH/bin"
}

saveProfileToGithub() {
  CONF_REPO="$1"
  if [[ "${CONF_REPO}X" == "X" ]]; then
    CONF_REPO="$HOME/Documents/Github/my-configs"
  fi
  echo "------------------------------------"
  echo "Will save profiles to [ \033[32m$CONF_REPO\033[0m ]"
  echo "------------------------------------"
  # save proxifier ppxs
  cp ~/Library/Application\ Support/Proxifier/Profiles/*.ppx "$CONF_REPO/proxifier/mac"
  # save sh rc files
  cp ~/.zshrc "$CONF_REPO/sh/"
  cp ~/.bash_profile "$CONF_REPO/sh"
  cp ~/.bashrc "$CONF_REPO/sh"
  # save vim profiles
  cp ~/.vimrc "$CONF_REPO/vim/mvim/"
  cp -R ~/.vim/colors "$CONF_REPO/vim/mvim/.vim/"
  cp -R ~/.vim/ftplugin "$CONF_REPO/vim/mvim/.vim/"

  PWD=`PWD`
  cd $CONF_REPO
  git diff
  echo "------------------------------------"
  git add .
  git status
  echo "------------------------------------"
  read
  git commit -m 'update: sync mac profile'
  echo "------------------------------------"
  echo 'already add & commit'
  echo "------------------------------------"
  echo 'waiting you push'
  cd $PWD
}

#CUSTOM FUNCTIONS END
	
#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
[[ -s "/Users/jonas/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/jonas/.sdkman/bin/sdkman-init.sh"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
