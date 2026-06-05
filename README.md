# Touch-Tab

Switch apps with trackpad on macOS. Enhanced version of the original Touch-Tab (forked from [ris58h/Touch-Tab](https://github.com/ris58h/Touch-Tab)).

在 macOS 上用触控板三指轻扫快速切换应用程序。基于原版的打磨增强版。

<p align="center">
  <img src="Preferences.png" width="320" alt="Touch-Tab Preferences View">
</p>

---

## 🌟 核心功能 / Key Features

* **3-Finger Swipe / 三指切换**：Swipe left/right with 3 fingers to switch apps; hold or swipe slowly to show App Switcher. (三指左右轻扫快速切换应用，慢滑或按住呼出切换窗口)。
* **Custom Preferences / 自定义设置**：Adjust swipe sensitivity, guard delay, and velocity multiplier to achieve a smooth "flywheel" scrolling feel. (自由调节灵敏度、延迟与速度乘数，实现丝滑的“飞轮”滚动切换)。
* **Background Scroll Fix / 滚动拦截**：Swallows horizontal 3-finger swipe events to prevent background window content from scrolling. (吞除横向手势，解决切换应用时导致的后台页面滚动冲突)。
* **Launch at Login / 开机自启动**：Toggle directly from preferences (macOS 13+). (首选项一键开启开机自启)。

---

## 📦 下载与安装 / Download & Installation

1. **下载安装包 / Download**:
   * 前往 [Releases 页面](https://github.com/Shell-human/Touch-Tab/releases) 下载最新的 **`Touch-Tab.dmg`**。
   * Download the latest **`Touch-Tab.dmg`** from the [Releases page](https://github.com/Shell-human/Touch-Tab/releases).
2. **安装 / Install**:
   * 双击打开 `Touch-Tab.dmg`，将 **Touch-Tab** 拖入 **Applications** (应用程序) 文件夹中运行。
   * Open `Touch-Tab.dmg` and drag **Touch-Tab** to the **Applications** folder.
3. **系统设置 / System Settings**:
   * **辅助功能 / Accessibility**: Open `System Settings > Privacy & Security > Accessibility` and authorize **Touch-Tab**. (在系统设置的辅助功能中允许 Touch-Tab 控制电脑)。
   * **触控板设置 / Trackpad**: Open `System Settings > Trackpad > More Gestures > Swipe between full-screen apps` and **disable** it or change it to 4 fingers. (在触控板设置中，关闭“在全屏幕应用之间轻扫”或改为“四指轻扫”以防手势冲突)。

---

## 🛠 编译开发 / Compilation

```bash
chmod +x build_app.sh
./build_app.sh
```
*Compiled app and installer package will be outputted to `build/` directory.*
