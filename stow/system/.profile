#!/bin/bash

# XDG compliance
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

setxkbmap -layout us -variant colemak_dh -option caps:backspace -option grp:shift_caps_toggle &

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

# cache output to avoid fork
_ac() {
    alias "$1=$2"
    local _c="${XDG_CACHE_HOME:-$HOME/.cache}/argcomplete-$1.bash"
    [[ -f $_c ]] || register-python-argcomplete "$1" --external-argcomplete-script "$2" > "$_c" 2>/dev/null
    [[ -s $_c ]] && source "$_c"
} # e.g. `_ac foo /path/to/foo_script_here_w_argcomplete.py`, shebang say `#!/usr/bin/env -S uv run`

# defaults
export EDITOR=nvim
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_TYPE=en_US.UTF-8
export LC_COLLATE="en_US.UTF-8"
export LC_CTYPE=C
export BASH_SILENCE_DEPRECATION_WARNING=1
export PKG_CONFIG_PATH=/usr/lib32/pkgconfig
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
"

# windows-unique
if [[ "$OSTYPE" == msys || "$OSTYPE" == cygwin ]]; then
    # native OpenSSH (LibreSSL) over git-bash OpenSSL (which breaks ECDSA)
    prepend_path "/c/Windows/System32/OpenSSH"

    append_path "/c/msys64/usr/bin"
fi

# device-specific
_hostname=${HOSTNAME:-$(hostname)}
case "$_hostname" in
    max)
        alias topoff="sudo tlp fullcharge"
        alias charge="sudo tlp setcharge 65 80"

        alias fix-sound='pulseaudio --check && (pulseaudio -k || sudo killall pulseaudio)'

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

        export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
        export QT_QPA_PLATFORMTHEME="qt5ct"
        export QT_AUTO_SCREEN_SCALE_FACTOR=0
        export QT_QPA_PLATFORMTHEME="qt5ct"
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
        ;;
    wayside)
        export OMP_HOST_COLOR="#56b6c2"
        export OMP_HOST_ICON=$'󰴺'
        ;;
    etx-maxv)
        export DISPLAY=$(hostname -i):1
        export OMP_HOST_COLOR="#6f6bf8"
        export OMP_HOST_ICON=$'\ue2a6'

        _local_root="/var/tmp/$USER"
        # bootstrap once; rm /var/tmp/$USER/.bootstrapped to force refresh
        if [[ ! -f "$_local_root/.bootstrapped" ]]; then
            mkdir -p "$_local_root"/{cache,state,tmux/plugins,blesh,bin,omp}
            cp -L "$HOME/.local/bin/oh-my-posh"   "$_local_root/bin/oh-my-posh"  2>/dev/null
            cp    "$HOME/.config/omp/theme.json"  "$_local_root/omp/theme.json"  2>/dev/null
            cp -L "$HOME/.local/bin/dirlabel"     "$_local_root/bin/dirlabel"    2>/dev/null
            : > "$_local_root/.bootstrapped"
        fi
        export XDG_CACHE_HOME="$_local_root/cache" \
               XDG_STATE_HOME="$_local_root/state" \
               TMUX_PLUGIN_MANAGER_PATH="$_local_root/tmux/plugins" \
               BLESH_DIR="$_local_root/blesh" \
               OMP_THEME="$_local_root/omp/theme.json"
        prepend_path "$_local_root/bin"
        unset _local_root
        ;;
esac


# interactive shell only
if [[ $- == *i* ]]; then
    [[ -t 0 ]] && stty -ixon # if stdin: turn off ctrl+s freezing terminal (XOFF)

    # [ -z "$SSH_AUTH_SOCK" ] && eval "$(ssh-agent -s)"

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
