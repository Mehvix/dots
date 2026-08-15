# Font Installation Quick Reference

## Check what fonts need to be installed
```powershell
.\stoh.cmd status fonts
```

## Preview font installation (dry run)
```powershell
.\stoh.cmd install fonts -n
```

## Install fonts (recommended - auto-elevates)
```powershell
.\install-fonts.ps1
```

## Install fonts (manual - requires admin PowerShell)
```powershell
# Run PowerShell as Administrator first
.\stoh.cmd install fonts -f
```

## Include in full system setup
```powershell
# Run as Administrator
.\stoh.cmd install --all
```

## Fonts Location
- **Source:** `../stow/fonts/.local/share/fonts/` (33 fonts tracked)
- **Target:** `C:\Windows\Fonts`
- **Manifest:** `win/fonts/.stoh`

## Important Notes
- Requires Administrator privileges (fonts are system-wide)
- Fonts are copied to Windows Fonts directory (not symlinked)
- Automatically registered with Windows via AddFontResource API
- Already-installed fonts are skipped automatically
- Use `install-fonts.ps1` for automatic elevation
