
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



### nvim

Installing [vim-plug](https://github.com/junegunn/vim-plug)

```shell
$ sh -c 'curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

### bash

- [ble.sh](https://github.com/akinomyoga/ble.sh?)
- [OMP](https://ohmyposh.dev/docs/) -- zsh too 


### zsh
> Nowadays, I use bash.

Plugins are submodules; if you didn't pull with `--recurse-submodules` then you'll need to do
```shell
$ git submodule update --init --recursive
```

