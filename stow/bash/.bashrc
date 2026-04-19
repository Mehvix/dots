#!/bin/bash

[[ $- == *i* ]] && [[ -f $HOME/.local/share/blesh/ble.sh ]] && source -- $HOME/.local/share/blesh/ble.sh --attach=none

# env
# [ -f /etc/bashrc ] && . /etc/bashrc
source $HOME/.profile


# History
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoreboth        # ignorespace + ignoredups; no erasedups as that causes history sync, issues w ble.sh (?)
shopt -s histappend           # append to history, don't overwrite
shopt -s cmdhist              # multi-line as one entry
[[ ${BLE_VERSION-} ]] || PROMPT_COMMAND="history -a"   # write history immediately (ble.sh handles this itself)
export HISTFILE=~/.shared_history

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
    tmux set -p @last_cmd "" 2>/dev/null
    __tmux_last_histnum=
    __tmux_preexec() {
      [ -n "$COMP_LINE" ] && return
      local num; num=$(HISTTIMEFORMAT= history 1 | sed 's/^[ ]*\([0-9]*\)[ ]*.*/\1/')
      [ "$num" = "$__tmux_last_histnum" ] && return
      __tmux_last_histnum=$num
      local cmd; cmd=$(HISTTIMEFORMAT= history 1 | sed 's/^[ ]*[0-9]*[ ]*//')
      tmux set -p @last_cmd "$cmd" 2>/dev/null
    }
    trap '__tmux_preexec' DEBUG
fi

# Attach ble.sh- everything prior is buffered
[[ ! ${BLE_VERSION-} ]] || ble-attach

_deferred_evals=(
  "command -v uv  &>/dev/null && eval '$(uv generate-shell-completion bash)'"
  "command -v uvx &>/dev/null && eval '$(uvx --generate-shell-completion bash)'"
  "[[ -f "${HOME}/.local/share/kiro-cli/shell/bash_profile.post.bash" ]] && builtin source '${HOME}/.local/share/kiro-cli/shell/bash_profile.post.bash'"
)
for _cmd in "${_deferred_evals[@]}"; do
  if [[ ${BLE_VERSION-} ]]; then
    ble/util/idle.push "$_cmd"
  else
    eval "$_cmd"
  fi
done
unset _deferred_evals _cmd

# fzf: fallback to eval when not using ble.sh
[[ ${BLE_VERSION-} ]] || eval "$(fzf --bash)"
