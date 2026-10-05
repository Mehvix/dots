#!/bin/bash

# XDG compliance
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# add dir to PATH if absent: append=lowest priority (default), prepend=overrides system
append_path () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}

prepend_path () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="$1${PATH:+:$PATH}"
    esac
}

# append_path "$HOME/bin"
append_path "$HOME/.local/bin"
append_path "/usr/local/bin"

append_path "$HOME/.cargo/env"


# cache output to avoid fork
_ac() {
    alias "$1=$2"
    local _c="${XDG_CACHE_HOME:-$HOME/.cache}/argcomplete-$1.bash"
    [[ -f $_c ]] || register-python-argcomplete "$1" --external-argcomplete-script "$2" > "$_c" 2>/dev/null
    [[ -s $_c ]] && source "$_c"
} # e.g. `_ac foo /path/to/foo_script_here_w_argcomplete.py`, shebang say `#!/usr/bin/env -S uv run`

# defaults
export EDITOR=nvim
# prefer en_US.UTF-8, then C.UTF-8, then plain C
_loc=$(locale -a 2>/dev/null | grep -ixm1 'en_US\.utf-\?8') \
     || _loc=$(locale -a 2>/dev/null | grep -ixm1 'C\.utf-\?8') \
     || _loc=C
export LANG="$_loc" LANGUAGE="$_loc" LC_ALL="$_loc"
unset _loc
export BASH_SILENCE_DEPRECATION_WARNING=1
# export DISPLAY=:0
export SYSTEMD_PAGER=$(command -v bat >/dev/null && echo "bat --paging=always" || echo "less")

# fzf
export FZF_DEFAULT_OPTS="
--color 16          # use term theme
--layout=reverse    # top-down results
--height 30%
--preview='bat -p --color=always {}'    # file preview with bat
"
export FZF_CTRL_R_OPTS="
--info inline       # show hits same line, not newline
--no-sort           # chronological order
--no-preview
--wrap              # wordwrap long cmds- can toggle w [ctrl|alt]+/
--exact             # exact substring match
--nth 2..           # dont match w history
--bind 'ctrl-h:backward-kill-word'      # ctrl+backspace deletes word
--bind 'esc:become(echo {q})'           # esc keeps typed query on cmdline (not orig line)
"

# alt+r: pick a command run by claude code / pi (see dots/scripts/agent-hist); prints it
_fzf_agent_hist() {
    "$HOME/dots/scripts/agent-hist" | fzf --query "$1" \
        --delimiter '\t' --with-nth 2,4 --nth 2 \
        --info inline --no-sort --exact --scheme history \
        --preview $'printf "%s\n\n" {3}; printf "%s\n" {4} | sed "s/⏎/\\n/g; s/↹/\\t/g"' \
        --preview-window 'down,40%,wrap' \
        --bind 'ctrl-h:backward-kill-word' \
        --bind 'esc:become(echo {q})' \
    | cut -f4 | sed 's/⏎/\n/g; s/↹/\t/g'
}

# windows-unique
if [[ "$OSTYPE" == msys || "$OSTYPE" == cygwin ]]; then
    # git-bash sets USERNAME but not USER; ble.sh complains otherwise
    export USER="${USER:-$USERNAME}"

    # native OpenSSH (LibreSSL) over git-bash OpenSSL (which breaks ECDSA)
    prepend_path "/c/Windows/System32/OpenSSH"
    append_path "/c/msys64/usr/bin"

fi
# WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
    alias ssh='ssh.exe'
    alias m='mwinit.exe'
fi

# device-specific
_hostname=${HOSTNAME:-$(hostname)}
case "$_hostname" in
    max)
        alias topoff="sudo tlp fullcharge"
        alias charge="sudo tlp setcharge 65 80"

        alias fix-sound='pulseaudio --check && (pulseaudio -k || sudo killall pulseaudio)'

        # keyboard: colemak-dh + capslock as backspace, shift+caps toggles layouts
        setxkbmap -layout us -variant colemak_dh \
            -option caps:backspace -option grp:shift_caps_toggle &

        alias sch="~/Documents/School/"

        alias jc='${CODE_ROOT}/JIPCAD/build/Application/Binaries/Nome3'
        alias attr="vim \${CODE_ROOT}/sites/mehvix.com/static/js/attributes.js"

        ## gitlet cs61b
        #alias gl="java -cp /home/max/Documents/Code/cs61b-akx/proj3 gitlet.Main"
        #alias glb="make -C /home/max/Documents/Code/cs61b-akx/proj3/gitlet/ default && gl"
        #alias gld="java -cp /home/max/Documents/Code/cs61b-akx/proj3 gitlet.DumpObj"
        #alias gitlet=gl

        bright() {
            xrandr --output HDMI-A-0 --brightness "$1" && xrandr --output eDP --brightness "$1"
        }

        export CODE_ROOT="${HOME}/Documents/Code"   # TODO other hosts
        export PATH="${HOME}/dots/scripts:${PATH}"  # TODO other hosts

        export DEBUGINFOD_URLS="https://debuginfod.archlinux.org"

        export PKG_CONFIG_PATH=/usr/lib32/pkgconfig

        export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
        export QT_QPA_PLATFORMTHEME="qt5ct"
        export QT_AUTO_SCREEN_SCALE_FACTOR=0
        export QT_SELECT=5
        export PATH=/usr/local/Qt-5.15.6/bin/:$PATH

        # verilog
        export PATH="$PATH:/usr/bin/verible-verilog-format"

        # haskell
        export PATH="$HOME/.cabal/bin:$HOME/.ghcup/bin:$PATH"

        # go
        export GOPATH=$HOME/go
        export PATH="$PATH:$GOPATH/bin"

        # npm
        export PATH=$HOME/.npm-global/bin:$PATH
        #export npm_config_prefix="$HOME/.local"

        # nvm
        #export NVM_LAZY=1
        #export NVM_DIR="$HOME/.nvm"

        # export TESSDATA_PREFIX='/usr/share/tessdata'

        export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
        export DOTNET_CLI_TELEMETRY_OPTOUT=1

        export OMP_HOST_COLOR="#98c379"
        export OMP_HOST_ICON=$'\uef09'

        alias code="cd \${CODE_ROOT}"
        # alias notes="cd \${CODE_ROOT}/notes/hugo/static/docs/"
        # alias sch="~/Documents/School/"
        alias dots="cd \${CODE_ROOT}/dotfiles/"
        alias www="/var/www/"
        alias comp="~/Pictures/photos-pc/Computer\ Misc/"

        alias lock="dm-tool lock"
        ;;
    houdini)
        export OMP_HOST_COLOR="#c678dd"
        export OMP_HOST_ICON=$'󱛠'
        append_path "$HOME/Android/Sdk/platform-tools"
        ;;
    wayside)
        export OMP_HOST_COLOR="#56b6c2"
        export OMP_HOST_ICON=$'󰴺'
        ;;
    etx-maxv)
        export DISPLAY=$(hostname -i):1
        export OMP_HOST_COLOR="#6f6bf8"
        export OMP_HOST_ICON=$'\ue2a6'
        ;;
esac

if command -v fnm >/dev/null; then
    export FNM_DIR="$HOME/.local/share/fnm"
    export FNM_VERSION_FILE_STRATEGY="local"
    export FNM_NODE_DIST_MIRROR="https://nodejs.org/dist"
    export FNM_COREPACK_ENABLED="false"
    export FNM_RESOLVE_ENGINES="true"
    eval "$(fnm env --use-on-cd)"
fi


# interactive shell only
if [[ $- == *i* ]]; then
    [[ -t 0 ]] && stty -ixon # if stdin: turn off ctrl+s freezing terminal (XOFF)

    # [ -z "$SSH_AUTH_SOCK" ] && eval "$(ssh-agent -s)"

    # history re-write (ADDHISTORY hook helper): when $PWD is inside $root,
    # rewrite paths under $root before they land in history. Two modes:
    #   no $3  -> ABSOLUTE: expand relative tokens resolving under $root to abs
    #            paths (foo -> /tank/proj/foo). Only fires when $PWD is in $root.
    #   $3=VAR -> ABBREVIATE: rewrite any $root occurrence to $VAR-relative
    #            paths; existing relative tokens are first resolved to absolute
    #            (needs $PWD in $root) so they abbreviate too.
    # helper, in place on $rw: when $PWD is in $1, relative tokens that resolve
    # under $1 become absolute (so the abbreviate step can fold them).
    _hist_resolve_rel() {
      local root=$1
      [[ "$PWD" == "$root" || "$PWD" == "$root"/* ]] || return 0
      [[ $rw == *$'\n'* ]] && return 0
      local tok resolved first=1 out new changed=; local -a words; read -ra words <<< "$rw"
      for tok in "${words[@]}"; do
        out=$tok
        if [[ "$tok" != /* && "$tok" != [-~\$]* && -e "$tok" ]]; then
          resolved=$(realpath -s -- "$PWD/$tok" 2>/dev/null) # -s: symlinks kept
          [[ "$resolved" == "$root" || "$resolved" == "$root"/* ]] && out=$resolved changed=1
        fi
        (( first )) && first=0 || new+=" "
        new+="$out"
      done
      [[ $changed ]] && rw=$new
      return 0
    }
    _hist_rewrite() {
      local root=$1 cmd=$2 var=$3 rw=$2
      [[ $root ]] || return 0
      _hist_resolve_rel "$root"
      # abbreviate mode: fold every absolute $root occurrence down to $VAR
      [[ $var ]] && _path_abbrev_fold "$root" "$var"
      [[ "$rw" == "$cmd" ]] && return 0
      ble/builtin/history -s -- "$rw"
      return 1
    }

    _hist_rewrite_nixos() { _hist_rewrite /etc/nixos "$1"; }
    _hist_rewrite_tank()  { _hist_rewrite /tank "$1"; }
    if [[ ${BLE_VERSION-} ]]; then
      [[ -d /etc/nixos ]] && blehook ADDHISTORY+=_hist_rewrite_nixos
      [[ -d /tank ]]      && blehook ADDHISTORY+=_hist_rewrite_tank
    fi

    # PATH_ABBREV_VARS: colon-separated var NAMES (e.g. "SOC_ROOT:QLINK_H_DIE_ROOT")
    # whose values are checkout/area roots. Commands are stored in history with
    # those roots folded to $NAME, so they replay against whatever the var points
    # at now (another checkout / tonight's run). Values are read at hook time.
    # Set the list per-site (e.g. ~/.profile_amzn); nvim's oldfiles does the same.
    # One hook for all vars (each rewriting hook adds its own history entry).
    # Longest value first, so nested roots fold to the most specific var.
    # $HOME is always an implicit root, folded to ~ (name "~"); being short, it
    # only wins for paths not under a more specific listed root.
    _path_abbrev_roots() { # -> lines "len<TAB>name<TAB>value", longest first
      local n v; local -a names
      IFS=: read -ra names <<< "${PATH_ABBREV_VARS-}"
      {
        for n in "${names[@]}"; do
          [[ $n =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]] || continue
          v=${!n-}; v=${v%/}
          [[ $v == /?* ]] && printf '%d\t%s\t%s\n' "${#v}" "$n" "$v"
        done
        v=${HOME%/}
        [[ $v == /?* ]] && printf '%d\t~\t%s\n' "${#v}" "$v"
      } | sort -t$'\t' -k1,1nr
    }
    # true if the end of $1 sits inside a '...' string ($VAR wouldn't expand
    # there); with $2=any, inside "..." too (~ expands in neither)
    _in_squote() {
      local s=$1 i c q=
      for ((i = 0; i < ${#s}; i++)); do
        c=${s:i:1}
        case $q$c in
          (\\) ((i++)) ;;                    # escape outside quotes
          ("'") q=s ;; ("s'") q= ;;
          ('"') q=d ;; ('d"') q= ;; ('d\') ((i++)) ;;
        esac
      done
      [[ $q == s || ( $2 == any && $q ) ]]
    }
    # fold $root -> $var in $rw, only at path boundaries: preceded by start /
    # space / quote / = / : / ( and followed by end / "/" / space / quote / : ; )
    # (so root /p/a leaves /p/ab and /x/p/a alone), and never inside '...'.
    # var "~" folds to a bare ~, which bash only expands unquoted at a word start
    # or right after an assignment's NAME=, so it gets those stricter rules.
    _path_abbrev_fold() {
      local root=$1 var=$2 out= rest=$rw pre ok
      while [[ $rest == *"$root"* ]]; do
        pre=${rest%%"$root"*}; rest=${rest#*"$root"}
        if [[ $var == '~' ]]; then
          [[ ( -z $out$pre || $out$pre == *[[:space:]\(\;\|\&] ||
               $out$pre =~ (^|[[:space:]])[_a-zA-Z][_a-zA-Z0-9]*=$ ) &&
             ( -z $rest || $rest == [/[:space:]\;\)\|\&]* ) ]] &&
            ! _in_squote "$out$pre" any
        else
          [[ ( -z $out$pre || $out$pre == *[[:space:]\"=:\(] ) &&
             ( -z $rest || $rest == [/[:space:]\'\":\;\)]* ) ]] &&
            ! _in_squote "$out$pre"
        fi
        ok=$?
        if ((ok == 0)); then
          [[ $var == '~' ]] && out+=$pre'~' || out+=$pre\$$var
        else
          out+=$pre$root
        fi
      done
      rw=$out$rest
    }
    _hist_rewrite_abbrev() {
      local rw=$1 len name root
      while IFS=$'\t' read -r len name root; do
        _hist_resolve_rel "$root"
        _path_abbrev_fold "$root" "$name"
      done < <(_path_abbrev_roots)
      [[ $rw == "$1" ]] && return 0
      ble/builtin/history -s -- "$rw"
      return 1
    }
    [[ ${BLE_VERSION-} ]] && blehook ADDHISTORY+=_hist_rewrite_abbrev

    source $HOME/.aliases
    [ -f $HOME/.secrets ] && source $HOME/.secrets
    [ -f $HOME/.profile_amzn ] && source $HOME/.profile_amzn

    # auto-source .env
    if [ -f .env ]; then
        set -a
        source .env
        set +a
    fi

    # colors
    export CLICOLOR=1
    export LSCOLORS=ExFxBxDxCxegedabagacad
    # export TERM=xterm-256color # overkill
    # [[ -z "$TMUX" && -z "$STY" ]] && export TERM=xterm-256color

    d=$HOME/.dircolors
    test -r "$d" && eval "$(dircolors "$d")"

fi
