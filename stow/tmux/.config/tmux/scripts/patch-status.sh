#!/bin/bash
# Patches tmux status-left/right to wrap tmux2k plugin scripts with caching.
# Run after TPM so the status strings are already set.
CACHED="$HOME/.config/tmux/scripts/cached"
TTL=15

TPM_PATH=$(tmux show-environment -g TMUX_PLUGIN_MANAGER_PATH 2>/dev/null | cut -d= -f2-)
[ -z "$TPM_PATH" ] && TPM_PATH="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins}"
TMUX2K_PLUGINS="$TPM_PATH/tmux2k/plugins"

# Link out-of-tree plugins into tmux2k's plugin dir (survives TPM updates).
if [ -d "$TMUX2K_PLUGINS" ]; then
    ln -sfn "$HOME/.config/tmux/scripts/disk.sh" "$TMUX2K_PLUGINS/disk.sh"
    ln -sfn "$HOME/.config/tmux/scripts/save.sh" "$TMUX2K_PLUGINS/save.sh"
fi

for side in status-right status-left; do
    val=$(tmux show -gv "$side" 2>/dev/null) || continue
    # Wrap #(/path/to/tmux2k/plugins/foo.sh) → #(cached foo 15 /path/to/tmux2k/plugins/foo.sh)
    patched=$(echo "$val" | sed -E "s|#\(([^)]*tmux2k/plugins/([a-z]+)\.sh)\)|#($CACHED \2 $TTL \1)|g")
    [ "$val" != "$patched" ] && tmux set -g "$side" "$patched"
done

save_hook="#($TPM_PATH/tmux-continuum/scripts/continuum_save.sh)"
sr=$(tmux show -gv status-right 2>/dev/null)
case "$sr" in
    *continuum_save.sh*) ;;                          # already present
    *) [ -x "$TPM_PATH/tmux-continuum/scripts/continuum_save.sh" ] && \
           tmux set -g status-right "${save_hook}${sr}" ;;
esac

# Attention segment (scripts/attn)
arrow=$'\xee\x82\xb0' sep=$'\xee\x82\xb1'
sess='#be5046' save='#636363' o='#e06c75'   # session-colors dark_red, save segment bg, flag bg
pfx=$(tmux show -gv @tmux2k-prefix-highlight 2>/dev/null); pfx=${pfx:-#61afef}   # tmux2k's prefix tint
any='#{S:#{W:#{P:#{@attn}}}}'
# thin separator before every item, then strip the first so it only sits between items;
# the :window_index is dropped for single-window sessions
items="#{s/^$sep//:#{S:#{W:#{P:#{?@attn,$sep ⚑ #{session_name}#{?#{==:#{session_windows},1},,:#{window_index}} #{=24:@attn} ,}}}}}"
old="#[fg=$sess,bg=$save]#{?client_prefix,#[fg=$pfx],}$arrow"
new="#{?$any,#[fg=$sess bg=$o],#[fg=$sess bg=$save]}#{?client_prefix,#[fg=$pfx],}$arrow"
new+="#{?$any,#[fg=#2d3139 bg=$o]$items#[fg=$o bg=$save]$arrow,}"
sl=$(tmux show -gv status-left 2>/dev/null)
# tmux2k's prefix tint only swaps the session bg; also swap its text to black so it stays readable
sl=${sl//"#{?client_prefix,#[bg=$pfx],}"/"#{?client_prefix,#[bg=$pfx fg=#2d3139],}"}
case "$sl" in
    *@attn*) ;;                                     # already patched (tmux2k resets it on reload)
    *"$old"*) # + sweep job, only while the viewed pane is tinted (no shell otherwise)
              tmux set -g status-left "${sl/"$old"/"$new"}#{?@attn_done,#($HOME/.config/tmux/scripts/attn sweep #{socket_path} #{pane_id}),}"
              tmux set -g status-left-length 200 ;; # tmux2k's 100 would clip the list
esac
