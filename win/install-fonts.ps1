#!/usr/bin/env pwsh

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$stohCmd = Join-Path $scriptPath "stoh.cmd"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Font installation requires administrator privileges."
    Write-Host "Requesting elevation..."

    # Re-launch as administrator
    $arguments = "& '$stohCmd' install fonts -f"
    Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-Command", $arguments
    exit
}

& $stohCmd install fonts -f
