# Touch-Tab

Switch apps with trackpad on macOS. Enhanced version of the original Touch-Tab (forked from [ris58h/Touch-Tab](https://github.com/ris58h/Touch-Tab)).

在 macOS 上用触控板三指轻扫快速切换应用程序。基于原版的打磨增强版。

<p align="center">
  <img src="Preferences_v13.png" width="320" alt="Touch-Tab Preferences View">
</p>

---

## 🇨🇳 中文说明

### 🌟 核心功能
* **三指轻扫切换**：用三指水平左右轻扫快速切换应用，慢滑或按住可呼出 App 切换器窗口（App Switcher）。
* **自定义设置**：在首选项中自由调节滑动灵敏度、触发延迟与手势加速度，调配出最适合您的丝滑手势。
* **背景滚动拦截**：吞除轻扫时的滚动事件，彻底解决原版中切换应用时导致的后台窗口页面跟着滚动的烦人 Bug。
* **状态栏图标隐藏**：支持在首选项中隐藏菜单栏图标，隐藏后程序在后台静默且常驻运行。
* **开机自启动**：在首选项中一键开启/关闭开机自启。

### 📦 下载与安装

> [!IMPORTANT]
> **最低系统要求**：本版本基于 Swift 6 与 Observation 框架重构，仅支持 **macOS 14.0 (Sonoma) 及以上系统**。
> 
> **⚠️ 关键必看配置**：在运行本软件前， **必须先将系统默认的三指轻扫改掉或关闭** 。请打开 `系统设置 > 触控板 > 更多手势 > 在全屏幕应用之间轻扫`，将其 **关闭** 或改为 **“四指轻扫”** 。否则系统的三指左右手势会霸占系统权限，导致软件的三指手势失效或冲突。

1. **下载安装包**：前往 [Releases 页面](https://github.com/Shell-human/Touch-Tab/releases) 下载最新的 **`Touch-Tab.dmg`**。
2. **快速安装**：双击打开 `.dmg` 镜像，将 **Touch-Tab** 拖入 **Applications**（应用程序）文件夹中运行。
3. **系统权限配置**：
   * **辅助功能 (Accessibility)**：打开 `系统设置 > 隐私与安全性 > 辅助功能`，勾选允许 **Touch-Tab** 控制电脑。
   * **⚠️ 三指拖移 (Three Finger Drag)**：如果您在 `系统设置 > 辅助功能 > 指针控制 > 触控板选项` 中启用了“使用触控板进行拖移”并选择为 **“三指拖移”**，请 **务必将其关闭**（或改为其他非三指拖移方式）。否则，您的三指滑动会被系统优先识别为拖拽窗口或选择文本，与本软件的三指手势产生严重冲突。

### 💡 使用贴士
> [!TIP]
> **重新安装/升级注意**：如果您之前安装过 Touch-Tab，重新安装或更新版本后可能会出现手势失效的情况。请在 `系统设置 > 隐私与安全性 > 辅助功能` 的列表中，先选中老的 Touch-Tab 并点击列表下方的 **`-` (减号)** 将其移除，然后再点击 **`+` (加号)** 重新将新版 Touch-Tab 添加进来并开启授权。

> [!NOTE]
> **如何恢复菜单栏图标**：如果您在首选项中隐藏了菜单栏图标，只需在「应用程序」文件夹（或通过 Spotlight / Launchpad）**再次双击运行 Touch-Tab**，即可重新调出首选项窗口将其勾选回来。

### 🛠 编译开发
如果您想自行编译：
```bash
chmod +x build_app.sh
./build_app.sh
```
编译生成的 `.app` 包和 `.dmg` 安装盘将存放在 `build/` 目录下。

---

## 🇺🇸 English Guide

### 🌟 Key Features
* **3-Finger Swipe**: Swipe left/right with 3 fingers to switch apps; hold or swipe slowly to show the macOS App Switcher UI.
* **Custom Settings**: Adjust swipe sensitivity, trigger delay, and gesture acceleration in Preferences to achieve a smooth and personalized gesture experience.
* **Background Scroll Guard**: Swallows horizontal 3-finger swipe events, fixing the bug in the original app where background window content scrolled during app switching.
* **Hide Menu Bar Icon**: Toggle the status bar icon visibility in Preferences; if hidden, the application runs silently and persistently in the background.
* **Launch at Login**: Easily enable or disable autostart directly from the Preferences window.

### 📦 Download & Installation

> [!IMPORTANT]
> **System Requirements**: This version is built with Swift 6 and the Observation framework, supporting only **macOS 14.0 (Sonoma) or newer**.
> 
> **⚠️ Critical Configuration**: Before launching the application, you **MUST disable or change the system default 3-finger swipe gesture**. Open `System Settings > Trackpad > More Gestures > Swipe between full-screen apps`, and **disable** it or change it to **"Swipe with four fingers"**. Otherwise, the default system gesture will block Touch-Tab, causing the 3-finger swipe to fail.

1. **Download**: Go to the [Releases page](https://github.com/Shell-human/Touch-Tab/releases) and download the latest **`Touch-Tab.dmg`**.
2. **Install**: Double-click the `.dmg` file and drag **Touch-Tab** into your **Applications** folder.
3. **System Configuration**:
   * **Accessibility**: Open `System Settings > Privacy & Security > Accessibility` and authorize **Touch-Tab**.
   * **⚠️ Three Finger Drag**: If you have enabled "Use trackpad for dragging" with **"Three Finger Drag"** under `System Settings > Accessibility > Pointer Control > Trackpad Options`, you **must disable it** (or change it to another style). Otherwise, your three-finger swipes will be captured by the system for window dragging or text selection, conflicting directly with Touch-Tab.

### 💡 Useful Tips
> [!TIP]
> **Reinstallation / Upgrade Warning**: If you have previously installed Touch-Tab, you might experience issues where gestures don't work after upgrading. To fix this, go to `System Settings > Privacy & Security > Accessibility`, select the old Touch-Tab entry, click the **`-` (minus)** button to remove it completely, then click the **`+` (plus)** button to re-add the new Touch-Tab application and enable its permission.

> [!NOTE]
> **How to Restore the Menu Bar Icon**: If you hid the menu bar status icon in Preferences, simply **re-launch the Touch-Tab application** from your Applications folder (or via Spotlight / Launchpad) to reopen the Preferences window and check the toggle again.

### 🛠 Compilation
To build the application manually:
```bash
chmod +x build_app.sh
./build_app.sh
```
The compiled app bundle and DMG installer will be saved to the `build/` directory.
