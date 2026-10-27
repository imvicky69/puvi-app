# Puvi Split APK & Release Generation Script (PowerShell)
# Usage:
#   .\scripts\build_release.ps1 -Version "1.0.1" -BuildNumber 2
#   .\scripts\build_release.ps1 -Version "1.0.1" -BuildNumber 2 -CreateGithubRelease

param (
    [Parameter(Mandatory=$false)]
    [string]$Version = "",

    [Parameter(Mandatory=$false)]
    [int]$BuildNumber = 0,

    [switch]$CreateGithubRelease
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "         Puvi — Split APK & Release Builder (Puja & Vicky)     " -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta

# 1. Resolve Version and Build Number from pubspec.yaml if not passed
$PubspecPath = Join-Path $ProjectRoot "pubspec.yaml"
$PubspecContent = Get-Content $PubspecPath -Raw

if ([string]::IsNullOrWhiteSpace($Version)) {
    if ($PubspecContent -match "version:\s*([0-9\.]+)\+?(\d*)") {
        $Version = $Matches[1]
        if ($BuildNumber -eq 0 -and $Matches[2]) {
            $BuildNumber = [int]$Matches[2]
        }
    } else {
        $Version = "1.0.0"
        $BuildNumber = 1
    }
}

if ($BuildNumber -eq 0) {
    $BuildNumber = 1
}

Write-Host "• Target Release Version: v$Version (Build $BuildNumber)" -ForegroundColor Cyan

# 2. Update pubspec.yaml if version or build number changed
$NewVersionString = "version: $Version+$BuildNumber"
if ($PubspecContent -notmatch "version:\s*$Version\+$BuildNumber") {
    $UpdatedPubspec = $PubspecContent -replace "version:\s*[0-9\.]+\+?\d*", $NewVersionString
    Set-Content -Path $PubspecPath -Value $UpdatedPubspec
    Write-Host "✓ Updated pubspec.yaml with $NewVersionString" -ForegroundColor Green
}

# 3. Create releases output directory
$ReleaseDir = Join-Path $ProjectRoot "releases\v$Version"
if (-not (Test-Path $ReleaseDir)) {
    New-Item -ItemType Directory -Path $ReleaseDir -Force | Out-Null
}

# 4. Fetch dependencies
Write-Host "`n[1/4] Resolving Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

# 5. Build Split-per-ABI APKs
Write-Host "`n[2/4] Building Split-per-ABI APKs (arm64-v8a, armeabi-v7a, x86_64)..." -ForegroundColor Yellow
flutter build apk --split-per-abi

# 6. Build Universal Release APK
Write-Host "`n[3/4] Building Universal Release APK..." -ForegroundColor Yellow
flutter build apk

# 7. Collect and rename output APKs
Write-Host "`n[4/4] Copying and packaging releases into releases\v$Version\..." -ForegroundColor Yellow
$SourceApkDir = Join-Path $ProjectRoot "build\app\outputs\flutter-apk"

$ApkMap = @{
    "app-arm64-v8a-release.apk" = "puvi-v$Version-arm64-v8a.apk"
    "app-armeabi-v7a-release.apk" = "puvi-v$Version-armeabi-v7a.apk"
    "app-x86_64-release.apk"    = "puvi-v$Version-x86_64.apk"
    "app-release.apk"           = "puvi-v$Version-universal.apk"
}

$Checksums = @()

foreach ($src in $ApkMap.Keys) {
    $srcPath = Join-Path $SourceApkDir $src
    $dstName = $ApkMap[$src]
    $dstPath = Join-Path $ReleaseDir $dstName

    if (Test-Path $srcPath) {
        Copy-Item -Path $srcPath -Destination $dstPath -Force
        $hash = (Get-FileHash -Path $dstPath -Algorithm SHA256).Hash
        $sizeMB = ((Get-Item $dstPath).Length / 1MB).ToString("0.1")
        $Checksums += "$hash  $dstName  ($sizeMB MB)"
        Write-Host "  ✓ $dstName ($sizeMB MB)" -ForegroundColor Green
    } else {
        Write-Warning "Source APK not found: $srcPath"
    }
}

# 8. Write Checksums file
$ChecksumFile = Join-Path $ReleaseDir "checksums.txt"
$Checksums | Out-File -FilePath $ChecksumFile -Encoding UTF8
Write-Host "✓ Generated SHA256 checksums at $ChecksumFile" -ForegroundColor Cyan

# 9. Write Release Notes draft
$NotesFile = Join-Path $ReleaseDir "release_notes.md"
@"
# Puvi v$Version ($NewVersionString)

### What's New 💕
- Real-time love shower notifications and simultaneous theme melody playback.
- Alive "Send Love" hold button with +1,000 celebration overlay.
- "Next Chapter" countdown clock for monthly, half-yearly & yearly anniversaries.
- In-app auto-update checker and one-click package installer.

### Downloads
- **puvi-v$Version-arm64-v8a.apk** (Recommended for modern Android phones)
- **puvi-v$Version-armeabi-v7a.apk** (For older 32-bit Android phones)
- **puvi-v$Version-universal.apk** (Universal installer compatible with all devices)
"@ | Out-File -FilePath $NotesFile -Encoding UTF8
Write-Host "✓ Generated release notes template at $NotesFile" -ForegroundColor Cyan

# 10. Optional GitHub Release creation via gh CLI
if ($CreateGithubRelease) {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        Write-Host "`nPublishing release v$Version to GitHub (imvicky69/puvi-app)..." -ForegroundColor Yellow
        $ApkFiles = Get-ChildItem -Path $ReleaseDir -Filter "*.apk" | ForEach-Object { $_.FullName }
        gh release create "v$Version" $ApkFiles --title "Puvi v$Version 💕" --notes-file $NotesFile
        Write-Host "✓ Successfully published release to GitHub!" -ForegroundColor Green
    } else {
        Write-Warning "GitHub CLI (gh) not found on PATH. Please upload the files in $ReleaseDir manually to GitHub Releases."
    }
}

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  ✓ All split APKs generated successfully in: releases\v$Version\  " -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
