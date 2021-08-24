# dotfiles

## stow

I use [GNU Stow](https://www.gnu.org/software/stow/) to manage dotfiles in the `stow` directory. Examples below:

### Track `.file` in `dir` (typically `~`):
```
# mkdir program
# touch program/.file
# stow --adopt -nvt dir program  # verify command is safe and symlinks .file
# stow --adopt -vt dir program
```

### Untrack zsh files:

```
# stow -Dvt ~ zsh
```

### manual
`dconf-cinnamon.ini` is exported via ```dconf dump /org/cinnamon/ > file.ini``` and can be loaded with ```dconf load / < file.ini```
This is because `~/.config/dconf` isn't plaintext.
