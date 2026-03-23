#!/bin/bash

append_path () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}

# append_path "$HOME/bin"
append_path "$HOME/.local/bin"
append_path "/usr/local/bin"

# XDG compliance
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

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
export DISPLAY=:0
export DATE=$(date "+%A, %B %e  %_I:%M%P")
export SYSTEMD_PAGER=$(command -v bat >/dev/null && echo "bat --paging=always" || echo "less")

# fzf
export FZF_DEFAULT_OPTS="--color 16 --layout=reverse --height 30% --preview='bat -p --color=always {}'"
export FZF_CTRL_R_OPTS="--info inline --no-sort --no-preview --exact"

# device-specific
case "$(hostname)" in
    max)
        export DEBUGINFOD_URLS="https://debuginfod.archlinux.org"

        export CODE_ROOT="${HOME}/Documents/Code"   # TODO other hosts
        export PATH="${HOME}/dots/scripts:${PATH}"  # TODO other hosts

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
        ;;
    houdini)
        export OMP_HOST_COLOR="#c678dd"
        export OMP_HOST_ICON=$'\uef01'
        ;;
    wayside)
        export OMP_HOST_COLOR="#56b6c2"
        export OMP_HOST_ICON=$'\uf0d3a'
        ;;
    etx-maxv)
        export OMP_HOST_COLOR="#6f6bf8"
        export OMP_HOST_ICON=$'\ue2a6'
esac


# interactive shell only
if [[ $- == *i* ]]; then
    [[ -t 0 ]] && stty -ixon # if stdin: turn off ctrl+s freezing terminal
    
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

