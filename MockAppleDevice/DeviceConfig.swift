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
