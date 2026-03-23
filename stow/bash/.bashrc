#!/bin/bash

[[ $- == *i* ]] && source -- $HOME/.local/share/blesh/ble.sh --attach=none

# env
[ -f /etc/bashrc ] && . /etc/bashrc
source $HOME/.profile


# History
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth:erasedups  # ignore dupes + leading spaces
shopt -s histappend               # append to history, don't overwrite
PROMPT_COMMAND="history -a"       # write history immediately

# Shell Options
shopt -s nocaseglob     # Case-insensitive globbing
shopt -s cdspell        # Autocorrect typos in cd
shopt -s checkwinsize   # Update LINES/COLUMNS after each command

# Completions
eval "$(fzf --bash)"
eval "$(uv generate-shell-completion bash)"
eval "$(uvx --generate-shell-completion bash)"

# Prompt
# eval "$(starship init bash)"
eval "$(oh-my-posh init bash --config $HOME/.config/omp/theme.json)"


# Set initial PS1 so VS Code shell integration doesn't capture the default prompt
PS1='$(_omp_get_primary)'


[[ ! ${BLE_VERSION-} ]] || ble-attach
