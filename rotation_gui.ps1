#Requires -Version 5.1
# Pocket 竖拍修正器 v3.1.0 - GUI 版
# Author: ZhiRenDaShu  https://link3.cc/zhirendashu
# License: CC BY-NC-SA 4.0 | Signature: 179689535&0814

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# ── 路径 ─────────────────────────────────────────────────────────────────
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$exiftool   = Join-Path $scriptDir "exiftool.exe"
$exiftoolKk = Join-Path $scriptDir "exiftool(-k).exe"
$configFile = Join-Path $scriptDir "config.ini"

# ── ExifTool 检测 ─────────────────────────────────────────────────────────
if (-not (Test-Path $exiftool)) {
    if (Test-Path $exiftoolKk) {
        Copy-Item $exiftoolKk $exiftool -Force
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "未找到 ExifTool！`n`n请前往官网下载 Windows EXE 版本：`nhttps://exiftool.org/`n`n解压后将 exiftool(-k).exe 放入本工具所在文件夹，再次运行即可自动初始化。",
            "缺少组件",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        exit 1
    }
}

# 清理残留临时文件
Get-ChildItem $scriptDir -Filter "*_exiftool_tmp" -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

# ── 读取配置 ─────────────────────────────────────────────────────────────
$lastChoice    = 1
$skipProcessed = $true
if (Test-Path $configFile) {
    try {
        $cfg = Get-Content $configFile | ConvertFrom-StringData
        if ($cfg.LastRotation)  { $lastChoice    = [int]$cfg.LastRotation }
        if ($cfg.SkipProcessed) { $skipProcessed = $cfg.SkipProcessed -eq "true" }
    } catch {}
}

# ── 全局：文件列表（动态 ArrayList） ─────────────────────────────────────
$videoExts = @(".mp4", ".mov", ".MP4", ".MOV")
$fileList  = [System.Collections.ArrayList]::new()

# ── 颜色主题 ──────────────────────────────────────────────────────────────
$C_BG      = [System.Drawing.Color]::FromArgb(24, 24, 37)
$C_BG2     = [System.Drawing.Color]::FromArgb(36, 36, 54)
$C_BG3     = [System.Drawing.Color]::FromArgb(49, 50, 68)
$C_ACCENT  = [System.Drawing.Color]::FromArgb(137, 180, 250)
$C_TEXT    = [System.Drawing.Color]::FromArgb(205, 214, 244)
$C_SUBTEXT = [System.Drawing.Color]::FromArgb(108, 112, 134)
$C_GREEN   = [System.Drawing.Color]::FromArgb(166, 227, 161)
$C_RED     = [System.Drawing.Color]::FromArgb(243, 139, 168)
$C_YELLOW  = [System.Drawing.Color]::FromArgb(249, 226, 175)
$C_SKIP    = [System.Drawing.Color]::FromArgb(127, 132, 156)

$F_NORM = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$F_BOLD = New-Object System.Drawing.Font("Microsoft YaHei UI", 9,  [System.Drawing.FontStyle]::Bold)
$F_HEAD = New-Object System.Drawing.Font("Microsoft YaHei UI", 11, [System.Drawing.FontStyle]::Bold)
$F_LOG  = New-Object System.Drawing.Font("Consolas", 8.5)

# ── 主窗口 ────────────────────────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text          = "Pocket 竖拍修正器  v3.1.0"
$form.ClientSize    = New-Object System.Drawing.Size(700, 640)
$form.MinimumSize   = New-Object System.Drawing.Size(700, 640)
$form.BackColor     = $C_BG
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Font          = $F_NORM
$form.AllowDrop     = $true   # 允许窗口级别拖放

# ── Header ────────────────────────────────────────────────────────────────
$pHead           = New-Object System.Windows.Forms.Panel
$pHead.Dock      = [System.Windows.Forms.DockStyle]::Top
$pHead.Height    = 56
$pHead.BackColor = $C_BG2

$lHead           = New-Object System.Windows.Forms.Label
$lHead.Text      = "Pocket 竖拍修正器"
$lHead.Font      = $F_HEAD
$lHead.ForeColor = $C_ACCENT
$lHead.BackColor = [System.Drawing.Color]::Transparent
$lHead.Location  = New-Object System.Drawing.Point(16, 8)
$lHead.Size      = New-Object System.Drawing.Size(500, 24)
$pHead.Controls.Add($lHead)

$lSub            = New-Object System.Windows.Forms.Label
$lSub.Text       = "v3.1.0  |  by 植人大树  |  DJI Pocket 竖拍元数据修正  · 无损画质"
$lSub.Font       = $F_NORM
$lSub.ForeColor  = $C_SUBTEXT
$lSub.BackColor  = [System.Drawing.Color]::Transparent
$lSub.Location   = New-Object System.Drawing.Point(16, 34)
$lSub.Size       = New-Object System.Drawing.Size(650, 16)
$pHead.Controls.Add($lSub)

# ── Footer ────────────────────────────────────────────────────────────────
$pFoot           = New-Object System.Windows.Forms.Panel
$pFoot.Dock      = [System.Windows.Forms.DockStyle]::Bottom
$pFoot.Height    = 58
$pFoot.BackColor = $C_BG2

$btnStart        = New-Object System.Windows.Forms.Button
$btnStart.Text   = "开始处理"
$btnStart.Size   = New-Object System.Drawing.Size(140, 36)
$btnStart.Location  = New-Object System.Drawing.Point(16, 11)
$btnStart.BackColor = $C_ACCENT
$btnStart.ForeColor = $C_BG
$btnStart.Font      = $F_BOLD
$btnStart.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnStart.FlatAppearance.BorderSize = 0
$pFoot.Controls.Add($btnStart)

$btnSave         = New-Object System.Windows.Forms.Button
$btnSave.Text    = "保存日志"
$btnSave.Size    = New-Object System.Drawing.Size(110, 36)
$btnSave.Location   = New-Object System.Drawing.Point(168, 11)
$btnSave.BackColor  = $C_BG3
$btnSave.ForeColor  = $C_TEXT
$btnSave.Font       = $F_NORM
$btnSave.FlatStyle  = [System.Windows.Forms.FlatStyle]::Flat
$btnSave.FlatAppearance.BorderColor = $C_BG3
$btnSave.FlatAppearance.BorderSize  = 1
$pFoot.Controls.Add($btnSave)

$lCopy           = New-Object System.Windows.Forms.Label
$lCopy.Text      = "© 2026 植人大树  |  CC BY-NC-SA 4.0"
$lCopy.Font      = $F_NORM
$lCopy.ForeColor = $C_SUBTEXT
$lCopy.BackColor = [System.Drawing.Color]::Transparent
$lCopy.Location  = New-Object System.Drawing.Point(420, 19)
$lCopy.Size      = New-Object System.Drawing.Size(270, 18)
$pFoot.Controls.Add($lCopy)

# ── Body ──────────────────────────────────────────────────────────────────
$pBody           = New-Object System.Windows.Forms.Panel
$pBody.Dock      = [System.Windows.Forms.DockStyle]::Fill
$pBody.BackColor = $C_BG
$pBody.AllowDrop = $true

$X = 14
$W = 670

# == 工具栏（添加文件 / 添加文件夹 / 清空列表）==
$lFiles          = New-Object System.Windows.Forms.Label
$lFiles.Text     = "待处理文件（0 个）"
$lFiles.Font     = $F_BOLD
$lFiles.ForeColor = $C_TEXT
$lFiles.BackColor = [System.Drawing.Color]::Transparent
$lFiles.Location = New-Object System.Drawing.Point($X, 12)
$lFiles.Size     = New-Object System.Drawing.Size(250, 20)
$pBody.Controls.Add($lFiles)

# 添加文件按钮
$btnAddFiles          = New-Object System.Windows.Forms.Button
$btnAddFiles.Text     = "+ 添加文件"
$btnAddFiles.Size     = New-Object System.Drawing.Size(100, 26)
$btnAddFiles.Location = New-Object System.Drawing.Point(390, 8)
$btnAddFiles.BackColor = $C_BG3
$btnAddFiles.ForeColor = $C_ACCENT
$btnAddFiles.Font      = $F_NORM
$btnAddFiles.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnAddFiles.FlatAppearance.BorderColor = $C_ACCENT
$btnAddFiles.FlatAppearance.BorderSize  = 1
$pBody.Controls.Add($btnAddFiles)

# 添加文件夹按钮
$btnAddFolder          = New-Object System.Windows.Forms.Button
$btnAddFolder.Text     = "添加文件夹"
$btnAddFolder.Size     = New-Object System.Drawing.Size(100, 26)
$btnAddFolder.Location = New-Object System.Drawing.Point(500, 8)
$btnAddFolder.BackColor = $C_BG3
$btnAddFolder.ForeColor = $C_TEXT
$btnAddFolder.Font      = $F_NORM
$btnAddFolder.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnAddFolder.FlatAppearance.BorderColor = $C_BG3
$btnAddFolder.FlatAppearance.BorderSize  = 1
$pBody.Controls.Add($btnAddFolder)

# 清空列表按钮
$btnClear          = New-Object System.Windows.Forms.Button
$btnClear.Text     = "清空"
$btnClear.Size     = New-Object System.Drawing.Size(60, 26)
$btnClear.Location = New-Object System.Drawing.Point(610, 8)
$btnClear.BackColor = $C_BG3
$btnClear.ForeColor = $C_RED
$btnClear.Font      = $F_NORM
$btnClear.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClear.FlatAppearance.BorderColor = $C_BG3
$btnClear.FlatAppearance.BorderSize  = 1
$pBody.Controls.Add($btnClear)

# == ListView ==
$lv              = New-Object System.Windows.Forms.ListView
$lv.Location     = New-Object System.Drawing.Point($X, 40)
$lv.Size         = New-Object System.Drawing.Size($W, 162)
$lv.View         = [System.Windows.Forms.View]::Details
$lv.FullRowSelect = $true
$lv.BackColor    = $C_BG2
$lv.ForeColor    = $C_TEXT
$lv.BorderStyle  = [System.Windows.Forms.BorderStyle]::None
$lv.HeaderStyle  = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable
$lv.Font         = $F_NORM
$lv.GridLines    = $false
$lv.AllowDrop    = $true    # ListView 支持拖放
$pBody.Controls.Add($lv)

$lv.Columns.Add("文件名",    340) | Out-Null
$lv.Columns.Add("当前旋转",  100) | Out-Null
$lv.Columns.Add("大小",       90) | Out-Null
$lv.Columns.Add("状态",      120) | Out-Null

# 拖放提示标签（ListView 为空时显示）
$lDrop           = New-Object System.Windows.Forms.Label
$lDrop.Text      = "将视频文件或文件夹拖到此处，或点击上方按钮选择文件"
$lDrop.Font      = $F_NORM
$lDrop.ForeColor = $C_SUBTEXT
$lDrop.BackColor = [System.Drawing.Color]::Transparent
$lDrop.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lDrop.Location  = New-Object System.Drawing.Point($X, 40)
$lDrop.Size      = New-Object System.Drawing.Size($W, 162)
$pBody.Controls.Add($lDrop)

# ── 分隔线 1 ─────────────────────────────────────────────────────────────
$sep1            = New-Object System.Windows.Forms.Panel
$sep1.Location   = New-Object System.Drawing.Point($X, 210)
$sep1.Size       = New-Object System.Drawing.Size($W, 1)
$sep1.BackColor  = $C_BG3
$pBody.Controls.Add($sep1)

# ── 旋转方向 ──────────────────────────────────────────────────────────────
$lDir            = New-Object System.Windows.Forms.Label
$lDir.Text       = "旋转方向"
$lDir.Font       = $F_BOLD
$lDir.ForeColor  = $C_TEXT
$lDir.BackColor  = [System.Drawing.Color]::Transparent
$lDir.Location   = New-Object System.Drawing.Point($X, 220)
$lDir.Size       = New-Object System.Drawing.Size(120, 20)
$pBody.Controls.Add($lDir)

$rbData = @(
    @{ Tag=1; Text="  右转 90°    顺时针  ·  Pocket 竖握镜头朝右  ( 最常用 )" },
    @{ Tag=2; Text="  左转 90°    逆时针  ·  Pocket 竖握镜头朝左  ( -90° / 270° )" },
    @{ Tag=3; Text="  颠倒 180°   上下翻转 · Pocket 倒置固定拍摄" }
)
$rbs = @()
$yy  = 244
foreach ($d in $rbData) {
    $rb           = New-Object System.Windows.Forms.RadioButton
    $rb.Text      = $d.Text
    $rb.Tag       = $d.Tag
    $rb.Font      = $F_NORM
    $rb.ForeColor = $C_TEXT
    $rb.BackColor = [System.Drawing.Color]::Transparent
    $rb.Location  = New-Object System.Drawing.Point(($X + 8), $yy)
    $rb.Size      = New-Object System.Drawing.Size(640, 24)
    $rb.Checked   = ($d.Tag -eq $lastChoice)
    $pBody.Controls.Add($rb)
    $rbs += $rb
    $yy += 27
}

# 跳过已处理
$cbSkip           = New-Object System.Windows.Forms.CheckBox
$cbSkip.Text      = "跳过已处理文件（当前 Rotation 已等于目标值时自动跳过）"
$cbSkip.Font      = $F_NORM
$cbSkip.ForeColor = $C_SUBTEXT
$cbSkip.BackColor = [System.Drawing.Color]::Transparent
$cbSkip.Checked   = $skipProcessed
$cbSkip.Location  = New-Object System.Drawing.Point(($X + 8), 328)
$cbSkip.Size      = New-Object System.Drawing.Size(640, 22)
$pBody.Controls.Add($cbSkip)

# ── 分隔线 2 ─────────────────────────────────────────────────────────────
$sep2            = New-Object System.Windows.Forms.Panel
$sep2.Location   = New-Object System.Drawing.Point($X, 358)
$sep2.Size       = New-Object System.Drawing.Size($W, 1)
$sep2.BackColor  = $C_BG3
$pBody.Controls.Add($sep2)

# ── 进度 ──────────────────────────────────────────────────────────────────
$lProg           = New-Object System.Windows.Forms.Label
$lProg.Text      = "准备就绪"
$lProg.Font      = $F_NORM
$lProg.ForeColor = $C_SUBTEXT
$lProg.BackColor = [System.Drawing.Color]::Transparent
$lProg.Location  = New-Object System.Drawing.Point($X, 367)
$lProg.Size      = New-Object System.Drawing.Size(650, 18)
$pBody.Controls.Add($lProg)

$pb              = New-Object System.Windows.Forms.ProgressBar
$pb.Location     = New-Object System.Drawing.Point($X, 390)
$pb.Size         = New-Object System.Drawing.Size($W, 10)
$pb.Minimum      = 0
$pb.Maximum      = 1
$pb.Value        = 0
$pb.Style        = [System.Windows.Forms.ProgressBarStyle]::Continuous
$pBody.Controls.Add($pb)

# ── 日志 ──────────────────────────────────────────────────────────────────
$lLog            = New-Object System.Windows.Forms.Label
$lLog.Text       = "处理日志"
$lLog.Font       = $F_BOLD
$lLog.ForeColor  = $C_TEXT
$lLog.BackColor  = [System.Drawing.Color]::Transparent
$lLog.Location   = New-Object System.Drawing.Point($X, 410)
$lLog.Size       = New-Object System.Drawing.Size(120, 18)
$pBody.Controls.Add($lLog)

$rtb             = New-Object System.Windows.Forms.RichTextBox
$rtb.Location    = New-Object System.Drawing.Point($X, 432)
$rtb.Size        = New-Object System.Drawing.Size($W, 148)
$rtb.ReadOnly    = $true
$rtb.BackColor   = $C_BG2
$rtb.ForeColor   = $C_TEXT
$rtb.Font        = $F_LOG
$rtb.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$rtb.ScrollBars  = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$pBody.Controls.Add($rtb)

# ── 添加到窗口（Bottom → Top → Fill） ────────────────────────────────────
$form.Controls.Add($pFoot)
$form.Controls.Add($pHead)
$form.Controls.Add($pBody)

# ======================================================================
# 辅助函数
# ======================================================================

# 写日志
function Add-Log {
    param([string]$msg, $color = $C_TEXT)
    $rtb.SelectionStart  = $rtb.TextLength
    $rtb.SelectionLength = 0
    $rtb.SelectionColor  = $color
    $rtb.AppendText($msg + "`n")
    $rtb.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# 刷新 ListView 和文件计数标签
function Refresh-ListView {
    $lv.Items.Clear()
    foreach ($fi in $fileList) {
        $item = New-Object System.Windows.Forms.ListViewItem($fi.Name)
        $item.SubItems.Add($fi.CurRot + "°") | Out-Null
        $item.SubItems.Add("$($fi.SizeMB) MB") | Out-Null
        $item.SubItems.Add($fi.Status) | Out-Null
        # 颜色
        switch ($fi.Status) {
            "完成"   { $item.ForeColor = $C_GREEN  }
            "失败"   { $item.ForeColor = $C_RED    }
            "已跳过" { $item.ForeColor = $C_SKIP   }
            default  { $item.ForeColor = $C_TEXT   }
        }
        $lv.Items.Add($item) | Out-Null
    }
    $lFiles.Text = "待处理文件（$($fileList.Count) 个）"
    $lDrop.Visible = ($fileList.Count -eq 0)
}

# 读取单个文件的 Rotation，返回 PSCustomObject
function Read-FileInfo {
    param([System.IO.FileInfo]$f)
    $rot = ((& $exiftool -S -Rotation $f.FullName 2>$null) -replace "Rotation\s*:\s*", "").Trim()
    if (-not $rot) { $rot = "0" }
    return [PSCustomObject]@{
        Name   = $f.Name
        Path   = $f.FullName
        SizeMB = [math]::Round($f.Length / 1MB, 1)
        CurRot = $rot
        Status = "待处理"
    }
}

# 添加文件（并去重）
function Add-Files {
    param([string[]]$paths)
    $added = 0
    foreach ($p in $paths) {
        if (Test-Path -LiteralPath $p -PathType Container) {
            $children = Get-ChildItem -LiteralPath $p |
                Where-Object { $videoExts -contains $_.Extension }
            foreach ($c in $children) {
                if (-not ($fileList | Where-Object { $_.Path -eq $c.FullName })) {
                    $null = $fileList.Add((Read-FileInfo $c))
                    $added++
                }
            }
        } elseif (Test-Path -LiteralPath $p -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($p)
            if ($videoExts -contains $ext) {
                if (-not ($fileList | Where-Object { $_.Path -eq $p })) {
                    $null = $fileList.Add((Read-FileInfo (Get-Item -LiteralPath $p)))
                    $added++
                }
            }
        }
    }
    Refresh-ListView
    if ($added -gt 0) {
        Add-Log "已添加 $added 个文件，共 $($fileList.Count) 个待处理。" $C_ACCENT
    }
}

# ======================================================================
# 事件绑定
# ======================================================================

# 添加文件按钮
$btnAddFiles.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Title            = "选择视频文件"
    $ofd.Filter           = "视频文件 (*.mp4;*.mov)|*.mp4;*.mov;*.MP4;*.MOV|所有文件 (*.*)|*.*"
    $ofd.Multiselect      = $true
    $ofd.InitialDirectory = [System.Environment]::GetFolderPath("MyVideos")
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Add-Files $ofd.FileNames
    }
})

# 添加文件夹按钮
$btnAddFolder.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "选择包含视频文件的文件夹"
    $fbd.ShowNewFolderButton = $false
    if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Add-Files @($fbd.SelectedPath)
    }
})

# 清空列表按钮
$btnClear.Add_Click({
    $fileList.Clear()
    Refresh-ListView
    $rtb.Clear()
    $pb.Value    = 0
    $pb.Maximum  = 1
    $lProg.Text  = "准备就绪"
})

# ListView 拖入事件
$lv.Add_DragEnter({
    param($s, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    } else {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::None
    }
})
$lv.Add_DragDrop({
    param($s, $e)
    $paths = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    Add-Files $paths
})

# Panel 拖入（覆盖布局其余区域）
$pBody.Add_DragEnter({
    param($s, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    } else {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::None
    }
})
$pBody.Add_DragDrop({
    param($s, $e)
    $paths = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    Add-Files $paths
})

# ── 开始处理 ──────────────────────────────────────────────────────────────
$btnStart.Add_Click({
    if ($fileList.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "请先添加视频文件。`n`n点击「+ 添加文件」或「添加文件夹」，也可直接将文件拖入列表区域。",
            "无文件", [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }

    # 获取旋转目标值
    $rotation = 90
    foreach ($rb in $rbs) {
        if ($rb.Checked) {
            switch ([int]$rb.Tag) {
                1 { $rotation = 90  }
                2 { $rotation = 270 }
                3 { $rotation = 180 }
            }
            break
        }
    }

    $doSkip           = $cbSkip.Checked
    $btnStart.Enabled = $false
    $btnSave.Enabled  = $false
    $rtb.Clear()
    $pb.Value   = 0
    $pb.Maximum = [Math]::Max(1, $fileList.Count)

    $ok = 0; $fail = 0; $skip = 0
    $total = $fileList.Count

    for ($i = 0; $i -lt $total; $i++) {
        $fi = $fileList[$i]
        $lProg.Text = "处理中：$($i+1) / $total  —  $($fi.Name)"
        $pb.Value   = $i + 1

        # 更新列表行状态
        $lv.Items[$i].SubItems[3].Text = "处理中..."
        $lv.Items[$i].ForeColor        = $C_YELLOW
        [System.Windows.Forms.Application]::DoEvents()

        # 跳过判断
        if ($doSkip -and $fi.CurRot -eq $rotation.ToString()) {
            $lv.Items[$i].SubItems[3].Text = "已跳过"
            $lv.Items[$i].ForeColor        = $C_SKIP
            $fileList[$i].Status           = "已跳过"
            Add-Log "[ - ]  $($fi.Name)   Rotation 已是 ${rotation}°，跳过" $C_SKIP
            $skip++
            continue
        }

        # 执行修改
        $result = & $exiftool -overwrite_original "-Rotation=$rotation" $fi.Path 2>&1
        if ($LASTEXITCODE -eq 0) {
            $lv.Items[$i].SubItems[3].Text = "完成"
            $lv.Items[$i].ForeColor        = $C_GREEN
            $fileList[$i].Status           = "完成"
            Add-Log "[ OK ]  $($fi.Name)   $($fi.CurRot)° -> ${rotation}°" $C_GREEN
            $ok++
        } else {
            $lv.Items[$i].SubItems[3].Text = "失败"
            $lv.Items[$i].ForeColor        = $C_RED
            $fileList[$i].Status           = "失败"
            Add-Log "[ !! ]  $($fi.Name)   $result" $C_RED
            $fail++
        }
    }

    $lProg.Text = "完成！  成功 $ok    跳过 $skip    失败 $fail"
    Add-Log "─────────────────────────────────────────" $C_SUBTEXT
    Add-Log "完成：成功 $ok   跳过 $skip   失败 $fail" $C_TEXT

    # 保存配置
    $selTag = 1
    foreach ($rb in $rbs) { if ($rb.Checked) { $selTag = $rb.Tag } }
    "LastRotation=$selTag`nSkipProcessed=$($cbSkip.Checked.ToString().ToLower())" |
        Set-Content $configFile -Encoding UTF8

    $btnStart.Enabled = $true
    $btnSave.Enabled  = $true

    if ($fail -gt 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "处理完成！`n成功 $ok 个  跳过 $skip 个  失败 $fail 个`n`n失败文件可能被其他程序占用，请关闭后重试。",
            "完成", [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    }
})

# ── 保存日志 ──────────────────────────────────────────────────────────────
$btnSave.Add_Click({
    $logDir  = Join-Path $scriptDir "处理日志"
    if (-not (Test-Path $logDir)) { New-Item $logDir -ItemType Directory -Force | Out-Null }
    $logFile = Join-Path $logDir "$(Get-Date -Format 'yyyy-MM-dd_HHmmss').txt"
    $rtb.Text | Set-Content $logFile -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show(
        "日志已保存至：`n$logFile", "保存成功",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
})

# ── 初始化：处理命令行传入的文件（拖入 bat 图标时） ──────────────────────
if ($args.Count -gt 0) {
    Add-Files $args
} else {
    Refresh-ListView
    Add-Log "欢迎使用 Pocket 竖拍修正器！" $C_ACCENT
    Add-Log "点击「+ 添加文件」或将视频文件拖入列表区域后，选择旋转方向开始处理。" $C_SUBTEXT
}

# ── 启动 ──────────────────────────────────────────────────────────────────
[System.Windows.Forms.Application]::Run($form)
