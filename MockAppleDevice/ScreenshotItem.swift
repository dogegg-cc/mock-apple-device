import SwiftUI

/// 截图数据模型
struct ScreenshotItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let image: NSImage
}
