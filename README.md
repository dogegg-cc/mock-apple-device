# MockAppleDevice 

[English](README.md) | [简体中文](README_zh-CN.md)

`MockAppleDevice` is a high-definition, all-in-one Apple device mockup tool developed specifically for macOS. It allows developers, designers, and marketers to easily import app screenshots and system interfaces into real-device frames (iPhone, iPad, MacBook, Apple Watch), rendering professional mockups with natural rounded corners, precise screen fitting, and shadows in one click.

<img width="684" height="482.5" alt="截屏2026-07-24 22 24 15" src="https://github.com/user-attachments/assets/062d2f1c-162f-4b97-a939-4559e0e34b1e" />

<img width="684" height="482.5" alt="截屏2026-07-24 22 25 10" src="https://github.com/user-attachments/assets/c035944e-fd58-4a5e-ae93-d9201c94a254" />

<img width="684" height="482.5" alt="截屏2026-07-24 22 25 44" src="https://github.com/user-attachments/assets/702bae50-4245-4763-8b4b-51769ae623ec" />

<img width="684" height="482.5" alt="截屏2026-07-24 22 26 25" src="https://github.com/user-attachments/assets/d127906a-670f-43f3-983a-3818f1abf1fd" />

---

## Download
[Download](https://github.com/dogegg-cc/mock-apple-device/releases)

## 🌟 Core Features

- **All-in-One Apple Device Coverage**: Supports multiple generations of devices including iPhone, iPad, MacBook, and Apple Watch.
- **Rich Device Dimensions**: Supports switching between multiple real-device colors, with smart auto-adaptation for both **Landscape** and **Portrait** orientations.

---

## 🛠 Tech Stack

- **Desktop Client**: Swift 5.10+ / SwiftUI / AppKit (macOS Target)
- **Automation Toolchain**: Python 3 (with Pillow library) — Used for screen boundary detection, image scaling, shadow blending, and high-precision rounded corner cropping.
- **Build & Deployment**: Shell scripts (`xcodebuild` & `hdiutil`)

---

## 📂 Project Structure

```text
MockAppleDevice/
├── MockAppleDevice.xcodeproj   # Main Xcode project directory
├── MockAppleDevice/            # macOS App source files
│   ├── Assets.xcassets/        # Static resources and AppIcon
│   ├── ContentView.swift       # App UI main layout (NavigationSplitView split-pane layout)
│   ├── ControlPanel.swift      # Right-side property inspector & batch export control panel
│   ├── CanvasPreview.swift     # Center mockup canvas preview area (supports drag-and-drop screenshots)
│   ├── DeviceConfig.swift      # Device configuration definitions and NSImage rotation/cropping extensions
│   ├── DeviceMockupView.swift  # Mockup rendering component (device shell + screenshot mask layer)
│   ├── ExportService.swift     # High-quality image rendering and batch export logic
│   ├── DeviceRepository.swift  # Device data storage and loading manager
│   ├── MockupState.swift       # Unified reactive state model for mockup configurations
│   └── device_models.json      # Device parameter definitions (screen ratio, corner radius, etc.)
├── process_assets.py           # Script for auto-downloading device shells and scanning screen coordinates
├── scan_custom_devices.py      # Custom mockup expansion scanner script
└── build_dmg.sh                # Script to build release build and package as a DMG installer
```

---

## 🚀 Developer Guide

### 1. Prerequisites

- **OS Requirement**: macOS 14.0 or later
- **Development Tool**: Xcode 15.0 or later
- **Script Dependencies**: Python 3 and Pillow library (will be automatically installed when running the helper scripts if missing).

### 2. Run & Build

1. Open the main project `MockAppleDevice.xcodeproj` in Xcode.
2. Select the **MockAppleDevice** Scheme and set the destination to **My Mac**.
3. Press `Cmd + R` to compile and run locally.

---

## ⚙️ Helper Tools & Automation Scripts

Several efficient automation development/ops scripts are provided in the project root:

### 1. Auto-Download and Sync Device Assets
Run the script to automatically pull the latest device wireframes (from public device mockup repositories), scan the black pixel blocks in the images to **reverse-engineer screen positions and aspect ratios**, and merge the coordinates into the `Assets` directory.
```bash
python3 process_assets.py
```

### 2. Build & Package as `.dmg` Installer in One Click
Execute the following script to automatically clean old build caches, invoke `xcodebuild` to build the Release version, create a shortcut link to Applications, and use `hdiutil` to package it into a clean, read-only compressed disk image (DMG):
```bash
./build_dmg.sh
```
Upon successful packaging, you can find `MockAppleDevice.dmg` in the `ipa/` directory under the root path.
