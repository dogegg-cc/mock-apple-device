import SwiftUI

/// 设备样机渲染视图 — 将截图叠加在设备外壳上
struct DeviceMockupView: View {
    let screenshot: NSImage?
    let device: DeviceModel
    let color: String
    let orientation: DeviceOrientation
    
    var body: some View {
        if let config = device.variants[color]?[orientation] {
            DeviceFrameView(screenshot: screenshot, device: device, config: config, orientation: orientation)
        } else {
            MissingVariantPlaceholder(orientation: orientation)
        }
    }
}

// MARK: - 设备框架渲染

private struct DeviceFrameView: View {
    let screenshot: NSImage?
    let device: DeviceModel
    let config: VariantConfig
    let orientation: DeviceOrientation
    
    var body: some View {
        Image(config.imageName)
            .resizable()
            .scaledToFit()
            .background(
                GeometryReader { geo in
                    screenshotLayer(in: geo.size)
                }
            )
    }
    
    private func screenshotLayer(in size: CGSize) -> some View {
        let screen = config.screenRect
        let screenWidth = size.width * screen.width
        let screenHeight = size.height * screen.height
        
        return Group {
            if let screenshot = screenshot {
                Image(nsImage: screenshot.adjustedToOrientation(orientation))
                    .resizable()
            } else {
                ScreenshotPlaceholder(
                    iconSize: min(size.width, size.height) * 0.08,
                    textSize: max(8, min(size.width, size.height) * 0.04)
                )
            }
        }
        .frame(width: screenWidth, height: screenHeight)
        .modifier(CornerRadiusModifier(category: device.category, screenWidth: screenWidth, screenHeight: screenHeight))
        .position(
            x: size.width * (screen.origin.x + screen.width / 2),
            y: size.height * (screen.origin.y + screen.height / 2)
        )
    }
}

// MARK: - 自适应裁剪修饰符

private struct CornerRadiusModifier: ViewModifier {
    let category: DeviceCategory
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    
    func body(content: Content) -> some View {
        if category == .iphone {
            let cr = min(screenWidth, screenHeight) * category.defaultCornerRadius
            content
                .clipShape(RoundedRectangle(cornerRadius: cr, style: .continuous))
        } else {
            content
                .clipped()
        }
    }
}

// MARK: - 占位符

private struct ScreenshotPlaceholder: View {
    let iconSize: CGFloat
    let textSize: CGFloat
    
    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.95, blue: 0.97)
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: iconSize))
                    .foregroundColor(.gray.opacity(0.7))
                Text("拖入截图")
                    .font(.system(size: textSize))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
    }
}

private struct MissingVariantPlaceholder: View {
    let orientation: DeviceOrientation
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
            Text("该设备缺少在此方向（\(orientation.displayName)）或颜色下的模型图片")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}
