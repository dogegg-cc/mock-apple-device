import SwiftUI

/// 高保真图片合成与导出服务
enum ExportService {
    
    /// 将截图合成到设备外壳中，返回最终合成图像
    /// - Parameters:
    ///   - screenshot: 用户截图
    ///   - deviceImage: 设备外壳图（屏幕区域已透明）
    ///   - screenRect: 屏幕区域的相对位置与大小（0~1 比例值）
    ///   - category: 设备品类，用于确定默认圆角半径
    ///   - orientation: 目标设备方向，用于自动摆正图片
    /// - Returns: 合成后的完整图像
    static func compositeImage(
        screenshot: NSImage,
        deviceImage: NSImage,
        screenRect: CGRect,
        category: DeviceCategory,
        orientation: DeviceOrientation
    ) -> NSImage {
        let deviceSize = deviceImage.size
        
        return NSImage(size: deviceSize, flipped: false) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            
            // 自动摆正图片方向
            let adjustedScreenshot = screenshot.adjustedToOrientation(orientation)
            
            // 1. 将贴图以圆角裁切贴在底层
            context.saveGState()
            
            // Mac 坐标原点在左下角，需要进行 Y 轴镜像映射
            let targetRect = CGRect(
                x: deviceSize.width * screenRect.origin.x,
                y: deviceSize.height * (1.0 - screenRect.origin.y - screenRect.size.height),
                width: deviceSize.width * screenRect.size.width,
                height: deviceSize.height * screenRect.size.height
            )
            
            // 只有超窄边框的 iPhone 需要对底层贴图做圆角剪裁；其他设备（宽边框）直接使用直角剪裁，让样机自带圆角自然物理遮挡即可
            if category == .iphone || category == .appleWatch {
                let cr = min(targetRect.width, targetRect.height) * category.defaultCornerRadius
                let clipPath = CGPath(
                    roundedRect: targetRect,
                    cornerWidth: cr,
                    cornerHeight: cr,
                    transform: nil
                )
                context.addPath(clipPath)
                context.clip()
            } else {
                context.clip(to: targetRect)
            }
            
            // 绘制截图（填充模式，确保完全覆盖）
            if let cgScreenshot = adjustedScreenshot.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                context.draw(cgScreenshot, in: targetRect)
            }
            context.restoreGState()
            
            // 2. 覆盖顶层设备外框（自带自然的抠空圆角与阴影遮挡效果）
            if let cgDevice = deviceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                context.draw(cgDevice, in: CGRect(origin: .zero, size: deviceSize))
            }
            
            return true
        }
    }
    
    /// 批量导出所有截图
    static func exportAll(state: MockupState) {
        let screenshots = state.screenshots
        guard let device = state.selectedDevice, !screenshots.isEmpty else { return }
        let selectedColor = state.selectedColor
        let selectedOrientations = state.selectedOrientations
        guard !selectedOrientations.isEmpty else { return }
        
        let openPanel = NSOpenPanel()
        openPanel.title = "选择保存导出的文件夹"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        
        openPanel.begin { response in
            guard response == .OK, let targetURL = openPanel.url else { return }
            
            // 开启 Loading 遮罩
            state.isExporting = true
            
            DispatchQueue.global(qos: .userInitiated).async {
                // 后台线程访问安全作用域目录 (解决 macOS App Sandbox 513 权限错误)
                let hasAccess = targetURL.startAccessingSecurityScopedResource()
                defer {
                    if hasAccess {
                        targetURL.stopAccessingSecurityScopedResource()
                    }
                }
                
                var successCount = 0
                var fileIndex = 1
                
                for item in screenshots {
                    for orientation in selectedOrientations {
                        guard let variantMap = device.variants[selectedColor],
                              let config = variantMap[orientation] else {
                            continue
                        }
                        
                        // 加载对应的设备底图
                        guard let deviceImage = NSImage(named: config.imageName) else {
                            print("Error: Could not load device image: \(config.imageName)")
                            continue
                        }
                        
                        let compositedImage = compositeImage(
                            screenshot: item.image,
                            deviceImage: deviceImage,
                            screenRect: config.screenRect,
                            category: device.category,
                            orientation: orientation
                        )
                        
                        // 写入本地 PNG 文件
                        if let tiffData = compositedImage.tiffRepresentation,
                           let bitmapRep = NSBitmapImageRep(data: tiffData),
                           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                            
                            let rawName = (item.name as NSString).deletingPathExtension
                            let cleanDeviceName = device.name.replacingOccurrences(of: " ", with: "_")
                            let cleanColor = selectedColor.replacingOccurrences(of: " ", with: "_")
                            let fileName = "\(rawName)_\(cleanDeviceName)_\(cleanColor)_\(orientation.rawValue)_\(fileIndex).png"
                            let fileURL = targetURL.appendingPathComponent(fileName)
                            
                            do {
                                try pngData.write(to: fileURL)
                                successCount += 1
                                fileIndex += 1
                            } catch {
                                print("Error writing png image: \(error)")
                            }
                        }
                    }
                }
                
                // 提示成功并关闭 Loading 遮罩
                DispatchQueue.main.async {
                    state.isExporting = false
                    
                    let alert = NSAlert()
                    alert.messageText = "导出完成"
                    alert.informativeText = "成功导出 \(successCount) 张高品质透明背景套壳图片至文件夹：\n\(targetURL.path)"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                }
            }
        }
    }
}
