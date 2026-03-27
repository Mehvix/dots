#!/bin/bash

[[ $- == *i* ]] && source -- $HOME/.local/share/blesh/ble.sh --attach=none

# env
# [ -f /etc/bashrc ] && . /etc/bashrc
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

__bp_last_argument_prev_command="${__bp_last_argument_prev_command:-}"
eval "$(oh-my-posh init bash --config $HOME/.config/omp/theme.json)"
# PS1='$(_omp_get_primary)'

if [ -n "$TMUX" ]; then   # fix OMP right-prompt off-by-one in tmux
    eval "$(declare -f _omp_get_primary | sed 's/terminal-width="${COLUMNS-0}"/terminal-width="$((${COLUMNS-0} - 1))"/')"
fi

# Attach ble.sh- everything prior is buffered
[[ ! ${BLE_VERSION-} ]] || ble-attach

_deferred_evals=(
  # Completions
  'uv generate-shell-completion bash'
  'uvx --generate-shell-completion bash'
)
for _cmd in "${_deferred_evals[@]}"; do
  if [[ ${BLE_VERSION-} ]]; then
    ble/util/idle.push "eval \"\$($_cmd)\""
  else
    eval "$($_cmd)"
  fi
done
unset _deferred_evals _cmd

# fzf: fallback to eval when not using ble.sh
[[ ${BLE_VERSION-} ]] || eval "$(fzf --bash)"
