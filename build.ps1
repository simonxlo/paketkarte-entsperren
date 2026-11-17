#requires -Version 5.1
<#
  Builds all release files into dist/:
    - paketkarte-entsperren-chrome-<version>.zip   (Chrome Web Store, Edge, Vivaldi, Brave)
    - paketkarte-entsperren-firefox-<version>.zip  (addons.mozilla.org)
    - paketkarte-entsperren.user.js                (Greasy Fork, Tampermonkey, Violentmonkey)

  Runs on Windows PowerShell 5.1 and PowerShell 7 (GitHub Actions).
  Usage:  ./build.ps1
#>
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$dist = Join-Path $root 'dist'
$utf8 = New-Object System.Text.UTF8Encoding $false
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

function Read-Text([string]$rel) { [System.IO.File]::ReadAllText((Join-Path $root $rel), $utf8) }

$chrome  = Read-Text 'manifests/chrome.json'  | ConvertFrom-Json
$firefox = Read-Text 'manifests/firefox.json' | ConvertFrom-Json
if ($chrome.version -ne $firefox.version) {
  throw "Version mismatch: chrome.json has $($chrome.version), firefox.json has $($firefox.version)"
}
$version = $chrome.version
Write-Host "Building version $version"

if (Test-Path $dist) { Remove-Item $dist -Recurse -Force -Confirm:$false }
New-Item -ItemType Directory $dist | Out-Null

function New-ExtensionZip([string]$manifest, [string]$zipName) {
  $zipPath = Join-Path $dist $zipName
  $entries = @(
    @{ Src = Join-Path $root "manifests/$manifest"; Name = 'manifest.json' },
    @{ Src = Join-Path $root 'src/unlock.js';       Name = 'unlock.js' }
  )
  Get-ChildItem (Join-Path $root 'icons') -Filter '*.png' | Sort-Object Name | ForEach-Object {
    $entries += @{ Src = $_.FullName; Name = "icons/$($_.Name)" }
  }
  $zip = [System.IO.Compression.ZipFile]::Open($zipPath, 'Create')
  try {
    foreach ($e in $entries) {
      [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $e.Src, $e.Name) | Out-Null
    }
  } finally { $zip.Dispose() }
  Write-Host "  OK  $zipName"
}

New-ExtensionZip 'chrome.json'  "paketkarte-entsperren-chrome-$version.zip"
New-ExtensionZip 'firefox.json' "paketkarte-entsperren-firefox-$version.zip"

$header = (Read-Text 'src/userscript-header.js').Replace('{{VERSION}}', $version)
$userscript = ($header + (Read-Text 'src/unlock.js')).Replace("`r`n", "`n")
[System.IO.File]::WriteAllText((Join-Path $dist 'paketkarte-entsperren.user.js'), $userscript, $utf8)
Write-Host "  OK  paketkarte-entsperren.user.js"
Write-Host "Done -> $dist"
