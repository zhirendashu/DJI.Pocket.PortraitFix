# Pocket 竖拍修正器 v2.2.0 中文命令行版
# 作者：植人大树  https://link3.cc/zhirendashu
# 开源协议：CC BY-NC-SA 4.0 | 隐藏水印：179689535&0814

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding            = [System.Text.Encoding]::UTF8

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$exiftool   = Join-Path $scriptDir "exiftool.exe"
$exiftoolKk = Join-Path $scriptDir "exiftool(-k).exe"

Write-Host ""
Write-Host "  +--------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |    Pocket 竖拍修正器  v2.2.0  命令行版    |" -ForegroundColor Cyan
Write-Host "  |  作者：植人大树  仅修改元数据，不损画质    |" -ForegroundColor Cyan
Write-Host "  +--------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $exiftool)) {
    if (Test-Path $exiftoolKk) {
        Write-Host "  [初始化] 检测到 exiftool(-k).exe，正在生成 exiftool.exe ..." -ForegroundColor Yellow
        Copy-Item $exiftoolKk $exiftool -Force
        Write-Host "  [初始化] 完成。" -ForegroundColor Green; Write-Host ""
    } else {
        Write-Host "  [错误] 未找到 ExifTool。" -ForegroundColor Red
        Write-Host "  下载地址：https://exiftool.org/" -ForegroundColor Yellow
        Write-Host "  将 exiftool(-k).exe 放入：$scriptDir" -ForegroundColor Cyan
        Read-Host "按 Enter 退出"; exit 1
    }
}

Get-ChildItem $scriptDir -Filter "*_exiftool_tmp" -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

$videoExts = @(".mp4",".mov",".MP4",".MOV"); $targetFiles = @()
if ($args.Count -eq 0) {
    Write-Host "  [模式] 处理脚本所在目录的所有视频" -ForegroundColor Yellow
    $targetFiles = Get-ChildItem $scriptDir | Where-Object { $videoExts -contains $_.Extension }
} else {
    Write-Host "  [模式] 处理拖入的文件" -ForegroundColor Yellow
    foreach ($arg in $args) {
        if (Test-Path -LiteralPath $arg -PathType Container) {
            $targetFiles += Get-ChildItem -LiteralPath $arg | Where-Object { $videoExts -contains $_.Extension }
        } elseif (Test-Path -LiteralPath $arg -PathType Leaf) {
            $targetFiles += Get-Item -LiteralPath $arg
        }
    }
}
if ($targetFiles.Count -eq 0) {
    Write-Host "  [提示] 未找到视频文件。" -ForegroundColor Yellow
    Read-Host "按 Enter 退出"; exit 0
}
Write-Host "  [已找到] $($targetFiles.Count) 个视频文件" -ForegroundColor Green; Write-Host ""
Write-Host "  请选择旋转方向：" -ForegroundColor White; Write-Host ""
Write-Host "    [1]  右转 90°   （Pocket 竖握，镜头朝右）★ 最常用"
Write-Host "    [2]  左转 90°   （Pocket 竖握，镜头朝左 / -90°）"
Write-Host "    [3]  颠倒 180°  （Pocket 倒置拍摄）"
Write-Host ""
$choice = (Read-Host "  请输入 1 / 2 / 3 后按 Enter").Trim()
switch ($choice) {
    "1" { $rotation=90;  $label="右转 90°（顺时针）" }
    "2" { $rotation=270; $label="左转 90°（逆时针 / -90°）" }
    "3" { $rotation=180; $label="颠倒 180°" }
    default { Write-Host "  [错误] 无效输入。" -ForegroundColor Red; Read-Host "按 Enter 退出"; exit 1 }
}
Write-Host ""; Write-Host "  [已选择] $label" -ForegroundColor Green
Write-Host "  ----------------------------------------"; Write-Host ""
$ok=0; $fail=0
foreach ($file in $targetFiles) {
    $path=$file.FullName
    Write-Host "[处理中] $($file.Name)" -ForegroundColor White
    $cur = (& $exiftool -S -Rotation $path 2>$null) -replace "Rotation\s*:\s*",""
    Write-Host "   当前旋转：$cur  →  修改为：$rotation"
    $r = & $exiftool -overwrite_original "-Rotation=$rotation" $path 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "   [成功] ✓" -ForegroundColor Green; $ok++ }
    else { Write-Host "   [失败] $r" -ForegroundColor Red
           Write-Host "   提示：请关闭占用此文件的程序后重试。" -ForegroundColor Yellow; $fail++ }
    Write-Host ""
}
Write-Host "=========================================="; Write-Host "  完成！成功：$ok 个，失败：$fail 个" -ForegroundColor $(if($fail -eq 0){"Green"}else{"Yellow"})
Write-Host "=========================================="; Write-Host ""
Read-Host "按 Enter 关闭窗口"