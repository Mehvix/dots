#!/usr/bin/env bash
# Resurrect runs post-save-layout before publishing `last`, and pre-restore-all
# before reading it. Never publish/restore an empty or incomplete layout.
set -euo pipefail

valid_layout() {
    [[ -f "$1" ]] && awk -F '\t' '
        $1 == "pane" && NF >= 11 { panes++ }
        $1 == "window" && NF >= 7 { windows++ }
        $1 == "state" { state++ }
        END { exit !(panes && windows && state) }
    ' "$1"
}

mode="${1:?expected save or restore}"
case "$mode" in
    save) target="${2:?expected snapshot path}"; dir="${target%/*}" ;;
    restore) dir="${2:?expected resurrect directory}"; target="$dir/last" ;;
    *) exit 2 ;;
esac

valid_layout "$target" && exit 0

# Timestamped names sort chronologically. Prefer the most recent valid backup,
# excluding the snapshot currently being written.
shopt -s nullglob
files=("$dir"/tmux_resurrect_*.txt)
for ((i=${#files[@]}-1; i>=0; i--)); do
    candidate="${files[i]}"
    [[ "$candidate" == "$target" ]] && continue
    valid_layout "$candidate" || continue
    case "$mode" in
        save)
            # The plugin compares this with `last` next; when identical it drops
            # the failed save instead of advancing `last` to an empty snapshot.
            cp -- "$candidate" "$target"
            ;;
        restore) ln -sfn -- "${candidate##*/}" "$target" ;;
    esac
    printf 'resurrect: rejected incomplete %s; using %s\n' "$target" "$candidate" >&2
    exit 0
done

printf 'resurrect: no valid backup available for %s\n' "$target" >&2
exit 1
