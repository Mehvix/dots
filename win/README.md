# stoh

Windows config tracker. GNU stow inspired. Copies rather than symlinks.

## Layout

```
win/
  stoh.py
  <package>/
    .stoh            # manifest
    <files...>       # mirror of subtree under target
```

## Manifest (`.stoh`)

`%VAR%`, `$VAR`, and `~` are expanded everywhere. Lines starting with `#` and
blank lines are ignored.

### 1. Shorthand — one bare line

Whole package -> target root:
```
%APPDATA%
```

### 2. Long form — `target =`

Same as shorthand, but explicit. Required if you also use `source =`:
```
target = %USERPROFILE%
```

### 3. Per-subdir mappings

Each top-level subdir of the source tree maps to its own root. Use when an
app's config is split across multiple Windows roots:
```
roaming = %APPDATA%
local   = %LOCALAPPDATA%
home    = %USERPROFILE%
```

`target =` and per-subdir mappings are mutually exclusive.

### 4. `source =` — point at a tree elsewhere in the repo

By default the package directory **is** the source tree. `source =` redirects
it, so a Windows-only `win/<pkg>/` package can install files that actually
live under `dots/stow/<pkg>/` (shared with Linux). Path is relative to the
package's `.stoh`.
```
source = ../../stow/system
target = %USERPROFILE%
```

`collect` writes back to the source tree, so changes flow into the shared
Linux config — no duplication.


## Commands

```
./stoh.py list              # show packages + targets
./stoh.py status <pkg>      # per-file: ok / differs / missing
./stoh.py install <pkg>     # copy package -> system (prompts on conflict)
./stoh.py collect <pkg>     # pull live files back into package
./stoh.py evict <pkg>       # delete gitignored files from package
```

Flags: `--all`, `-n` (dry run), `-f` (force, no prompts).


## Workflow

1. **New package:** `mkdir win/foo && echo '%APPDATA%\Foo' > win/foo/.stoh`,
   then manually copy in the files you want to track.
2. **Sync changes back from disk:** `./stoh.py collect foo`.
3. **Apply on a fresh machine:** `./stoh.py install --all`.
4. **App writes junk into a tracked tree:** add it to `.gitignore`, then
   `./stoh.py evict foo` to drop it from the package.

`collect` only refreshes files **already** in the package — new files on
disk are intentional opt-in. After tweaking an app, `git status` will show
any new artifacts; gitignore them or `git add` them.
