# winget

## Refresh

Update `packages.json` to reflect current state:
```
./refresh.py        # reconcile installed set against packages.json
./refresh.py -n     # dry run: report new/removed, write nothing
./refresh.py -y     # add every new find without prompting
```

Will prompt for new entries; `.ignore` (`.gitignored`, per-machine) will be appended with any ignored entries.

## Import

```bash
winget import -i packages.json --accept-package-agreements --accept-source-agreements
```
