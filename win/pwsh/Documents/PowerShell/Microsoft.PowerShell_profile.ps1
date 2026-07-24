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
        $inject = "        `$Arguments = @('--config', '$ompTheme') + `$Arguments"
        # Trim the load-time `secondary` spawn -> static continuation prompt.
        $esc = [char]27
        $static = '    Set-PSReadLineOption -ContinuationPrompt ("' + $esc + '[38;2;97;175;239m>> ' + $esc + '[0m")'
        $lines = $lines | ForEach-Object {
            if     ($_ -match 'Set-PSReadLineOption -ContinuationPrompt.*Invoke-Utf8Posh.*secondary') { $static }
            elseif ($_ -match '^\s*param\(\[string\[\]\]\$Arguments = @\(\)\)') { $_; $inject }
            else   { $_ }
        }
        $lines | Out-File -FilePath $ompCache -Encoding utf8
    }
    . $ompCache
}

Set-PSReadLineOption -EditMode Emacs                       # bindkey -e
Set-PSReadLineOption -HistoryNoDuplicates                  # HIST_IGNORE_ALL_DUPS
Set-PSReadLineOption -MaximumHistoryCount 100000           # HISTSIZE
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally   # INC_APPEND_HISTORY / histappend
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
# no as-you-type prediction popup; history recall is on-demand via up/down below.
# guarded because it throws when output is redirected (scripts/CI).
try { Set-PSReadLineOption -PredictionSource None } catch {}

# up/down = substring history search (zsh history-substring-search)
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
# ctrl+backspace / ctrl+arrows = word ops (^H backward-kill-word, Ctrl+Left/Right)
Set-PSReadLineKeyHandler -Key Ctrl+Backspace  -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow  -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
# ctrl+n = cd .. (zsh cd-up-widget)
Set-PSReadLineKeyHandler -Key Ctrl+n -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert('cd ..')
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

# --- fzf: on-demand only (spawns on keypress, never at startup) ---
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    # ctrl+r = fuzzy history (honors your FZF_CTRL_R_OPTS: no-sort, exact, inline)
    Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
        $h = [System.Collections.ArrayList]@(Get-Content -ErrorAction SilentlyContinue (Get-PSReadLineOption).HistorySavePath)
        $h.Reverse()
        # -Unique keeps the first (most-recent) occurrence, dropping older dupes
        $pick = $h | Select-Object -Unique | fzf --no-sort --no-preview --wrap --exact --info=inline --reverse --height=40%
        if ($pick) {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($pick)
        }
    }


    # ctrl+t = fuzzy file picker, inserts the path
    Set-PSReadLineKeyHandler -Key Ctrl+t -ScriptBlock {
        $pick = fzf --reverse --height=40%
        if ($pick) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$pick") }
    }
}

# aliases
Set-Alias v    nvim
Set-Alias vim  nvim
Set-Alias c    Clear-Host
function o { Invoke-Item @args }
function q { exit }
function mk { mkdir @args }
function mkcd { param($d) New-Item -ItemType Directory -Force -Path $d | Out-Null; Set-Location $d }
function get { curl.exe -O -L @args }
function ipp { Write-Host "Your ip is:"; (Invoke-RestMethod https://api.ipify.org) }
function npp { & "C:\Program Files\Notepad++\notepad++.exe" $args }
function m { mwinit.exe -f }
function s { ssh.exe @args }

# git
'gl', 'gp', 'gcm' | ForEach-Object { Remove-Item "Alias:$_" -Force -ErrorAction SilentlyContinue }
#^free up built-in aliases we want to reuse (they're ReadOnly, hence Remove-Item -Force)
function gs   { git status @args }
function gss  { git show @args }
function gb   { git branch @args }
function ga   { git add @args }
function gaa  { git add . }
function gcm  { git commit -m @args }
function gca  { git commit --amend @args }
function gcan { git commit --amend --no-edit @args }
function gco  { git checkout @args }
function gp   { git push @args }
function gf   { git fetch @args }
function gl   { git pull @args }
function gll  { git log @args }
function glo  { git log --oneline @args }
function gd   { git diff @args }
function gyc  { git cherry-pick --continue --no-edit }
function gys  { git cherry-pick --skip }
function gya  { git cherry-pick --abort }

function vp { nvim $PROFILE }
function rp { . $PROFILE }
