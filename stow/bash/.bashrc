#!/bin/bash

# bail for non-interactive shells
[[ $- == *i* ]] || return 0

_blesh="${BLESH_DIR:-$HOME/.local/share/blesh}/ble.sh"; [[ -f $_blesh ]] && source -- "$_blesh" --attach=none; unset _blesh;

source $HOME/.profile


# History
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth        # ignorespace + ignoredups; no erasedups as that causes history sync, issues w ble.sh (?)
shopt -s histappend           # append to history, don't overwrite
shopt -s cmdhist              # multi-line as one entry
[[ ${BLE_VERSION-} ]] || PROMPT_COMMAND="history -a"   # write history immediately (ble.sh handles this itself)
HISTFILE=~/.shared_history

# Shell Options
shopt -s autocd         # cd not needed
shopt -s globstar       # ** matches recursively
# shopt -s dotglob        # include dotfiles in glob
shopt -s cdspell        # autocorrect typos in cd
shopt -s nocaseglob     # case-insensitive globbing
shopt -s checkwinsize   # update LINES/COLUMNS after each command
shopt -s no_empty_cmd_completion  # avoid searching PATH

# complete dirs for destination arg (source=files, dest=dirs)
_dest_dir_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}" nargs=0 flag=-f
    for ((i=1; i<COMP_CWORD; i++)); do [[ "${COMP_WORDS[i]}" != -* ]] && ((nargs++)); done
    ((nargs)) && flag=-d
    COMPREPLY=($(compgen $flag -- "$cur"))
}
complete -o filenames -F _dest_dir_complete mv cp rsync  # first arg=files, subsequent=dirs
complete -d -o dirnames cd du rmdir pushd  # dirs only; -o dirnames ensures ble.sh ambiguous fallback stays dirs-only

_file_only_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}" f
    COMPREPLY=()
    for f in $(compgen -f -- "$cur"); do
        [[ -d ${f/#\~/$HOME} ]] || COMPREPLY+=("$f")
    done
}
complete -o filenames -F _file_only_complete \
  vim nvim v \
  less more cat bat head tail wc stat \
  diff cmp patch \
  gcc cc python python3 lua \
  source .


eval "$(oh-my-posh init bash --config "${OMP_THEME:-$HOME/.config/omp/theme.json}" --print)"
_dirlabel_update() { eval "$(dirlabel 2>/dev/null)"; }
[[ " ${PROMPT_COMMAND[*]} " == *" _dirlabel_update "* ]] || PROMPT_COMMAND=(_dirlabel_update "${PROMPT_COMMAND[@]}")
# PS1='$(_omp_get_primary)'

if [ -n "$TMUX" ]; then
    eval "$(declare -f _omp_get_primary | sed 's/terminal-width="${COLUMNS-0}"/terminal-width="$((${COLUMNS-0} - 1))"/')" # fix OMP right-prompt off-by-one
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
    if [[ ${BLE_VERSION-} ]]; then
      blehook PREEXEC+='__tmux_preexec'
    else
      trap '__tmux_preexec' DEBUG
    fi
fi

# Attach ble.sh- everything prior is buffered
[[ ! ${BLE_VERSION-} ]] || ble-attach

_deferred_evals=(
  'command -v uv  &>/dev/null && eval "$(uv generate-shell-completion bash)"'
  'command -v uvx &>/dev/null && eval "$(uvx --generate-shell-completion bash)"'
  'command -v activate-global-python-argcomplete &>/dev/null && eval "$(activate-global-python-argcomplete --dest=-)"'
  '[[ -f "${HOME}/.local/share/kiro-cli/shell/bash_profile.post.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bash_profile.post.bash"'
  # 'shopt -oq posix || { [[ -f /usr/share/bash-completion/bash_completion ]] && builtin source /usr/share/bash-completion/bash_completion; }'
)
if [[ $- != *c* ]]; then
  for _cmd in "${_deferred_evals[@]}"; do
    if [[ ${BLE_VERSION-} ]]; then
      ble/util/idle.push "$_cmd"
    else
      eval "$_cmd"
    fi
  done
fi
unset _deferred_evals _cmd

# fzf: fallback to eval when not using ble.sh
[[ ${BLE_VERSION-} ]] || eval "$(fzf --bash)"
