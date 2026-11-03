# Copies the addon (AutoMacros.toc, every file it lists, the Media icon) from this project
# into the WoW Forever client's AddOns\AutoMacros as a plain folder, not a link: the
# CurseForge app updates AutoMacros there and, through a link, deleted project files.
# Run from the project folder:  & .\tools\sync_forever.ps1   (optionally another client folder)
param([string]$Client = "C:\Program Files (x86)\World of Warcraft\_forever_")

$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $Client "Interface\AddOns\AutoMacros"

# the files the game needs: the .toc, what it lists, the AddOn List icon
$files = @("AutoMacros.toc")
foreach ($line in Get-Content (Join-Path $project "AutoMacros.toc")) {
    $l = $line.Trim()
    if ($l -and -not $l.StartsWith("#")) { $files += $l }
}
$files += "Media\AutoMacros.tga"
foreach ($f in $files) {
    if (-not (Test-Path (Join-Path $project $f))) { throw "missing in the project: $f (nothing copied)" }
}

if (Test-Path $dest) {
    $item = Get-Item $dest -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        # a link (junction): remove the link only, never what it points to
        [IO.Directory]::Delete($dest, $false)
    } else {
        # our own plain copy (or the CurseForge app's): replace it
        Remove-Item $dest -Recurse -Force
    }
}

foreach ($f in $files) {
    $to = Join-Path $dest $f
    New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
    Copy-Item (Join-Path $project $f) $to
}
$version = (Select-String -Path (Join-Path $dest "AutoMacros.toc") -Pattern '^## Version:\s*(.+)$').Matches[0].Groups[1].Value
Write-Output ("Copied {0} files (AutoMacros {1}) to {2}" -f $files.Count, $version, $dest)
