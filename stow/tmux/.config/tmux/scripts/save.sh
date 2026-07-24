#!/usr/bin/env bash
# tmux2k segment: minutes since the last tmux-resurrect save.
last="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/last"
if [ -e "$last" ]; then
    printf '󰆓 %dm' $(( ($(date +%s) - $(stat -c %Y "$last")) / 60 ))
else
    printf '󰆓 --'
fi
