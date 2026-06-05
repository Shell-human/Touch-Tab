# Touch-Tab

Switch apps with trackpad on macOS. This is an enhanced and polished version of the original Touch-Tab app (forked from [ris58h/Touch-Tab](https://github.com/ris58h/Touch-Tab)).

在 macOS 上用触控板三指轻扫快速切换应用程序。此版本为精心打磨后的增强版（Fork 自 [ris58h/Touch-Tab](https://github.com/ris58h/Touch-Tab) 原版项目）。

<p align="center">
  <img src="Preferences.png" width="350" alt="Touch-Tab Preferences View">
</p>

---

## 中文介绍

### 🌟 核心功能
* **三指轻扫切换 App**：在触控板上使用三个手指左右轻扫，即可在活跃应用之间快速切换。轻扫后按住或慢速滑动将呼出系统的 App 切换器 UI（Command+Tab 窗口）。
* **首选项设置面板**：点击状态栏图标选择 `Preferences...` 开启配置窗口，支持：
  * **滑动灵敏度 (Swipe Sensitivity)**：微调手势触发门槛（默认 `0.035`），防止触控板误触或让滑动反馈更加敏锐。
  * **切换延迟 (Switching Delay)**：设置连续切换之间的保护延迟（默认 `125 ms`），使切换平顺受控，也可设为 `0 ms` 体验完全无延迟极速响应。
  * **速度乘数 (Velocity Multiplier)**：放大你快速滑动时的手势位移速度（默认 `1.0x`，最高支持 `10.0x`），让你在快滑时能连续跳过多个 App。
  * **一键恢复默认 (Reset to Defaults)**：一键将所有参数重置回最佳默认值。
  * **开机自启动 (Launch at Login)**：一键开启开机自启动开关。

---

## English Introduction

### 🌟 Key Features
* **3-Finger Swipe Switching**: Swipe left or right with 3 fingers to switch between active apps. Hold after a swipe or swipe slowly to bring up the macOS system App Switcher UI.
* **Unified Preferences Panel**: Tap the menu bar icon and select `Preferences...` to access customization sliders:
  * **Swipe Sensitivity**: Fine-tune the distance threshold (default: `0.035`) to avoid accidental triggers or to make the gestures more sensitive.
  * **Switching Delay**: Add a guard delay between consecutive switches (default: `125 ms`) for smoother controls, or set it to `0 ms` for instant response.
  * **Velocity Multiplier**: Amplify finger velocity (default: `1.0x`, up to `10.0x`) during fast swipes, allowing you to skip multiple apps.
  * **Reset to Defaults**: Instantly restore all settings to their default values.
  * **Launch at Login**: Toggle start-on-boot directly from the Preferences panel.

---

## 安装与配置 / Installation & Setup

1. **下载或编译项目 / Download & Compile**:
   * 你可以使用项目根目录下的 `./build_app.sh` 脚本在终端一键编译，编译后的 `Touch-Tab.app` 将在 `build` 目录中生成。
   * Move `Touch-Tab.app` to your `/Applications` (应用程序) folder.

2. **授予辅助功能权限 / Grant Accessibility Permissions**:
   * macOS 需要开启控制权限来监听手势并模拟键盘事件。
   * Open `System Settings > Privacy & Security > Accessibility` (系统设置 > 隐私与安全 > 辅助功能).
   * Enable/Authorize **Touch-Tab**. If updating, we recommend removing Touch-Tab from the list first (click `-`) and adding it again (click `+`).

3. **禁用系统 3 指滑动冲突 / Resolve System Gesture Conflict**:
   * 系统默认 of the 3 指全屏滑动会拦截 Touch-Tab 的事件，需要进行微调。
   * Open `System Settings > Trackpad > More Gestures > Swipe between full-screen apps` (系统设置 > 触控板 > 更多手势 > 在全屏幕应用之间轻扫).
   * **Disable** the option or change it to **4-finger swipe** (用四个手指轻扫).

---

## 编译运行 / Compilation & Packaging

Make the build script executable and run it to compile and package the app bundle:
```bash
chmod +x build_app.sh
./build_app.sh
```
The packaged app bundle will be located at `build/Touch-Tab.app`.
