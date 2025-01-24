export XDG_CONFIG_HOME="$HOME/.config"

export EDITOR=/usr/bin/nvim
export LANG=en_US.UTF-8
export LC_COLLATE="en_US.UTF-8"
export LC_CTYPE=C
export BASH_SILENCE_DEPRECATION_WARNING=1
#export PKG_CONFIG_PATH=/usr/lib/pkgconfig
export PKG_CONFIG_PATH=/usr/lib32/pkgconfig

export QT_QPA_PLATFORMTHEME="qt5ct"
export QT_SELECT=5
export PATH=/usr/local/Qt-5.15.6/bin/:$PATH

export GTK2_RC_FILES="$HOME/.gtkrc-2.0"

export DEBUGINFOD_URLS="https://debuginfod.archlinux.org"

export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1

export TESSDATA_PREFIX='/usr/share/tessdata'

# verilog
export PATH="$PATH:/usr/bin/verible-verilog-format"

# haskell
export PATH="$HOME/.cabal/bin:$HOME/.ghcup/bin:$PATH"

# go
export GOPATH=$HOME/go
export PATH="$PATH:$GOPATH/bin"

# python
# export PYTHONSTARTUP=~/.pythonrc
#export PYTHONPATH="./.pyenv/versions/3.11.0b4/lib/python3.11/site-packages:$PYTHONPATH" # https://github.com/bpython/bpython/issues/494#issuecomment-98760418
export PYTHONSTARTUP=~/.config/bpython/startup.py

## pipx
export PIPX_DEFAULT_PYTHON='python3'    # https://github.com/pypa/pipx/issues/654

## pyenv
#export PYENV_ROOT="$HOME/.pyenv"
#export PATH="$PYENV_ROOT/bin:$PATH"

## pipenv
export PIPENV_VERBOSITY=-1
export PIPENV_VENV_IN_PROJECT=1 # Place the virtual environment at `.venv`.
export PIPENV_IGNORE_VIRTUALENVS=true # Always create a pipenv venv (useful when running from vim)

# cs61B
# source ~/Documents/Code/cs61b-software/adm/login

# Personal Directories
export CODE_ROOT="${HOME}/Documents/Code"

# dot file scripts
export PATH="${CODE_ROOT}/dotfiles/scripts:${PATH}"

# npm
export PATH=~/.npm-global/bin:$PATH
#export npm_config_prefix="$HOME/.local"

# nvm 
#export NVM_LAZY=1
#export NVM_DIR="$HOME/.nvm"

append_path () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}

