# winget

Tracked list of explicitly-installed Windows packages.

`packages.json` holds a curated set of `winget` package IDs — the apps
installed on purpose. Transitive dependencies and OS-bundled runtimes
(VCRedist, VCLibs, UI.Xaml, .NET runtimes, WindowsAppRuntime, AppInstaller)
are filtered out; `winget` re-pulls those automatically when installing a
real app.

## Refresh (after installing/removing apps)

```
./refresh.py        # reconcile installed set against packages.json
./refresh.py -n     # dry run: report new/removed, write nothing
./refresh.py -y     # add every new find without prompting
```

`refresh.py` reconciles what's installed against what's tracked:

* **Removed** — tracked but no longer installed → dropped from `packages.json`.
* **New** — installed but untracked → prompted per package:
  * `a` add · `i` ignore · `s` skip (this run) · `A`/`I` all · `q` quit
* **Ignored** — recorded in `.ignore` and never prompted again.

`.ignore` is a local, **git-untracked** file (one ID per line). Choosing
"ignore" for a package you don't want in the list — e.g. work apps or things
that came bundled — stops it resurfacing on every refresh. "Skip" defers the
decision to the next run.

## Restore on a fresh machine

`winget import` expects its own schema (a Sources wrapper), not our flat list,
so generate one on the fly:

```bash
uv run python -c "import json,sys; ids=json.load(open('packages.json'))['ids']; \
  json.dump({'\$schema':'https://aka.ms/winget-packages.schema.2.0.json', \
  'Sources':[{'Packages':[{'PackageIdentifier':i} for i in ids], \
  'SourceDetails':{'Name':'winget','Argument':'https://cdn.winget.microsoft.com/cache', \
  'Identifier':'Microsoft.Winget.Source_8wekyb3d8bbwe','Type':'Microsoft.PreIndexed.Package'}}]}, \
  sys.stdout)" > /tmp/import.json
winget import -i /tmp/import.json --accept-package-agreements --accept-source-agreements
```

Or install ad hoc: `winget install --id <PackageIdentifier> -e`.
