#!/bin/bash

[[ $- == *i* ]] || return 0

[[ -o emacs || -o vi ]] || return 0 # nixos build-time bash (ie bash --noediting) cannot run ble.sh/completions.
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
#
# Shared awk: emit a natural sort key from a line's basename, zero-padding each
# digit run to 20 places so 2 < 10 < 100. Reads TAB-separated `name<TAB>payload`;
# emits `key<TAB>payload`. With no TAB (bare path) payload defaults to the name,
# so the same program serves both the -F function and the ble.sh resort below.
_natural_sort_awk='BEGIN { FS = OFS = "\t" }
{
  name = $1; payload = (NF > 1 ? $2 : $1)
  base = name; sub(/.*\//, "", base)
  key = base; out = ""
  while (match(key, /[0-9]+/)) {
    out = out substr(key, 1, RSTART-1) sprintf("%020d", substr(key, RSTART, RLENGTH)+0)
    key = substr(key, RSTART+RLENGTH)
  }
  print out key, payload
}'
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
# NOTE: this handles the EXACT-PREFIX case (`cd foo<TAB>`) only. For ambiguous
# nested matches (`cd f/sb<TAB>` fuzzy/substr/subseq) our -F function returns
# nothing for the literal word and ble.sh falls back to its built-in source:file,
# which glob-sorts LEXICALLY and ignores -o nosort -- see _natural_path_resort.
_natural_dir_complete() {
  compopt -o filenames 2>/dev/null
  [[ ${comp_type-} ]] && comp_type=${comp_type//:menu-show-prefix:/:}
  mapfile -t COMPREPLY < <(
    compgen -d -- "${COMP_WORDS[COMP_CWORD]}" |
    awk "$_natural_sort_awk" | LC_ALL=C sort -t$'\t' -k1,1 | cut -f2-
  )
}
complete -o dirnames -o filenames -o nosort -F _natural_dir_complete cd du rmdir pushd
# fzf's deferred completion (loaded by ble-attach) hijacks cd/du/rmdir/pushd with
# _fzf_{dir,path}_completion, dropping our sort -V; re-register after it loads.
if [[ ${BLE_VERSION-} ]]; then
  # ble.sh generates path candidates without honoring -o nosort in two spots our
  # -F function can't reach: (a) the ambiguous-match fallback for cd/du/... (any
  # nested fuzzy/substr/subseq, e.g. `cd parent/sb`), which drops into ble's own
  # source:file and glob-sorts lexically; and (b) EVERY other command's path arg
  # (`ss h/9`, `cat`, `vim`, `grep x d/`), completed by ble's file source or by
  # bash-completion's _filedir -- neither of which we register. Re-sort the final
  # candidate list naturally, after generation, whenever ALL candidates are paths.
  #
  # Path-ness is read off the candidate action, not the command name, so this
  # covers arbitrary commands: ble native paths carry action file/dir/cdpath/tilde;
  # bash-completion's _filedir arrives as progcomp with :filenames: in its payload.
  # Mixed/non-path menus (kill PIDs, git subcommands, variables) keep ble's order.
  # Skipped for auto-complete (:auto:, per-keystroke) and flag words (COMPV=-*).
  #
  # Also strips :menu-show-prefix: here (same trick as _natural_dir_complete,
  # same reason) so ALL-path menus show basenames: ble's native file source
  # yields candidates as full evaluated paths (e.g. every entry under $VAR/
  # arrives as /proj/.../workspace/.../name), and .inputrc's
  # menu-complete-display-prefix=on forces the whole path into the menu, which
  # wraps unreadably. Each candidate's PREFIX_LEN already holds the dir-prefix
  # length; dropping the flag lets the menu use it. comp_type here is the
  # caller's local (dynamic scope) and is saved to _ble_complete_menu_comp
  # AFTER generate returns, so the strip persists into menu rendering.
  _natural_path_resort() {
    ((cand_count > 1)) || return 0
    [[ :$comp_type: == *:auto:* || $COMPV == -* ]] && return 0

    # Every candidate must be a filesystem path, else leave ble's order intact.
    local i pack
    for ((i = 0; i < cand_count; i++)); do
      pack=${cand_pack[i]}
      case ${pack%%:*} in
        (file|dir|cdpath|tilde) ;;
        (progcomp) [[ :${pack#*:*:} == *:filenames:* ]] || return 0 ;;
        (*) return 0 ;;
      esac
    done

    [[ ${comp_type-} ]] && comp_type=${comp_type//:menu-show-prefix/}

    local order
    order=$(
      for ((i = 0; i < cand_count; i++)); do
        printf '%s\t%s\n' "${cand_word[i]}" "$i"
      done | awk "$_natural_sort_awk" | LC_ALL=C sort -t$'\t' -k1,1 -s | cut -f2
    )
    local -a nc=() nw=() np=()
    local n=0
    while IFS= read -r i; do
      nc[n]=${cand_cand[i]}; nw[n]=${cand_word[i]}; np[n]=${cand_pack[i]}
      ((n++))
    done <<< "$order"
    cand_cand=("${nc[@]}"); cand_word=("${nw[@]}"); cand_pack=("${np[@]}")
  }
  # $VAR path completion. Both are `around` advices whose skip path sets
  # ADVICE_EXIT=1 without running the source -- ble reads that as "no
  # candidates" and falls through to the next source for the word.
  #
  # (a) dive-into-dir: for `cmd $NAME<TAB>` ble runs variable-name completion
  # first. When NAME is fully typed and names a directory, that menu is a trap
  # if sibling vars exist (NAME_ROOT...): it re-offers names forever and TAB
  # never enters the dir. Skip it so the file source completes `$NAME/` and the
  # next TAB lists the entries. Partial names (`$QLINK_H<TAB>`) still menu.
  _blesh_dollar_var_dive() {
    if ((COMP1 > 0)) && [[ ${comp_text:COMP1-1:1} == '$' ]]; then
      local n=$COMPS   # variable source's COMPS = the name after `$`
      if [[ $n =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ && ${!n+set} && -d ${!n} ]]; then
        ADVICE_EXIT=1
        return 0
      fi
    fi
    ble/function#advice/do
  }
  # (b) empty-var guard: `$TYPO` (unset var) evaluates to "", so file
  # completion lists the CWD and a second TAB replaces the `$TYPO` word with a
  # cwd file. Yield nothing instead; ble's ambiguous pass can then suggest the
  # correctly-spelled var ($QLINK_HDIE -> $QLINK_H_DIE).
  _blesh_empty_var_guard() {
    if [[ ${COMPS-} == *'$'* && -z ${COMPV[*]-} ]]; then
      ADVICE_EXIT=1
      return 0
    fi
    ble/function#advice/do
  }
  # TAB watchdog: completion functions run IN the shell, so a slow external call
  # inside one (`$(git ...)` on NFS, make -qp, a script run for argcomplete...)
  # freezes the prompt, and C-c can't help -- ble has the tty in raw mode, so it
  # is just a byte queued behind the hang. Around each candidate generation, a
  # background sleeper fires after COMPLETE_TIMEOUT secs and kills the processes
  # the completion spawned: every descendant of the shell except the subtrees of
  # background jobs that existed before TAB (`jobs -p`, snapshotted up front)
  # and the watchdog's own subtree. TERM, then KILL survivors; the completion
  # function sees empty output and returns, and the (partial) candidate list is
  # dropped so TAB just bells instead of falling back to some filename.
  # Pure-bash infinite loops (no child process) aren't covered.
  #
  # Job control is switched off for the generation (`local -` restores it):
  # otherwise a direct `cmd` in a completion function is a foreground JOB, and
  # killing it makes bash print "Terminated  cmd" over the command line. (Not
  # SIGINT/SIGPIPE to dodge that: a fg child dying of INT makes bash act as if
  # C-c hit the shell, wedging ble mid-widget; PIPE is inherited-ignored here.)
  # The watchdog launches inside $(...) so it never gets a job-table entry.
  _comp_watchdog_fire() {
    local t=$1 shell=$2 me=$BASHPID pids p; shift 2
    sleep "$t"
    pids=$(ps -e -o pid=,ppid= | awk -v root="$shell" -v skip="$me $*" '
      BEGIN { n = split(skip, s, " "); for (i = 1; i <= n; i++) ex[s[i]] = 1 }
      { par[$1] = $2 }
      END {
        for (p in par) {
          for (q = p; q in par && q > 1; q = par[q]) {
            if (q in ex) break
            if (par[q] == root) { print p; break }
          }
        }
      }')
    [[ $pids ]] || return 0
    kill -TERM $pids 2>/dev/null
    sleep 1
    for p in $pids; do kill -KILL "$p" 2>/dev/null; done
    return 0
  }
  _comp_watchdog() {
    local -; set +m
    local t=${COMPLETE_TIMEOUT:-2} wd bg ret t0
    ble/util/clock; t0=$ret   # ms; bash 4.4 has no EPOCHREALTIME, $SECONDS is too coarse
    bg=$(jobs -p)   # bash keeps the job table visible inside $(...)
    wd=$(_comp_watchdog_fire "$t" $$ $bg </dev/null &>/dev/null & echo $!)
    ble/function#advice/do
    kill "$wd" 2>/dev/null
    # elapsed, not "is wd alive": wd lingers through its TERM->KILL grace period
    ble/util/clock
    ((ret - t0 >= t * 1000)) || return 0
    ble/complete/candidates/clear
    ble/widget/.bell "complete: timed out after ${t}s (COMPLETE_TIMEOUT)"
  }
  blehook/eval-after-load complete '
    ble/function#advice around ble/complete/generate-candidates-from-opts _comp_watchdog
    builtin unset -f ble/cmdinfo/complete:cd 2>/dev/null
    builtin unset -f ble/cmdinfo/complete:pushd 2>/dev/null
    ble/function#advice after ble/complete/candidates/generate _natural_path_resort
    ble/function#advice around ble/complete/source:variable _blesh_dollar_var_dive
    ble/function#advice around ble/complete/source:file     _blesh_empty_var_guard
    ble/function#advice around ble/complete/source:argument _blesh_empty_var_guard
  '
  ble/util/import/eval-after-load integration/fzf-completion \
    'complete -o dirnames -o filenames -o nosort -F _natural_dir_complete cd du rmdir pushd'
fi


_omp_config="${OMP_THEME:-$HOME/.config/omp/theme.json}"
eval "$(oh-my-posh init bash --config "$_omp_config" --print \
        | sed -E "s#(print (primary|secondary|transient)) #\1 --config '$_omp_config' #g")"
unset _omp_config
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
    # Record the just-run command into @last_cmd (shown in the pane-border
    # format). Runs at preexec — no OSC 133;A here: the cursor is already on the
    # output row, so a mark would tag output, not the prompt (see 133;A below).
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
      # OSC 133;A (prompt-start) mark that tmux PgUp/PgDn jump between. ble.sh's
      # transient collapse rewrites past prompts from OMP's transient template on
      # every render, so the mark must live in that template to persist on the
      # `❯ cmd` scrollback line. Prepend to the value OMP installed (keeps its
      # baked-in --config); \[ \] flags the bytes non-printing for width accounting.
      bleopt prompt_ps1_final='\['$'\e]133;A\a''\]'"$bleopt_prompt_ps1_final"
    else
      # Plain bash: OMP's primary-prompt 133;A persists on its own; just track @last_cmd.
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
        # don't clobber a completion already registered on the alias name (e.x. _ac)
        complete -p "$name" &>/dev/null && continue
        complete -F _complete_alias "$name"
    done < <(alias -p)
}

_deferred_evals=(
  'command -v uv  &>/dev/null && eval "$(uv generate-shell-completion bash)"'
  'command -v uvx &>/dev/null && eval "$(uvx --generate-shell-completion bash)"'
  '[[ -z "${VTE_VERSION:-}" && -f "${HOME}/.local/share/kiro-cli/shell/bash_profile.post.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bash_profile.post.bash"'
  'shopt -oq posix || { [[ -f /usr/share/bash-completion/bash_completion ]] && builtin source /usr/share/bash-completion/bash_completion; }'
  'command -v activate-global-python-argcomplete &>/dev/null && eval "$(activate-global-python-argcomplete --dest=-)"'
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

# alt+r: agent (claude code / pi) command history
__agent_hist_widget() {
  local sel; sel=$(_fzf_agent_hist "$READLINE_LINE") || return
  READLINE_LINE=$sel READLINE_POINT=${#sel}
}
bind -x '"\er": __agent_hist_widget'
