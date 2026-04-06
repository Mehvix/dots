#!/bin/bash

[[ $- == *i* ]] && source -- $HOME/.local/share/blesh/ble.sh --attach=none

# env
# [ -f /etc/bashrc ] && . /etc/bashrc
source $HOME/.profile


# History
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth        # ignorespace + ignoredups; no erasedups as that causes history sync, issues w ble.sh (?)
shopt -s histappend           # append to history, don't overwrite
shopt -s cmdhist              # multi-line as one entry
[[ ${BLE_VERSION-} ]] || PROMPT_COMMAND="history -a"   # write history immediately (ble.sh handles this itself)

# Shell Options
shopt -s autocd         # cd not needed
shopt -s globstar       # ** matches recursively
# shopt -s dotglob        # include dotfiles in glob
shopt -s cdspell        # autocorrect typos in cd
shopt -s nocaseglob     # case-insensitive globbing
shopt -s checkwinsize   # update LINES/COLUMNS after each command
shopt -s no_empty_cmd_completion  # avoid searching PATH

_omp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/omp_init.bash"
_omp_theme="$HOME/.config/omp/theme.json"
_omp_key="$(stat -c %Y "$_omp_theme" "$(command -v oh-my-posh)" 2>/dev/null)"
if [[ ! -f "$_omp_cache" || ! -f "${_omp_cache}.key" || "$_omp_key" != "$(< ${_omp_cache}.key)" ]]; then
  oh-my-posh init bash --config "$_omp_theme" --print |
    awk '/_omp_secondary_prompt=\$\(/{skip=1} skip && /^\)/{skip=0; next} !skip' |
    grep -v '"$_omp_executable" notice' |
    sed 's|print \(primary\) \\|print \1 \\\n                --config '"$HOME/.config/omp/theme.json"' \\|;s|print \(transient\) \\|print \1 \\\n                --config '"$HOME/.config/omp/theme.json"' \\|' \
    > "$_omp_cache"
  echo "$_omp_key" > "${_omp_cache}.key"
fi
source "$_omp_cache"
unset _omp_cache _omp_key _omp_theme
# eval "$(oh-my-posh init bash --config $HOME/.config/omp/theme.json)"
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
