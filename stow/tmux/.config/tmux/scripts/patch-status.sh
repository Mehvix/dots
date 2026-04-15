#!/bin/bash
# Patches tmux status-left/right to wrap tmux2k plugin scripts with caching.
# Run after TPM so the status strings are already set.
CACHED="$HOME/.config/tmux/scripts/cached"
TTL=15

for side in status-right status-left; do
    val=$(tmux show -gv "$side" 2>/dev/null) || continue
    # Wrap #(/path/to/tmux2k/plugins/foo.sh) → #(cached foo 15 /path/to/tmux2k/plugins/foo.sh)
    patched=$(echo "$val" | sed -E "s|#\(([^)]*tmux2k/plugins/([a-z]+)\.sh)\)|#($CACHED \2 $TTL \1)|g")
    [ "$val" != "$patched" ] && tmux set -g "$side" "$patched"
done
