import SwiftUI

/// 应用全局 UI 状态（精简版：纯 UI 状态 + 截图管理）
@Observable
class MockupState {
    // 设备数据源（注入）
    let deviceRepository: DeviceRepository

    // UI 选择状态
    var selectedCategory: DeviceCategory = .iphone {
        didSet {
            selectFirstAvailableDevice()
        }
    }
    var selectedDevice: DeviceModel? {
        didSet {
            handleDeviceChange()
        }
    }
    var selectedColor: String = ""
    var previewOrientation: DeviceOrientation = .portrait
    var selectedOrientations: Set<DeviceOrientation> = [.portrait]
    var isExporting: Bool = false
    
    // 截图数据
    var screenshots: [ScreenshotItem] = []
    var selectedScreenshotId: UUID?
    
    // 便捷访问
    var selectedScreenshot: ScreenshotItem? {
        screenshots.first { $0.id == selectedScreenshotId }
    }
    
    var allDevices: [DeviceModel] {
        deviceRepository.allDevices
    }
    
    init(deviceRepository: DeviceRepository = DeviceRepository()) {
        self.deviceRepository = deviceRepository
        selectFirstAvailableDevice()
    }
    
    // MARK: - 截图管理
    
    func addScreenshot(url: URL) {
        if let image = NSImage(contentsOf: url) {
            let item = ScreenshotItem(name: url.lastPathComponent, image: image)
            self.screenshots.append(item)
            if self.selectedScreenshotId == nil {
                self.selectedScreenshotId = item.id
            }
        }
    }
    
    func addScreenshot(image: NSImage, name: String) {
        let item = ScreenshotItem(name: name, image: image)
        self.screenshots.append(item)
        if self.selectedScreenshotId == nil {
            self.selectedScreenshotId = item.id
        }
    }
    
    func removeScreenshot(id: UUID) {
        screenshots.removeAll { $0.id == id }
        if selectedScreenshotId == id {
            selectedScreenshotId = screenshots.first?.id
        }
    }
    
    // MARK: - 设备选择联动
    
    func selectCategory(_ category: DeviceCategory) {
        self.selectedCategory = category
        selectFirstAvailableDevice()
    }
    
    /// 导出（委托给 ExportService）
    func exportAll() {
        guard selectedDevice != nil, !selectedColor.isEmpty else { return }
        ExportService.exportAll(state: self)
    }
}

// MARK: - 私有方法

extension MockupState {
    /// 联动设备修改：自动切换可用颜色和方向
    private func handleDeviceChange() {
        guard let device = selectedDevice else { return }
        
        // 如果当前颜色不被新设备支持，切回第一个颜色
        if !device.colors.contains(selectedColor) {
            self.selectedColor = device.colors.first ?? ""
        }
        
        // 刷新支持的方向
        if let variantMap = device.variants[selectedColor] {
            let availableOrientations = Array(variantMap.keys)
            
            // 确保 previewOrientation 在可用列表中
            if !availableOrientations.contains(previewOrientation) {
                self.previewOrientation = availableOrientations.first ?? .portrait
            }
            
            // 同步 selectedOrientations
            self.selectedOrientations = [self.previewOrientation]
        }
    }
    
    private func selectFirstAvailableDevice() {
        let categoryDevices = allDevices.filter { $0.category == selectedCategory }
        if let first = categoryDevices.first {
            self.selectedDevice = first
            self.selectedColor = first.colors.first ?? ""
            
            if let variantMap = first.variants[selectedColor] {
                let availableOrientations = Array(variantMap.keys)
                if !availableOrientations.contains(previewOrientation) {
                    self.previewOrientation = availableOrientations.first ?? .portrait
                }
            }
        } else {
            self.selectedDevice = nil
            self.selectedColor = ""
        }
    }
}
