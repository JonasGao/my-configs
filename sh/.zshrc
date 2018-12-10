# Path to your oh-my-zsh installation.
export ZSH=/Users/jonas/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="awesomepanda"

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
plugins=(git osx svn docker ssh-agent mvn nvm npm node zsh-syntax-highlighting zsh-autosuggestions spring)

# User configuration

# export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh
source $HOME/myenv

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

export REPO_OS_OVERRIDE="macosx"
export GRADLE_HOME=/Users/jonas/.sdkman/candidates/gradle/current/bin
export ANDROID_HOME="/usr/local/share/android-sdk"
export JDK8_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home"
export JDK10_HOME="/Library/Java/JavaVirtualMachines/jdk-10.jdk/Contents/Home"
export JAVA_HOME="$JDK8_HOME"
export PY2_HOME="/usr/local/Cellar/python@2/2.7.14_3"
export PY3_HOME="/usr/local/Cellar/python/3.6.5/libexec"

export PATH="/usr/local/sbin:$PATH"
export PATH="$PATH:$HOME/.config/yarn/global/node_modules/.bin"
export PATH="$PATH:$JAVA_HOME/bin"
export PATH="$PATH:$HOME/.bin"

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

cdtemp() {
  tmp_root="$1"
  if [ -z $tmp_root ]; then
    tmp_root="$MY_TEMP_ROOT"
  fi
  if [ -z $tmp_root ]; then
    echo "No temp root dir config"
    exit 1
  fi
  cd $tmp_root
  tmp=tmp-$(date | shasum | cut -c1-6)
  mkdir $tmp
  cd $tmp
}

proxy() {
  port1="$2"
  port2="$3"
  case "$1" in
    on)
      if [[ "$2" == "" ]]; then
        echo '请指定端口'
        return 1
      fi
      export HTTP_PROXY="http://127.0.0.1:$port1"
      export HTTPS_PROXY="http://127.0.0.1:$port1"
      export ALL_PROXY="socks5://127.0.0.1:$port2"
      echo "HTTP(S) => 127.0.0.1:$port1"
      echo "SOCKS5  => 127.0.0.1:$port2"
      ;;
    off)
      unset HTTP_PROXY
      unset HTTPS_PROXY
      unset ALL_PROXY
      echo "unset PROXY"
      ;;
    *)
      echo "$HTTP_PROXY"
      echo "$HTTPS_PROXY"
      echo "$ALL_PROXY"
      ;;
  esac
}

#CUSTOM FUNCTIONS END
	
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Specify your defaults in this environment variable
export HOMEBREW_CASK_OPTS="--appdir=/Volumes/Store/Applications"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Volumes/Store/home/jonas/sdkman"
[[ -s "/Volumes/Store/home/jonas/sdkman/bin/sdkman-init.sh" ]] && source "/Volumes/Store/home/jonas/sdkman/bin/sdkman-init.sh"

#NVM
export NVM_DIR="/Volumes/Store/home/jonas/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

alias flushDns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; say DNS cache flushed;"
alias y=yarn
alias g=git

