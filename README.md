# PocketPortraitFix — Pocket 竖拍修正器

<p align="center">
  <img src="https://img.shields.io/badge/版本-v3.1.0-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/平台-Windows%20%7C%20macOS-lightgrey?style=flat-square" />
  <img src="https://img.shields.io/badge/画质损失-零-brightgreen?style=flat-square" />
  <img src="https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-orange?style=flat-square" />
</p>

<p align="center">
  <b>为 DJI Pocket 竖拍视频写入旋转元数据</b><br>
  让剪辑软件自动识别为竖屏 · 不重新编码 · 零画质损失 · 秒级完成
</p>

---

## 🎯 它解决什么问题？

用 **DJI Pocket 系列相机**竖握拍摄时，视频文件本身仍以横屏格式存储（如 4K 3840×2160），不带任何旋转标记。导致：

| 症状 | 原因 |
|------|------|
| 拖进 Premiere / Final Cut / 剪映后**显示为横屏** | 文件无旋转元数据 |
| 手动在软件内旋转会**降低画质** | 触发缩放插值运算 |
| 放置到 9:16 竖屏画布要**反复调整** | 每条素材都要手动旋转 |

**PocketPortraitFix** 在视频文件头部写入一个标准 `Rotation` 元数据标签，剪辑软件读到这个标签后自动识别为竖屏方向，直接适配 9:16 画布。

> ✅ 不重新编码 · ✅ 文件大小不变 · ✅ 支持批量处理 · ✅ 可撤销

---

## 🖥️ Windows 使用方法

### 方式一：图形界面（推荐新手）

```
双击 → Pocket竖拍修正器.bat
```

1. 点击 **`+ 添加文件`** 选择视频，或直接**拖入窗口**
2. 选择旋转方向（99% 情况选 **右转 90°**）
3. 点击 **`开始处理`**，等进度条完成

### 方式二：命令行（快捷，推荐熟练用户）

```
把视频文件拖到 →  旋转修复_中文版.bat  上
```

弹出终端，输入 `1` / `2` / `3` 选方向，回车完成。

---

## 🍎 macOS 使用方法

### 第一次使用前（只需设置一次）

**① 安装 ExifTool**

```bash
brew install exiftool
```

> 没有 Homebrew？先访问 [https://brew.sh](https://brew.sh) 安装。

**② 给脚本授权**

打开终端，将下面命令的路径替换为文件实际位置后执行：

```bash
chmod +x /path/to/Pocket竖拍修正器_Mac.command
```

### 之后每次使用

```
双击 → Pocket竖拍修正器_Mac.command
```

1. 弹出文件选择窗口 → 选择视频（支持多选）
2. 弹出方向选择窗口 → 选旋转方向
3. 等待终端处理完成，弹窗提示结果

> **Mac 安全提示**：首次双击如果提示"无法打开"，请右键 → 打开 → 选择"打开"，之后即可正常双击运行。

---

## 🔄 旋转方向怎么选？

| 选项 | 度数 | 适用场景 |
|------|------|----------|
| **右转 90°** ⭐ 最常用 | 90° 顺时针 | Pocket 竖握时镜头朝右 |
| **左转 90°** | 270°（-90°）| Pocket 竖握时镜头朝左 |
| **颠倒 180°** | 180° | Pocket 倒置固定拍摄 |

> 💡 不确定选哪个？先选 **右转 90°** 处理后在剪辑软件预览，方向反了再运行工具选 **左转 90°** 覆盖即可。

---

## 📁 文件清单

| 文件 | 说明 |
|------|------|
| `Pocket竖拍修正器.bat` | Windows 图形界面入口 |
| `Pocket竖拍修正器_Mac.command` | macOS 入口 |
| `旋转修复_中文版.bat` | Windows 命令行快捷版（中文） |
| `旋转修复_英文版.bat` | Windows 命令行快捷版（English） |
| `rotation_gui.ps1` | Windows GUI 核心脚本 |
| `rotation_fix_cn.ps1` | 命令行中文核心脚本 |
| `rotation_fix.ps1` | 命令行英文核心脚本 |
| `exiftool(-k).exe` | ExifTool 引擎（Win 首次运行自动初始化） |

---

## ⚙️ 系统要求

| 平台 | 要求 |
|------|------|
| Windows | Windows 10 / 11，无需额外安装 |
| macOS | 需安装 ExifTool（`brew install exiftool`） |

---

## ❓ 常见问题

**Q：处理完拖进剪辑软件还是横屏？**  
A：换另一个旋转方向再处理一次，两次处理会覆盖，不影响视频。

**Q：提示"处理失败"？**  
A：关掉正在播放这个视频的播放器或资源管理器预览窗格，重试。

**Q：Windows 双击 `.bat` 没反应？**  
A：右键 → 属性 → 勾选"解除锁定"（从网络下载的文件会被 Windows 锁定）。

**Q：Mac 报"bash: permission denied"？**  
A：在终端执行 `chmod +x 文件路径` 后再双击。

---

## 👤 作者

**植人大树**  
🔗 [https://link3.cc/zhirendashu](https://link3.cc/zhirendashu)

© 2026 植人大树 · [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)  
禁止未经授权的商业化使用 · No unauthorized commercial use
