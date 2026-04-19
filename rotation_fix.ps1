# Pocket Portrait Fix Tool v2.2.0 - Command Line
# Author: ZhiRenDaShu  https://link3.cc/zhirendashu
# License: CC BY-NC-SA 4.0 | Signature: 179689535&0814

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding            = [System.Text.Encoding]::UTF8

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$exiftool   = Join-Path $scriptDir "exiftool.exe"
$exiftoolKk = Join-Path $scriptDir "exiftool(-k).exe"

Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |  Pocket Portrait Fix Tool  v2.2.0       |" -ForegroundColor Cyan
Write-Host "  |  Author: ZhiRenDaShu  No re-encode      |" -ForegroundColor Cyan
Write-Host "  +------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $exiftool)) {
    if (Test-Path $exiftoolKk) {
        Write-Host "  [Setup] Found exiftool(-k).exe, creating exiftool.exe ..." -ForegroundColor Yellow
        Copy-Item $exiftoolKk $exiftool -Force
        Write-Host "  [Setup] Done." -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "  [ERROR] ExifTool not found." -ForegroundColor Red
        Write-Host "  Download: https://exiftool.org/" -ForegroundColor Yellow
        Write-Host "  Put exiftool(-k).exe in: $scriptDir" -ForegroundColor Cyan
        Read-Host "Press Enter to exit"; exit 1
    }
}

Get-ChildItem $scriptDir -Filter "*_exiftool_tmp" -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

$videoExts = @(".mp4",".mov",".MP4",".MOV"); $targetFiles = @()
if ($args.Count -eq 0) {
    Write-Host "  [Mode] All videos in script folder" -ForegroundColor Yellow
    $targetFiles = Get-ChildItem $scriptDir | Where-Object { $videoExts -contains $_.Extension }
} else {
    Write-Host "  [Mode] Dropped file(s)" -ForegroundColor Yellow
    foreach ($arg in $args) {
        if (Test-Path -LiteralPath $arg -PathType Container) {
            $targetFiles += Get-ChildItem -LiteralPath $arg | Where-Object { $videoExts -contains $_.Extension }
        } elseif (Test-Path -LiteralPath $arg -PathType Leaf) {
            $targetFiles += Get-Item -LiteralPath $arg
        }
    }
}
if ($targetFiles.Count -eq 0) {
    Write-Host "  [WARN] No video files found." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"; exit 0
}
Write-Host "  [Found] $($targetFiles.Count) file(s)" -ForegroundColor Green; Write-Host ""
Write-Host "  Select rotation:" -ForegroundColor White; Write-Host ""
Write-Host "    [1]  Clockwise   90  (Pocket lens faces right)"
Write-Host "    [2]  Counter     90  (Pocket lens faces left / -90)"
Write-Host "    [3]  180             (Pocket mounted upside-down)"
Write-Host ""
$choice = (Read-Host "  Enter 1 / 2 / 3").Trim()
switch ($choice) {
    "1" { $rotation=90;  $label="Clockwise 90" }
    "2" { $rotation=270; $label="Counter-clockwise 90" }
    "3" { $rotation=180; $label="180 upside-down" }
    default { Write-Host "  [ERROR] Invalid." -ForegroundColor Red; Read-Host "Press Enter"; exit 1 }
}
Write-Host ""; Write-Host "  [Selected] $label" -ForegroundColor Green
Write-Host "  ----------------------------------------"; Write-Host ""
$ok=0; $fail=0
foreach ($file in $targetFiles) {
    $path=$file.FullName
    Write-Host "[Processing] $($file.Name)" -ForegroundColor White
    $cur = (& $exiftool -S -Rotation $path 2>$null) -replace "Rotation\s*:\s*",""
    Write-Host "   Rotation: $cur  ->  $rotation"
    $r = & $exiftool -overwrite_original "-Rotation=$rotation" $path 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "   [OK]" -ForegroundColor Green; $ok++ }
    else { Write-Host "   [FAIL] $r" -ForegroundColor Red
           Write-Host "   Tip: close any app using this file." -ForegroundColor Yellow; $fail++ }
    Write-Host ""
}
Write-Host "=========================================="; Write-Host "  Done!  OK: $ok   Failed: $fail" -ForegroundColor $(if($fail -eq 0){"Green"}else{"Yellow"})
Write-Host "=========================================="; Write-Host ""
Read-Host "Press Enter to close"