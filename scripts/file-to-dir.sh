#!/bin/bash

for file in *; do
  [[ -f "$file" ]] || continue
  name="${file%.*}"
  read -rp "Move '$file' into '$name/'? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || continue
  mkdir -p "$name"
  mv "$file" "$name/"
done
