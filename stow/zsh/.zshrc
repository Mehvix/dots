# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Environment Variables
source ~/.profile
source ~/.aliases
source ~/.secrets

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/max/.oh-my-zsh"

# Set name of the theme to load
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="false"
unsetopt CASE_GLOB

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git 
    ssh-agent
    #zsh-autosuggestions 
    zsh-syntax-highlighting 
    history-substring-search
)

zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle :omz:plugins:ssh-agent identities id_151 id_180
zstyle :omz:plugins:ssh-agent quiet yes
zstyle :omz:plugins:ssh-agent lazy yes

source $ZSH/oh-my-zsh.sh

# User configuration
# vi mode
# bindkey -v

# History
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down
setopt HIST_IGNORE_ALL_DUPS # do not put duplicated command into history list
setopt HIST_SAVE_NO_DUPS    # do not save duplicated command
setopt HIST_REDUCE_BLANKS   # remove unnecessary blanks
setopt HIST_FIND_NO_DUPS    # step over dups
setopt INC_APPEND_HISTORY   # append history immediatly, rather than on exit
export HISTFILE=~/.zsh_history
export HISTSIZE=10000   #  number of commands that are loaded into memory from $HISTFILE
export SAVEHIST=10000   # number of commands that are stored from $HISTFILE

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
setopt INC_APPEND_HISTORY_TIME  # append command to history file immediately after execution
HIST_STAMPS="yy/mm/dd"


# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_TYPE=en_US.UTF-8
export LC_CTYPE=C

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#     export EDITOR='vim'
# else
#     export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# source .env if present
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# https://github.com/mafredri/zsh-async
source ~/.async.zsh     # todo outsource this to plugin manager

# fzf
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh


# Add colors to Terminal
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export TERM=xterm-256color

d=~/.dircolors
test -r $d && eval "$(dircolors $d)"

# chruby
#source /usr/share/chruby/chruby.sh
#source /usr/share/chruby/auto.sh
#RUBIES=(/opt/ruby* $HOME/.rubies/*)

# pipx
autoload -U bashcompinit
bashcompinit
#eval "$(register-python-argcomplete pipx)"

# poetry
fpath+=~/.zfunc
autoload -Uz compinit && compinit

# pyenv
#export PYENV_ROOT="$HOME/.pyenv"
#command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
#eval "$(pyenv init -)"

# nvm 
#source /usr/share/nvm/init-nvm.sh 

# https://stackoverflow.com/questions/23556330/run-nvm-use-automatically-every-time-theres-a-nvmrc-file-on-the-directory/50378304#50378304
#_nvmrc_hook() {
#  if [[ $PWD == $PREV_PWD ]]; then
#    return
#  fi
#  
#  PREV_PWD=$PWD
#  [[ -f ".nvmrc" ]] && nvm use
#}
#
#if ! [[ "${PROMPT_COMMAND:-}" =~ _nvmrc_hook ]]; then
#  PROMPT_COMMAND="_nvmrc_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
#fi

# Allow parent to initialize shell
# https://stackoverflow.com/a/60438516/7833617
if [[ -n $ZSH_INIT_COMMAND ]]; then
    #echo "Running: $ZSH_INIT_COMMAND"
    eval "$ZSH_INIT_COMMAND"
fi


#[ -f "/home/max/.ghcup/env" ] && source "/home/max/.ghcup/env" # ghcup-env
#autoload -Uz compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/max/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/max/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/max/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/max/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# bun completions
#[ -s "/home/max/.local/share/reflex/bun/_bun" ] && source "/home/max/.local/share/reflex/bun/_bun"

# bun
#export BUN_INSTALL="$HOME/.local/share/reflex/bun"
#export PATH="$BUN_INSTALL/bin:$PATH"
#autoload -Uz compinit && compinit
