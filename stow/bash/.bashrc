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

_omp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/omp_init.bash"
_omp_hash=$(md5sum "$HOME/.config/omp/theme.json" "$(which oh-my-posh)" 2>/dev/null | md5sum | cut -d' ' -f1)
if [[ ! -f "$_omp_cache" || ! -f "${_omp_cache}.hash" || "$_omp_hash" != "$(cat ${_omp_cache}.hash)" ]]; then
  oh-my-posh init bash --config "$HOME/.config/omp/theme.json" --print |
    awk '/_omp_secondary_prompt=\$\(/{skip=1} skip && /^\)/{skip=0; next} !skip' |
    grep -v '"$_omp_executable" notice' |
    sed 's|print primary \\|print primary \\\n                --config '"$HOME/.config/omp/theme.json"' \\|' \
    > "$_omp_cache"
  echo "$_omp_hash" > "${_omp_cache}.hash"
fi
source "$_omp_cache"
unset _omp_cache _omp_hash
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
