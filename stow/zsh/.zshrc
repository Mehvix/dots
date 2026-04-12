#!/usr/bin/env zsh

unsetopt BEEP

b() { bash -c "$*"; } # bash wrapper

source ~/.profile

if [[ -n $ZSH_INIT_COMMAND ]]; then
    eval "$ZSH_INIT_COMMAND"
fi


# binds
# ============================================================================
bindkey -e # emacs (like bash)

WORDCHARS=${WORDCHARS//[\/.]}   # 'word' split by these chars
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


# completion
# ============================================================================
fpath+=~/.zfunc
autoload -Uz compinit
unsetopt CASE_GLOB

if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    # check cache once per day
    compinit -i
else
    compinit -C -i
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


# plugins
# ============================================================================
source <(fzf --zsh)
source ~/.async.zsh

ZPLUGINDIR=~/.zsh/plugins

# # p10k
# source ~/.powerlevel10k/powerlevel10k.zsh-theme
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# omp
eval "$(oh-my-posh init zsh --config ~/.config/omp/theme.json)"

# syntax highlighting
[[ -f $ZPLUGINDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source $ZPLUGINDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# history substring search
[[ -f $ZPLUGINDIR/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && \
    source $ZPLUGINDIR/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey "^[[A" history-substring-search-up      # up arrow
bindkey "^[[B" history-substring-search-down    # down arrow
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1


# history
# ============================================================================
setopt HIST_IGNORE_ALL_DUPS # do not put duplicated command into history list
setopt HIST_SAVE_NO_DUPS    # do not save duplicated command
setopt HIST_REDUCE_BLANKS   # remove unnecessary blanks
setopt HIST_FIND_NO_DUPS    # step over dupes
setopt INC_APPEND_HISTORY   # append history immediately, rather than on exit
unsetopt SHARE_HISTORY              # fsok fzf maintaining history of current shell
unsetopt EXTENDED_HISTORY           # fsok compatibility with bash
unsetopt INC_APPEND_HISTORY_TIME    # ||
export HISTSIZE=10000   # number of commands that are loaded into memory from $HISTFILE
export SAVEHIST=10000   # number of commands that are stored from $HISTFILE
export HISTFILE=~/.shared_history
