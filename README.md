# MockAppleDevice 

[English](README.md) | [简体中文](README_zh-CN.md)

`MockAppleDevice` is a macOS device mockup tool. Import screenshots, choose an iPhone, iPad, MacBook, or Apple Watch frame, preview the result, and export PNGs in batches. Image compositing runs locally.

<img width="684" height="482.5" alt="截屏2026-07-24 22 24 15" src="https://github.com/user-attachments/assets/062d2f1c-162f-4b97-a939-4559e0e34b1e" />

<img width="684" height="482.5" alt="截屏2026-07-24 22 25 10" src="https://github.com/user-attachments/assets/c035944e-fd58-4a5e-ae93-d9201c94a254" />

<img width="684" height="482.5" alt="截屏2026-07-24 22 25 44" src="https://github.com/user-attachments/assets/702bae50-4245-4763-8b4b-51769ae623ec" />

<img width="684" height="482.5" alt="截屏2026-07-24 22 26 25" src="https://github.com/user-attachments/assets/d127906a-670f-43f3-983a-3818f1abf1fd" />

## Download and use

Download a published version from [Releases](https://github.com/dogegg-cc/mock-apple-device/releases). The app's minimum deployment target is macOS 14.0; the repository's packaging script produces a DMG for Apple Silicon (arm64).

1. Choose a device category and model in the sidebar.
2. Drag screenshots onto the canvas, or use the import button to select multiple images.
3. Choose a color or band style and select the supported export orientations.
4. Select a screenshot in the bottom tray to preview it, then export to a folder.

Each batch uses the selected model and color for all imported screenshots and selected orientations. Transparent areas around the device are preserved. Available styles and orientations depend on the imported assets. The interface includes Simplified Chinese and English language options.

Screenshots rotate automatically when their orientation differs from the frame, then scale to the configured screen rectangle. Different aspect ratios can stretch the screenshot; use screenshots matching the target screen ratio for best results. Frame styling and shadows come from the source artwork.

## Device assets

The current configuration includes the following families. See [device_models.json](MockAppleDevice/device_models.json) for exact models, colors, and orientations.

| Category | Included families |
| --- | --- |
| iPhone | iPhone 16 and 17 families, iPhone Air, iPhone 18 Pro / Pro Max |
| iPad | iPad (A16), iPad mini (A17 Pro), iPad Air (M4), iPad Pro (M5) |
| MacBook | MacBook Air (M5), MacBook Pro (M5), MacBook Neo |
| Apple Watch | Series 11, Ultra 3 |

## Build from source

- The app uses Swift, SwiftUI, AppKit, and Core Graphics.
- The current source has passed a Debug build with Xcode 27.0. Compatibility with older Xcode versions has not been verified.
- The app target deploys to macOS 14.0 or later. Project-level and test deployment settings use macOS 26.5; running tests requires an environment that meets those settings.
- Python 3 and Pillow are only needed to maintain device assets. Building and using the app does not require them.

Open `MockAppleDevice.xcodeproj` in Xcode, select the `MockAppleDevice` scheme and `My Mac`, then press `Cmd + R`. The project uses automatic signing; select your own Development Team in Signing & Capabilities when signing is required.

For a local unsigned build check, run from the repository root:

```bash
xcodebuild -project MockAppleDevice.xcodeproj \
  -scheme MockAppleDevice \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
```

This checks compilation and does not create a distribution DMG.

## Add or update device models

The asset workflow is:

```text
Source PNGs in Device/
  → scan_custom_devices.py
  → Assets.xcassets + device_models.json
  → Build the app
  → DeviceRepository loads the configuration for the UI
```

The app reads bundled resources and configuration. After adding source PNGs, import them and rebuild. Adding a model within an existing category usually only requires assets and JSON; adding a new category also requires changes to the Swift category definitions and related logic.

### 1. Prepare transparent PNGs

Device frames need a transparent screen opening so screenshots can be drawn behind them. The importer copies the original image; it does not cut out the screen or remove existing screen content. Use the lowercase `.png` extension.

For iPhone and iPad, use `Model - Color - Orientation.png`. For example:

```text
Device/
└── iPhone-18/
    └── iPhone 18 Pro/
        ├── iPhone 18 Pro - Black - Portrait.png
        ├── iPhone 18 Pro - Black - Landscape.png
        ├── iPhone 18 Pro - Silver - Portrait.png
        └── iPhone 18 Pro - Silver - Landscape.png
```

Use `Portrait` or `Landscape` for the orientation. Keep one source image per model, color, and orientation to avoid resource collisions. MacBook and Apple Watch use different filename parsing rules: follow the existing assets and `parse_metadata()` in the script, then inspect the generated model and color names.

### 2. Install importer dependencies

From the repository root, create a Python virtual environment and install Pillow:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install Pillow
```

Keep the local `.venv/` directory out of version control. The script's current entry point does not install Pillow automatically. Without it, screen detection logs an error and falls back to default coordinates.

### 3. Import assets

With that virtual environment active, run from the repository root:

```bash
python scan_custom_devices.py .
```

Pass `.` explicitly as the repository root; omitting the argument uses a machine-specific path hardcoded in the script. The importer scans all of `Device/`, parses category, model, color, and orientation, detects screen bounds, and writes image sets and the complete `device_models.json`.

**This is a full rebuild, not an incremental merge.** Existing images with matching resource names are overwritten. Manual coordinate adjustments and models present only in the JSON are replaced by the generated configuration. Removing a source image does not automatically remove its old `.imageset`; review and delete unused resources separately.

Screen detection uses transparent pixels and margin rules, with some fixed proportions for iPhones. Verify the result in the app. The script does not download artwork or composite screenshots.

### 4. Review and verify

- Review the Git diff for model names, colors, orientations, resource names, and unexpected changes to existing configuration.
- Check that every referenced `.imageset` contains its PNG and matching `Contents.json`.
- Rebuild and run the app. Import screenshots and inspect colors, orientations, screen edges, corners, and camera cutouts, then check exported PNGs.
- Commit the source files under `Device/`, generated `Assets.xcassets` resources, and `device_models.json` together.

`screenRect` uses coordinates from 0 to 1 relative to the complete frame image. Corner radii currently come from `DeviceCategory.defaultCornerRadius` in `DeviceConfig.swift`. The legacy `MockAppleDevice/update_json.py` script adds a `cornerRadius` JSON field that the current configuration model does not read; it is not part of the import workflow.

## Package a DMG

Run from the repository root:

```bash
./build_dmg.sh
```

The script builds a Release **arm64** app using the project's signing settings, adds an Applications shortcut, and writes `ipa/MockAppleDevice.dmg`. It does not import device assets; complete the import and verification steps first.

At startup, it deletes the root `build/` and `dist/` directories and the previous DMG with the same name. Temporary build directories are removed after successful packaging. The script does not notarize or staple the app, or produce Intel or Universal builds.

## Project structure

```text
MockAppleDevice/
├── Device/                        # Source device PNGs
├── MockAppleDevice.xcodeproj/     # Xcode project
├── MockAppleDevice/
│   ├── Assets.xcassets/           # Bundled image resources and app icon
│   ├── device_models.json        # Model → color → orientation → image and screen rect
│   ├── DeviceConfig.swift        # Config types, corner radii, screenshot rotation
│   ├── DeviceRepository.swift    # Loads device configuration from the app bundle
│   ├── MockupState.swift         # Current device selection and screenshot list
│   ├── ContentView.swift         # Main layout and language selection
│   ├── DeviceSidebar.swift       # Category and model selection
│   ├── CanvasPreview.swift       # Mockup preview and screenshot drop handling
│   ├── ScreenshotTray.swift      # Screenshot import, selection, and removal
│   ├── ControlPanel.swift        # Style, orientation, and export controls
│   ├── DeviceMockupView.swift    # SwiftUI mockup preview compositing
│   ├── ExportService.swift       # AppKit / Core Graphics compositing and PNG export
│   ├── Localizable/              # UI localization resources
│   └── update_json.py            # Legacy cornerRadius field migration script
├── MockAppleDeviceTests/          # Unit test target
├── MockAppleDeviceUITests/        # UI test target
├── scan_custom_devices.py         # Full asset import and configuration generation
└── build_dmg.sh                   # arm64 Release build and DMG packaging
```

## License

The project includes an [MIT License](LICENSE).
