export EDITOR=/usr/bin/nvim
export LANG=en_US.UTF-8
export BASH_SILENCE_DEPRECATION_WARNING=1

export QT_QPA_PLATFORMTHEME="qt5ct"
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"

# pyenv
export PATH="$HOME/.pyenv/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"

# pipenv
export PIPENV_VENV_IN_PROJECT=1 # Place the virtual environment at `.venv`.
export PIPENV_VERBOSITY=-1
export PIPENV_VENV_IN_PROJECT=true
export PIPENV_IGNORE_VIRTUALENVS=true # Always create a pipenv venv (useful when running from vim)

# cs61B
# source ~/Documents/Code/cs61b-software/adm/login

# dot file scripts
export PATH="/home/max/Documents/Code/dotfiles/scripts:${PATH}"

