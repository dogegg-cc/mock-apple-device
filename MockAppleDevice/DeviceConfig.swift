import Foundation
import CoreGraphics

enum DeviceCategory: String, Codable, CaseIterable, Identifiable {
    case iphone = "iphone"
    case ipad = "ipad"
    case macbook = "macbook"
    case appleWatch = "appleWatch"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .iphone: return "iPhone"
        case .ipad: return "iPad"
        case .macbook: return "MacBook"
        case .appleWatch: return "Apple Watch"
        }
    }
    
    var systemImage: String {
        switch self {
        case .iphone: return "iphone"
        case .ipad: return "ipad"
        case .macbook: return "laptopcomputer"
        case .appleWatch: return "applewatch"
        }
    }
    
    var defaultCornerRadius: CGFloat {
        switch self {
        case .iphone: return 0.115
        case .ipad: return 0.045
        case .macbook: return 0.02
        case .appleWatch: return 0.22
        }
    }
}

enum DeviceOrientation: String, Codable, CaseIterable, Identifiable {
    case portrait = "portrait"
    case landscape = "landscape"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .portrait: return "竖屏 (Portrait)"
        case .landscape: return "横屏 (Landscape)"
        }
    }
    
    func localizedName(forLanguage language: String) -> String {
        let isEnglish = language == "en"
        switch self {
        case .portrait: return isEnglish ? "Portrait" : "竖屏"
        case .landscape: return isEnglish ? "Landscape" : "横屏"
        }
    }
}

struct VariantConfig: Codable, Hashable {
    let imageName: String
    let screenRect: CGRect
    
    private struct CGRectCodable: Codable {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
    }
    
    enum CodingKeys: String, CodingKey {
        case imageName
        case screenRect
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageName = try container.decode(String.self, forKey: .imageName)
        let rect = try container.decode(CGRectCodable.self, forKey: .screenRect)
        screenRect = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageName, forKey: .imageName)
        let rectCodable = CGRectCodable(
            x: screenRect.origin.x,
            y: screenRect.origin.y,
            width: screenRect.size.width,
            height: screenRect.size.height
        )
        try container.encode(rectCodable, forKey: .screenRect)
    }
    
    init(imageName: String, screenRect: CGRect) {
        self.imageName = imageName
        self.screenRect = screenRect
    }
}

struct DeviceModel: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let category: DeviceCategory
    let colors: [String]
    let variants: [String: [DeviceOrientation: VariantConfig]]
}

/// JSON 根结构类型别名：[品类: [型号: [颜色: [方向: VariantConfig]]]]
typealias DeviceConfigJSON = [String: [String: [String: [String: VariantConfig]]]]

#if canImport(AppKit)
import AppKit

extension NSImage {
    /// 自动旋转摆正图片以适应样机的物理方向，避免长宽拉伸不协调
    func adjustedToOrientation(_ targetOrientation: DeviceOrientation) -> NSImage {
        let isImageLandscape = size.width > size.height
        let isTargetLandscape = targetOrientation == .landscape
        
        // 如果截图与目标样机屏幕方向不一致，则进行旋转摆正
        if isImageLandscape != isTargetLandscape {
            let newSize = CGSize(width: size.height, height: size.width)
            return NSImage(size: newSize, flipped: false) { rect in
                guard let context = NSGraphicsContext.current?.cgContext else { return false }
                
                // 根据旋转源与目标方向，自适应决定顺时针或逆时针旋转：
                // 1. 竖图 -> 横样机：应逆时针旋转 90 度（+.pi / 2），使贴图头部（原上方）转向左侧（横屏样机头部在左）。
                // 2. 横图 -> 竖样机：应顺时针旋转 90 度（-.pi / 2），使贴图头部（原左方）转向顶侧（竖屏样机头部在顶）。
                let angle: CGFloat = isTargetLandscape ? .pi / 2 : -.pi / 2
                
                // 将原点移到旋转中心
                context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
                context.rotate(by: angle)
                context.translateBy(x: -self.size.width / 2, y: -self.size.height / 2)
                
                if let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    context.draw(cgImage, in: CGRect(origin: .zero, size: self.size))
                }
                return true
            }
        }
        return self
    }
}
#endif
