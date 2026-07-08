function npp { & "C:\Program Files\Notepad++\notepad++.exe" $args }
function m { mwinit.exe -f }

# --- oh-my-posh: cached + trimmed init ---
# oh-my-posh renders by spawning its 20MB binary, and process creation is slow
# on this box (EDR scans every launch, ~350ms each). We cache the generated init
# script and dot-source it; on regen we also strip the one spawn oh-my-posh makes
# at load time just to style the *continuation* prompt (the rare multi-line `>>`
# case), replacing it with a static string.
# The cache regenerates (and re-trims) whenever the exe or theme changes.
$ompCache = "$env:LOCALAPPDATA\omp_init.ps1"
$ompTheme = "$HOME\dots\stow\omp\.config\omp\theme.json"
$ompExe   = (Get-Command oh-my-posh -ErrorAction SilentlyContinue).Source
if ($ompExe) {
    $stale = -not (Test-Path $ompCache) -or
             (Get-Item $ompExe).LastWriteTime   -gt (Get-Item $ompCache).LastWriteTime -or
             (Get-Item $ompTheme).LastWriteTime -gt (Get-Item $ompCache).LastWriteTime
    if ($stale) {
        $lines = & $ompExe init pwsh --config $ompTheme --print
        # Trim the load-time `secondary` spawn -> static continuation prompt.
        $esc = [char]27
        $static = '    Set-PSReadLineOption -ContinuationPrompt ("' + $esc + '[38;2;97;175;239m>> ' + $esc + '[0m")'
        $lines = $lines | ForEach-Object {
            if ($_ -match 'Set-PSReadLineOption -ContinuationPrompt.*Invoke-Utf8Posh.*secondary') { $static } else { $_ }
        }
        $lines | Out-File -FilePath $ompCache -Encoding utf8
    }
    . $ompCache
}
