#!/usr/bin/env bash
avail=$(df -h --output=avail "$HOME" | tail -1 | tr -d ' ')
printf '󰋊 %s' "$avail"
