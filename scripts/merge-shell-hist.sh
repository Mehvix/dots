#!/usr/bin/env bash
set -euo pipefail

cp ~/.zsh_history ~/.zsh_history.bak
cat ~/.bash_history <(sed 's/^: [0-9]*:[0-9]*;//' ~/.zsh_history) \
  | awk '!seen[$0]++' \
  > ~/.shared_history
