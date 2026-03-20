#!/bin/bash

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# export SYSTEMD_PAGER=
source ~/.aliases
source ~/.profile
[ -f ~/.secrets ] && source ~/.secrets

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

# Prompt (starship)
eval "$(starship init bash)"

# Transient prompt: collapse previous prompts to just the character symbol
# (starship native transient requires bash 5.1+, this works on 4.4+)
__transient_prompt_trap() {
    # Only act when a command is actually being executed (not empty Enter)
    # and only for interactive prompts (not subshells/scripts)
    if [[ "$BASH_COMMAND" != "$PROMPT_COMMAND" && "$BASH_COMMAND" != "starship_precmd" ]]; then
        # Move cursor up to the info line and clear it, then move back down
        # Starship two-line prompt: line 1 = info, line 2 = character
        printf '\033[1A\033[2K\033[1B'
    fi
}
trap '__transient_prompt_trap' DEBUG
