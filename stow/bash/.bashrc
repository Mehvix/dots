#!/bin/bash

[[ $- == *i* ]] || return 0
[[ -z "${ANTIGRAVITY_AGENT:-}${CLAUDE_CODE:-}${KIRO_AGENT:-}" ]] || return 0

_blesh="${BLESH_DIR:-$HOME/.local/share/blesh}/ble.sh"; [[ -f $_blesh ]] && source -- "$_blesh" --attach=none; unset _blesh;

source $HOME/.profile


# History
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth        # ignorespace + ignoredups; no erasedups as that causes history sync, issues w ble.sh (?)
export HISTIGNORE='cd ..'            # don't record the Ctrl+N shortcut
shopt -s histappend           # append to history, don't overwrite
shopt -s cmdhist              # multi-line as one entry
[[ ${BLE_VERSION-} ]] || PROMPT_COMMAND="history -a"   # write history immediately (ble.sh handles this itself)
HISTFILE=~/.shared_history
[[ -f "$HISTFILE" ]] || : > "$HISTFILE"  # avoid tac error on first-ever exit

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
    local cur="${COMP_WORDS[COMP_CWORD]}" nargs=0
    for ((i=1; i<COMP_CWORD; i++)); do
        [[ "${COMP_WORDS[i]}" == -* ]] && continue
        ((nargs++))
    done
    if ((nargs)); then
        mapfile -t COMPREPLY < <(compgen -d -- "$cur")
    else
        mapfile -t COMPREPLY < <(compgen -f -- "$cur")
    fi
}
complete -o filenames -F _dest_dir_complete mv cp  # first arg=files, subsequent=dirs
# dirs only, sorted naturally (1,2,10) rather than lexically (1,10,2)
# pad to 20 digits and sort to avoid '@tmp'-suffix dir funnies
# -o dirnames ensures ble.sh ambiguous fallback stays dirs-only
# -o nosort tells ble.sh to honor our COMPREPLY order.
# COMPREPLY holds full paths so the completion inserts the whole path; the menu is
# told to show only the basename (else long dir prefixes wrap one-per-line off-screen).
#   stock readline: `compopt -o filenames` -> displays the last path component.
#   ble.sh: honors filenames too, BUT `.inputrc`'s menu-complete-display-prefix=on maps
#     to :menu-show-prefix: in comp_type, which forces the whole candidate to be shown.
#     Strip that flag locally (dynamic scope reaches ble's frame) so the menu shows
#     basenames while insertion keeps the full path. No-op / harmless under stock bash.
_natural_dir_complete() {
  compopt -o filenames 2>/dev/null
  [[ ${comp_type-} ]] && comp_type=${comp_type//:menu-show-prefix:/:}
  mapfile -t COMPREPLY < <(
    compgen -d -- "${COMP_WORDS[COMP_CWORD]}" |
    awk '{
      base = $0; sub(/.*\//, "", base)
      key = base; out = ""
      while (match(key, /[0-9]+/)) {
        out = out substr(key, 1, RSTART-1) sprintf("%020d", substr(key, RSTART, RLENGTH)+0)
        key = substr(key, RSTART+RLENGTH)
      }
      printf "%s%s\t%s\n", out, key, $0
    }' | LC_ALL=C sort -t$'\t' -k1,1 | cut -f2-
  )
}
complete -o dirnames -o filenames -o nosort -F _natural_dir_complete cd du rmdir pushd
# fzf's deferred completion (loaded by ble-attach) hijacks cd/du/rmdir/pushd with
# _fzf_{dir,path}_completion, dropping our sort -V; re-register after it loads.
if [[ ${BLE_VERSION-} ]]; then
  blehook/eval-after-load complete '
    builtin unset -f ble/cmdinfo/complete:cd 2>/dev/null
    builtin unset -f ble/cmdinfo/complete:pushd 2>/dev/null
  '
  ble/util/import/eval-after-load integration/fzf-completion \
    'complete -o dirnames -o filenames -o nosort -F _natural_dir_complete cd du rmdir pushd'
fi


eval "$(oh-my-posh init bash --config "${OMP_THEME:-$HOME/.config/omp/theme.json}" --print)"
_dirlabel_last_key=""
_dirlabel_update() {
    local f="${XDG_CONFIG_HOME:-$HOME/.config}/dirlabels"
    local key="$PWD:$(stat -c %Y "$f" 2>/dev/null)"    # re-eval on dir change or label edit
    [[ "$key" == "$_dirlabel_last_key" ]] && return
    _dirlabel_last_key="$key"
    eval "$(dirlabel 2>/dev/null)"
}
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

# propagate completion thru aliases, including subcommand-baking ones
_complete_alias() {
    local cmd="${COMP_WORDS[0]}"
    local raw
    raw=$(alias "$cmd" 2>/dev/null) || return
    # `alias foo='bar -x sub'` -> raw = `bar -x sub`
    raw="${raw#*=\'}"
    raw="${raw%\'}"

    local -a tokens
    eval "tokens=($raw)" 2>/dev/null || return
    (( ${#tokens[@]} )) || return

    local target="${tokens[0]}"
    [[ "$target" == "$cmd" ]] && return    # NOT all the way down

    local -a rest=("${COMP_WORDS[@]:1}")
    local shift_n=$(( ${#tokens[@]} - 1 ))
    local new_line="${tokens[*]} ${rest[*]}"
    local delta=$(( ${#new_line} - ${#COMP_LINE} ))
    COMP_WORDS=("${tokens[@]}" "${rest[@]}")
    COMP_CWORD=$(( COMP_CWORD + shift_n ))
    COMP_LINE="$new_line"
    COMP_POINT=$(( COMP_POINT + delta ))

    if ! complete -p "$target" &>/dev/null; then
        declare -F _completion_loader &>/dev/null \
            && _completion_loader "$target" &>/dev/null
    fi
    if declare -F _command_offset &>/dev/null; then
        _command_offset 0
    else
        # completion isn't loaded yet, fallback
        local spec
        spec=$(complete -p "$target" 2>/dev/null) || return
        if [[ "$spec" =~ -F[[:space:]]+([^[:space:]]+) ]]; then
            "${BASH_REMATCH[1]}" "$target" \
                "${COMP_WORDS[$COMP_CWORD]}" "${COMP_WORDS[$COMP_CWORD-1]}"
        fi
    fi
}

_register_alias_completions() {
    local line name target
    while IFS= read -r line; do
        line="${line#alias }"
        name="${line%%=*}"
        line="${line#*=}"
        line="${line#\'}"; line="${line%\'}"
        target="${line%% *}"
        [[ -z "$target" || "$target" == "$name" ]] && continue
        complete -F _complete_alias "$name"
    done < <(alias -p)
}

_deferred_evals=(
  'command -v uv  &>/dev/null && eval "$(uv generate-shell-completion bash)"'
  'command -v uvx &>/dev/null && eval "$(uvx --generate-shell-completion bash)"'
  'command -v activate-global-python-argcomplete &>/dev/null && eval "$(activate-global-python-argcomplete --dest=-)"'
  '[[ -z "${VTE_VERSION:-}" && -f "${HOME}/.local/share/kiro-cli/shell/bash_profile.post.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bash_profile.post.bash"'
  'shopt -oq posix || { [[ -f /usr/share/bash-completion/bash_completion ]] && builtin source /usr/share/bash-completion/bash_completion; }'
  # bash-completion ships `_cd` and `complete -F _cd -o nospace cd pushd` -- clobber em
  '_cd() { _natural_dir_complete; }; complete -o dirnames -o nosort -F _natural_dir_complete cd du rmdir pushd'
  '_register_alias_completions'
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
