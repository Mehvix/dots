# Ultimate Performance power plan (falls back to High performance), no AC power savers.
# applies: immediate

$ultimate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
$high     = '8c5e7fda-e8bf-4a96-9a85-cf3e3a8a7e2b'

function Find-Scheme([string]$name) {
    powercfg /list | ForEach-Object {
        if ($_ -match '([0-9a-f-]{36})\s+\((.+?)\)' -and $Matches[2] -eq $name) { $Matches[1] }
    } | Select-Object -First 1
}

$guid = Find-Scheme 'Ultimate Performance'
if (-not $guid) {
    # Duplicating the hidden template is the only way to surface it; fails on Modern Standby (S0) systems.
    $out = powercfg -duplicatescheme $ultimate 2>&1
    if ($out -match '([0-9a-f-]{36})') { $guid = $Matches[1] }
}
if (-not $guid) {
    Write-Warning 'Ultimate Performance unavailable; trying High performance'
    $guid = Find-Scheme 'High performance'
    if (-not $guid) { $guid = $high }
}

powercfg -setactive $guid
if ($LASTEXITCODE) { Write-Error "could not activate $guid (power plan may be enforced by policy)"; exit 1 }

# AC only; battery behavior untouched.
powercfg -setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMIN 5   # plan defaults to 100 (always max clock); let it idle down
powercfg -setacvalueindex $guid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0  # USB selective suspend off
powercfg -setacvalueindex $guid SUB_PCIEXPRESS ASPM 0                                                          # PCIe link state PM off
powercfg -change standby-timeout-ac 0
powercfg -change hibernate-timeout-ac 0
powercfg -setactive $guid

powercfg /getactivescheme
