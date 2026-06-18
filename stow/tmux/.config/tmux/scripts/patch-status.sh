#!/bin/bash
# Patches tmux status-left/right to wrap tmux2k plugin scripts with caching.
# Run after TPM so the status strings are already set.
CACHED="$HOME/.config/tmux/scripts/cached"
TTL=15

TPM_PATH=$(tmux show-environment -g TMUX_PLUGIN_MANAGER_PATH 2>/dev/null | cut -d= -f2-)
[ -z "$TPM_PATH" ] && TPM_PATH="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins}"
TMUX2K_PLUGINS="$TPM_PATH/tmux2k/plugins"

# Link out-of-tree plugins into tmux2k's plugin dir (survives TPM updates).
[ -d "$TMUX2K_PLUGINS" ] && ln -sfn "$HOME/.config/tmux/scripts/disk.sh" "$TMUX2K_PLUGINS/disk.sh"

for side in status-right status-left; do
    val=$(tmux show -gv "$side" 2>/dev/null) || continue
    # Wrap #(/path/to/tmux2k/plugins/foo.sh) → #(cached foo 15 /path/to/tmux2k/plugins/foo.sh)
    patched=$(echo "$val" | sed -E "s|#\(([^)]*tmux2k/plugins/([a-z]+)\.sh)\)|#($CACHED \2 $TTL \1)|g")
    [ "$val" != "$patched" ] && tmux set -g "$side" "$patched"
done
