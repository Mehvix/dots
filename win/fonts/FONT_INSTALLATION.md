# Font Installation Feature for stoh

## Summary

Extended the `stoh` (Windows config tracker) to support automatic font installation from tracked font files in the dotfiles repository.

## Changes Made

### 1. Extended stoh.py Core

**New capabilities:**
- Added `fonts = true` directive in `.stoh` manifests
- Windows API integration via ctypes for font registration
- Special font installation mode that:
  - Copies fonts to `C:\Windows\Fonts`
  - Registers them with Windows using `AddFontResource`
  - Broadcasts `WM_FONTCHANGE` to notify all applications
  - Checks for existing installations to avoid duplicates

**Modified functions:**
- `parse_manifest()` - Added `fonts` directive parsing
- `cmd_install()` - Added font installation branch
- `cmd_status()` - Shows font installation status
- `cmd_list()` - Displays fonts packages with (fonts) tag
- Added `Mapping.fonts_mode` field to track font packages

**New functions:**
- `is_font_file()` - Detect font files by extension (.ttf, .otf, .ttc, .woff, .woff2)
- `get_windows_fonts_dir()` - Returns Windows Fonts directory path
- `install_font_windows()` - Install and register a font file
- `uninstall_font_windows()` - Uninstall and unregister a font file

### 2. Created fonts Package

**Location:** `win/fonts/`

**Manifest (`.stoh`):**
```
source = ../../stow/fonts/.local/share/fonts
fonts = true
```

This maps the Linux-style font directory structure to Windows font installation.

### 3. Helper Script for Elevation

**File:** `win/install-fonts.ps1`

PowerShell script that:
- Checks if running as administrator
- Automatically requests elevation if needed
- Executes font installation with proper privileges

### 4. Updated Documentation

**win/README.md:**
- Added section 5 documenting `fonts = true` directive
- Explained admin privilege requirement
- Provided usage examples

## Usage

### List fonts to be installed
```powershell
cd win
.\stoh.cmd status fonts
```

### Dry run (preview)
```powershell
.\stoh.cmd install fonts -n
```

### Install fonts (with automatic elevation)
```powershell
.\install-fonts.ps1
```

### Install fonts (manual, requires admin terminal)
```powershell
.\stoh.cmd install fonts -f
```

### Include fonts in full setup
```powershell
# As administrator
.\stoh.cmd install --all
```

## Font Detection Status

**33 fonts tracked** in `stow/fonts/.local/share/fonts/`:
- PT Sans family (4 fonts)
- PT Mono + Nerd Font variant (2 fonts)
- Hip Pocket family (13 fonts)
- Cormorant Unicase family (5 fonts)
- Various display/decorative fonts (9 fonts)

All fonts are currently detected as `[missing]` and ready to install.

## Technical Details

### Why Not Symlinks?

Windows font installation requires:
1. Physical files in `C:\Windows\Fonts`
2. Registry entries or API registration
3. Administrator privileges

Symlinks don't work for fonts - they must be copied and registered via Windows API.

### Font Registration API

Uses Windows GDI32.dll functions:
- `AddFontResourceW()` - Register font file
- `RemoveFontResourceW()` - Unregister font file

Plus User32.dll for notification:
- `SendMessageW(HWND_BROADCAST, WM_FONTCHANGE, 0, 0)` - Notify all windows

### Permission Handling

Font installation requires admin rights because:
- `C:\Windows\Fonts` is a system directory
- Font registration modifies system state
- Registry entries (in some cases) require elevation

The `install-fonts.ps1` script handles elevation automatically via PowerShell's `-Verb RunAs`.

## Integration with Existing Workflow

Fonts work seamlessly with stoh's existing model:
- **Source:** Shared with Linux (`stow/fonts/.local/share/fonts/`)
- **Package:** Windows-specific manifest (`win/fonts/.stoh`)
- **Install:** Same command structure (`stoh.cmd install fonts`)
- **Status:** Standard status checking (`stoh.cmd status fonts`)
- **List:** Appears in package listing (`stoh.cmd list`)

This maintains consistency while handling Windows font installation's special requirements.
