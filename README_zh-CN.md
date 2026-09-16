# MockAppleDevice 

[English](README.md) | [简体中文](README_zh-CN.md)

`MockAppleDevice` 是一款 macOS 设备样机工具。导入截图后，可以选择 iPhone、iPad、MacBook 或 Apple Watch 边框，预览效果并批量导出 PNG。图片合成在本机完成。

<img width="684" height="482.5" alt="截屏2026-07-03 16 46 23" src="https://github.com/user-attachments/assets/24c0ba7e-88a2-480e-a81a-7b244e4dd534" />

## 下载与使用

从 [Releases](https://github.com/dogegg-cc/mock-apple-device/releases) 下载发布版本。App 的最低部署目标为 macOS 14.0；仓库打包脚本生成的 DMG 面向 Apple Silicon（arm64）。

1. 在左侧选择设备品类和型号。
2. 将截图拖入画布，或点击「导入图片」选择多张图片。
3. 在右侧选择颜色或表带样式，勾选设备支持的导出方向。
4. 在底部选择截图查看预览，再点击批量导出并选择保存文件夹。

每次导出使用当前选定的型号和颜色，为所有已导入截图生成所选方向的 PNG。设备周围的透明区域会保留；方向和外观选项取决于已导入的素材。界面可切换简体中文和英文。

截图方向与设备方向不一致时会自动旋转，然后缩放至配置的屏幕区域。截图比例与目标屏幕不一致时可能发生拉伸，建议使用相同比例的截图。边框外观和阴影来自素材本身。

## 设备素材

当前配置包含以下设备系列；具体型号、颜色和方向以 [device_models.json](MockAppleDevice/device_models.json) 为准。

| 品类 | 已收录系列 |
| --- | --- |
| iPhone | iPhone 16、17 系列，iPhone Air，iPhone 18 Pro / Pro Max |
| iPad | iPad (A16)、iPad mini (A17 Pro)、iPad Air (M4)、iPad Pro (M5) |
| MacBook | MacBook Air (M5)、MacBook Pro (M5)、MacBook Neo |
| Apple Watch | Series 11、Ultra 3 |

## 从源码运行

- App 使用 Swift、SwiftUI、AppKit 和 Core Graphics。
- 当前源码已在 Xcode 27.0 下通过 Debug 构建验证；旧版 Xcode 的兼容性未验证。
- App target 的最低部署目标为 macOS 14.0，项目级设置和测试 target 的部署目标为 macOS 26.5。运行测试时需满足测试配置要求。
- Python 3 和 Pillow 仅用于维护设备素材，正常编译和使用 App 无需安装。

使用 Xcode 打开 `MockAppleDevice.xcodeproj`，选择 `MockAppleDevice` scheme 和 `My Mac`，按 `Cmd + R` 运行。工程使用自动签名；需要签名时，在 Signing & Capabilities 中选择自己的 Development Team。

也可以在仓库根目录执行本地无签名构建检查：

```bash
xcodebuild -project MockAppleDevice.xcodeproj \
  -scheme MockAppleDevice \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
```

此命令用于检查编译，不生成 DMG 分发包。

## 新增或更新机型

设备接入流程如下：

```text
Device/ 中的原始 PNG
  → scan_custom_devices.py
  → Assets.xcassets + device_models.json
  → 编译 App
  → DeviceRepository 加载配置，界面显示机型
```

App 读取的是随包发布的资源和配置，添加原始 PNG 后需要导入并重新编译。同一品类内新增机型通常只需更新素材和 JSON；新增设备品类需要同时扩展 Swift 中的品类定义及相关逻辑。

### 1. 准备透明 PNG

设备边框素材需要包含透明的屏幕区域，截图会绘制在边框后面。脚本直接复制原图，不负责抠图或清除屏幕内容。文件扩展名使用小写 `.png`。

iPhone / iPad 使用「型号 - 颜色 - 方向.png」命名，以 iPhone 18 为例：

```text
Device/
└── iPhone-18/
    └── iPhone 18 Pro/
        ├── iPhone 18 Pro - Black - Portrait.png
        ├── iPhone 18 Pro - Black - Landscape.png
        ├── iPhone 18 Pro - Silver - Portrait.png
        └── iPhone 18 Pro - Silver - Landscape.png
```

文件名中的 `Portrait` / `Landscape` 分别表示竖屏和横屏。同一型号、颜色、方向只保留一份素材，以免生成同名资源时互相覆盖。MacBook 和 Apple Watch 使用不同的命名解析规则，添加时请对照同类素材及脚本中的 `parse_metadata()`，并检查生成后的型号和颜色名称。

### 2. 安装导入依赖

在仓库根目录创建 Python 虚拟环境并安装 Pillow：

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install Pillow
```

`.venv/` 是本地环境，不应提交到版本库。脚本当前入口不会自动安装 Pillow；缺少依赖时，屏幕检测会报错并回退到默认坐标。

### 3. 导入素材

保持上述虚拟环境激活，在仓库根目录执行：

```bash
python scan_custom_devices.py .
```

显式传入 `.` 表示仓库根目录；省略参数会使用脚本中写死的本机路径。脚本会扫描整个 `Device/`，解析品类、型号、颜色和方向，检测屏幕区域，生成 `.imageset` 资源及完整的 `device_models.json`。

**这是全量重建，不是增量合并。** 同名图片资源会被覆盖，JSON 中手工调整的坐标或仅存在于 JSON 的机型也会被重建结果替代。从 `Device/` 删除素材后，脚本不会自动清理对应的旧 `.imageset`，需要单独核对并删除不再使用的资源。

屏幕检测基于透明像素和边距规则；iPhone 还使用部分固定比例，检测结果需要通过实际预览确认。脚本不下载素材，也不执行截图合成。

### 4. 检查并验证

- 检查 Git 差异，确认型号、颜色、方向和 `imageName` 正确，已有配置的变化符合预期。
- 确认每个配置对应的 `.imageset` 包含 PNG 和正确的 `Contents.json`。
- 重新编译运行 App，导入截图检查各颜色、横竖屏、屏幕边缘、四角和摄像头区域，再导出 PNG 检查结果。
- 提交原始 `Device/` 素材、生成的 `Assets.xcassets` 资源和 `device_models.json`。

`screenRect` 使用相对于整张边框图片的 0～1 坐标。当前圆角参数来自 `DeviceConfig.swift` 中的 `DeviceCategory.defaultCornerRadius`；`MockAppleDevice/update_json.py` 是旧的字段补充脚本，其写入的 `cornerRadius` 不被当前配置模型读取，无需作为导入步骤运行。

## 打包 DMG

在仓库根目录执行：

```bash
./build_dmg.sh
```

脚本使用项目的签名配置构建 Release 版 **arm64** App，加入 Applications 快捷方式，并输出 `ipa/MockAppleDevice.dmg`。脚本不会执行素材导入，需要先完成前面的导入与验证。

打包开始时会删除根目录下的 `build/`、`dist/` 和同名旧 DMG；成功后会清理临时构建目录。它没有执行公证或 stapling，也不生成 Intel 或 Universal 版本。

## 项目结构

```text
MockAppleDevice/
├── Device/                        # 原始设备 PNG
├── MockAppleDevice.xcodeproj/     # Xcode 工程
├── MockAppleDevice/
│   ├── Assets.xcassets/           # 打包进 App 的图片资源和图标
│   ├── device_models.json        # 型号 → 颜色 → 方向 → 资源名与屏幕区域
│   ├── DeviceConfig.swift        # 配置类型、圆角参数和截图旋转
│   ├── DeviceRepository.swift    # 从 App Bundle 加载设备配置
│   ├── MockupState.swift         # 当前设备选择和截图列表
│   ├── ContentView.swift         # 主界面和语言切换
│   ├── DeviceSidebar.swift       # 品类和型号选择
│   ├── CanvasPreview.swift       # 样机预览和拖入截图
│   ├── ScreenshotTray.swift      # 截图导入、选择和移除
│   ├── ControlPanel.swift        # 外观、方向和导出控制
│   ├── DeviceMockupView.swift    # SwiftUI 样机预览合成
│   ├── ExportService.swift       # AppKit / Core Graphics 合成并导出 PNG
│   ├── Localizable/              # 界面本地化资源
│   └── update_json.py            # 旧的 cornerRadius 字段补充脚本
├── MockAppleDeviceTests/          # 单元测试 target
├── MockAppleDeviceUITests/        # UI 测试 target
├── scan_custom_devices.py         # 素材全量导入和配置生成
└── build_dmg.sh                   # arm64 Release 构建与 DMG 打包
```

## 许可证

项目包含 [MIT License](LICENSE)。
