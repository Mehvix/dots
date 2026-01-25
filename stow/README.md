
## Track `.file` in `dir` (typically `~`):

```shell
$ mkdir program
$ touch program/.file
$ stow --adopt -nvt dir program  # verify command is safe and symlinks .file
$ stow --adopt -vt dir program
```

## Untrack zsh files:

```shell
$ stow -Dvt ~ zsh
```
