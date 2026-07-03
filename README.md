# MockAppleDevice 

[English](README_EN.md) | [简体中文](README.md)

`MockAppleDevice` 是一款专为 macOS 平台开发的高清、全品类苹果设备样机（Mockup）套壳工具。它允许开发者、设计师和运营人员轻松地将应用截图、系统界面等导入各种苹果硬件设备（iPhone、iPad、MacBook、Apple Watch）的实机边框中，一键渲染出具有自然圆角、精准屏幕拟合以及阴影的专业样机展示图。

<img width="684" height="482.5" alt="截屏2026-07-03 16 46 23" src="https://github.com/user-attachments/assets/24c0ba7e-88a2-480e-a81a-7b244e4dd534" />


---

## 🌟 核心特性

- **全品类 Apple 设备覆盖**：支持 iPhone、iPad、MacBook、Apple Watch 等多代硬件设备。
- **丰富的设备维度**：支持多种实机机身颜色切换，以及**横屏 (Landscape)** 与**竖屏 (Portrait)** 智能自适应。

---

## 🛠 技术栈

- **桌面客户端**：Swift 5.10+ / SwiftUI / AppKit (macOS Target)
- **自动化工具链**：Python 3 (Pillow 库) —— 用于检测屏幕边界、缩放切图、阴影合并及高精圆角裁剪。
- **打包部署**：Shell 脚本 (xcodebuild & hdiutil)

---

## 📂 项目结构说明

```text
MockAppleDevice/
├── MockAppleDevice.xcodeproj   # Xcode 主工程目录
├── MockAppleDevice/            # macOS App 主程序源文件
│   ├── Assets.xcassets/        # 静态资源与应用图标 (AppIcon)
│   ├── ContentView.swift       # 应用 UI 主框架（NavigationSplitView 分栏布局）
│   ├── ControlPanel.swift      # 右侧属性调整与批量导出控制面板
│   ├── CanvasPreview.swift     # 中间样机画布实时预览区 (支持拖拽截图导入)
│   ├── DeviceConfig.swift      # 设备配置定义及 NSImage 摆正裁剪底层扩展
│   ├── DeviceMockupView.swift  # 样机独立渲染组件（设备外壳 + 截图遮罩图层）
│   ├── ExportService.swift     # 高品质图片渲染及多图批量导出逻辑
│   ├── DeviceRepository.swift  # 设备数据存储仓库与加载管理
│   ├── MockupState.swift       # 样机配置的全局统一响应式状态模型
│   └── device_models.json      # 设备参数定义 (包含屏幕占比、圆角等数据)
├── process_assets.py           # 样机外壳素材自动下载与屏幕坐标扫描工具
├── scan_custom_devices.py      # 自定义样机扩展扫描脚本
└── build_dmg.sh                # 自动化构建 Release 版 App 并封装为 DMG 安装包的脚本
```

---

## 🚀 开发者指南

### 1. 环境准备

- **系统要求**：macOS 14.0 或更高版本
- **开发工具**：Xcode 15.0 或更高版本
- **脚本依赖**：Python 3 及 Pillow 库（如果没有，运行配套脚本时会自动安装）。

### 2. 运行与编译

1. 使用 Xcode 打开主工程 `MockAppleDevice.xcodeproj`。
2. 选择 **MockAppleDevice** Scheme，Destination 选择 **My Mac**。
3. 按下 `Cmd + R` 即可编译并在本地运行。

---

## ⚙️ 配套工具与自动化脚本

项目根目录下提供了多款高效的自动化开发/运维脚本：

### 1. 自动下载与同步设备素材
运行脚本可自动拉取最新的设备框图（来自公开设备框架仓），并自动扫描图像内黑色像素块来**反推屏幕的位置与尺寸比率**，将坐标合并写入 `Assets` 目录。
```bash
python3 process_assets.py
```

### 2. 一键编译并打包为 `.dmg` 分发包
执行以下脚本，它将自动清理旧编译缓存，调用 `xcodebuild` 编译 Release 版本，创建 Applications 快捷方式链接，并使用 `hdiutil` 封装生成极客风格的只读压缩磁盘映像：
```bash
./build_dmg.sh
```
打包成功后，可在根目录下的 `ipa/` 目录中找到 `MockAppleDevice.dmg`。
