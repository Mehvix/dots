# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Environment Variables
source ~/.profile
source ~/.aliases
[ -f ~/.secrets ] && source ~/.secrets

export PATH=$HOME/bin:/usr/local/bin:$PATH

unsetopt BEEP

# Binds
bindkey -e # emacs (like bash)
bindkey '^H' backward-kill-word # ctrl+backspace deletes word

bindkey '\e[1;5D' backward-word       # Ctrl+Left
bindkey '\e[1;5C' forward-word        # Ctrl+Right

# cd-up-widget() {
#     builtin cd ..
#     local precmd
#     for precmd in $precmd_functions; do
#         $precmd
#     done
#     zle .reset-prompt
# }
cd-up-widget() {
    BUFFER='cd ..'
    zle accept-line
}
zle -N cd-up-widget
bindkey '^N' cd-up-widget
zle -N cd-up-widget
bindkey '^N' cd-up-widget            # Ctrl+n: go up a directory


# ============================================================================
# Completion System
# ============================================================================
fpath+=~/.zfunc
autoload -Uz compinit
unsetopt CASE_GLOB

if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    # check cache once per day
    compinit
else
    compinit -C
fi

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# uv
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"

# ============================================================================
# Plugins
# ============================================================================
ZPLUGINDIR=~/.zsh/plugins

# p10k
source ~/.powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# syntax highlighting
[[ -f $ZPLUGINDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source $ZPLUGINDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# history substring search
[[ -f $ZPLUGINDIR/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && \
    source $ZPLUGINDIR/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey "^[[A" history-substring-search-up      # up arrow
bindkey "^[[B" history-substring-search-down    # down arrow
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# ============================================================================
# History Configuration
# ============================================================================
setopt HIST_IGNORE_ALL_DUPS # do not put duplicated command into history list
setopt HIST_SAVE_NO_DUPS    # do not save duplicated command
setopt HIST_REDUCE_BLANKS   # remove unnecessary blanks
setopt HIST_FIND_NO_DUPS    # step over dups
setopt INC_APPEND_HISTORY   # append history immediatly, rather than on exit
export HISTFILE=~/.zsh_history
export HISTSIZE=10000   #  number of commands that are loaded into memory from $HISTFILE
export SAVEHIST=10000   # number of commands that are stored from $HISTFILE


setopt HIST_IGNORE_ALL_DUPS     # Don't save duplicates
setopt HIST_SAVE_NO_DUPS        # Don't save duplicates
setopt HIST_REDUCE_BLANKS       # Remove unnecessary blanks
setopt HIST_FIND_NO_DUPS        # Don't display duplicates when searching
setopt INC_APPEND_HISTORY       # Append immediately, not on exit
setopt INC_APPEND_HISTORY_TIME  # Append with timestamp
setopt SHARE_HISTORY            # Share history between sessions

HIST_STAMPS="yy/mm/dd"

# ============================================================================
# Colors
# ============================================================================
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export TERM=xterm-256color

d=~/.dircolors
test -r $d && eval "$(dircolors $d)"

# ============================================================================
# FZF
# ============================================================================
# source /usr/share/fzf/key-bindings.zsh
# source /usr/share/fzf/completion.zsh
source <(fzf --zsh)

# ============================================================================
# Async
# ============================================================================
source ~/.async.zsh


# ============================================================================
# Environment source
# ============================================================================
# Source .env if present in current directory
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi


# ============================================================================
# Parent initialization
# ============================================================================
if [[ -n $ZSH_INIT_COMMAND ]]; then
    eval "$ZSH_INIT_COMMAND"
fi
