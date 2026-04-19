#!/bin/bash
# Pocket 竖拍修正器 Mac v1.0.0
# Author: ZhiRenDaShu  https://link3.cc/zhirendashu
# License: CC BY-NC-SA 4.0 | Signature: 179689535&0814
#
# 首次使用：在终端执行一次  chmod +x "Pocket竖拍修正器_Mac.command"
# 之后直接双击此文件即可运行

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/处理日志"

echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   Pocket 竖拍修正器  Mac v1.0.0          ║"
echo "  ║   by 植人大树  |  无损修改元数据          ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

# ── 检测 ExifTool ──────────────────────────────────────────────────────────
EXIFTOOL=""

# 优先查找脚本同目录下的 exiftool（用于免安装分发）
if [[ -f "$SCRIPT_DIR/exiftool" ]]; then
    EXIFTOOL="$SCRIPT_DIR/exiftool"
elif command -v exiftool &>/dev/null; then
    EXIFTOOL="exiftool"
else
    osascript << 'APPL'
display dialog "未找到 ExifTool！

请选择以下任一方式安装：

方式一（推荐）：
打开终端，输入：
  brew install exiftool

（若未安装 Homebrew，请先访问 https://brew.sh）

方式二：
访问 https://exiftool.org
下载 macOS Package 并安装" with title "Pocket 竖拍修正器" buttons {"知道了"} default button 1 with icon stop
APPL
    echo "  [错误] 未找到 ExifTool，请安装后重试"
    echo ""
    echo "  安装命令：brew install exiftool"
    echo ""
    read -rp "  按 Enter 关闭..."
    exit 1
fi

echo "  [OK] ExifTool 已就绪：$EXIFTOOL"
echo ""

# ── 选择文件 ──────────────────────────────────────────────────────────────
osascript > /tmp/_pocket_fixer_paths.txt << 'APPL'
try
    set selectedFiles to (choose file ¬
        with prompt "选择视频文件（可多选，按住 Command 点击多个文件）" ¬
        with multiple selections allowed)
    set output to ""
    repeat with f in selectedFiles
        set output to output & POSIX path of f & linefeed
    end repeat
    return output
on error
    return ""
end try
APPL

# 读取路径列表
mapfile -t FILE_PATHS < /tmp/_pocket_fixer_paths.txt
rm -f /tmp/_pocket_fixer_paths.txt

# 过滤空行
VALID_PATHS=()
for p in "${FILE_PATHS[@]}"; do
    [[ -n "$p" && -f "$p" ]] && VALID_PATHS+=("$p")
done

if [[ ${#VALID_PATHS[@]} -eq 0 ]]; then
    echo "  未选择任何文件，退出。"
    read -rp "  按 Enter 关闭..."
    exit 0
fi

echo "  [已选择] ${#VALID_PATHS[@]} 个文件"
echo ""

# ── 选择旋转方向 ───────────────────────────────────────────────────────────
CHOICE=$(osascript << 'APPL'
choose from list {¬
    "右转 90°  —  顺时针（Pocket 竖握镜头朝右）★ 最常用", ¬
    "左转 90°  —  逆时针（Pocket 竖握镜头朝左 / -90°）", ¬
    "颠倒 180° —  上下翻转（Pocket 倒置拍摄）"} ¬
    with title "Pocket 竖拍修正器" ¬
    with prompt "请选择旋转方向：" ¬
    default items {"右转 90°  —  顺时针（Pocket 竖握镜头朝右）★ 最常用"}
APPL
)

case "$CHOICE" in
    *"右转 90°"*)  ROTATION=90;  LABEL="右转 90°（顺时针）" ;;
    *"左转 90°"*)  ROTATION=270; LABEL="左转 90°（逆时针 / 270°）" ;;
    *"颠倒 180°"*) ROTATION=180; LABEL="颠倒 180°" ;;
    *)
        echo "  已取消，退出。"
        read -rp "  按 Enter 关闭..."
        exit 0
        ;;
esac

echo "  [已选择] $LABEL"
echo "  ──────────────────────────────────────────"
echo ""

# ── 处理文件 ──────────────────────────────────────────────────────────────
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d_%H%M%S).txt"

OK=0; FAIL=0; TOTAL=${#VALID_PATHS[@]}; IDX=0

for FILEPATH in "${VALID_PATHS[@]}"; do
    ((IDX++))
    FILENAME=$(basename "$FILEPATH")
    CURRENT_ROT=$("$EXIFTOOL" -S -Rotation "$FILEPATH" 2>/dev/null | sed 's/Rotation: //')
    [[ -z "$CURRENT_ROT" ]] && CURRENT_ROT="0"

    echo "  [$IDX/$TOTAL] $FILENAME"
    echo "     当前 Rotation: ${CURRENT_ROT}°  →  修改为：${ROTATION}°"

    RESULT=$("$EXIFTOOL" -overwrite_original "-Rotation=$ROTATION" "$FILEPATH" 2>&1)
    EXIT_CODE=$?

    if [[ $EXIT_CODE -eq 0 ]]; then
        echo "     ✓ 成功"
        echo "[OK]  $FILENAME   ${CURRENT_ROT}° -> ${ROTATION}°" >> "$LOG_FILE"
        ((OK++))
    else
        echo "     ✗ 失败：$RESULT"
        echo "[!!]  $FILENAME   失败: $RESULT" >> "$LOG_FILE"
        ((FAIL++))
    fi
    echo ""
done

# ── 完成汇报 ──────────────────────────────────────────────────────────────
echo "  ══════════════════════════════════════════"
echo "  完成！  成功 $OK 个  失败 $FAIL 个"
echo "  ══════════════════════════════════════════"
echo ""
echo "  日志已保存：$LOG_FILE"
echo ""

osascript << APPL
display dialog "处理完成！

✓ 成功：$OK 个
✗ 失败：$FAIL 个

日志已保存到：处理日志 文件夹" ¬
    with title "Pocket 竖拍修正器" ¬
    buttons {"关闭"} default button 1
APPL

read -rp "  按 Enter 关闭窗口..."
