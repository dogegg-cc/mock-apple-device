import SwiftUI

/// 设备数据加载与查询服务
@Observable
class DeviceRepository {
    private(set) var allDevices: [DeviceModel] = []
    
    init() {
        loadDeviceConfig()
    }
    
    /// 从 Bundle 加载设备配置 JSON
    func loadDeviceConfig() {
        guard let bundleURL = Bundle.main.url(forResource: "device_models", withExtension: "json"),
              let data = try? Data(contentsOf: bundleURL) else {
            print("device_models.json not found in bundle.")
            return
        }
        
        do {
            let rawDict = try JSONDecoder().decode(DeviceConfigJSON.self, from: data)
            
            var devices: [DeviceModel] = []
            
            for (catStr, modelsDict) in rawDict {
                guard let category = DeviceCategory(rawValue: catStr) else { continue }
                
                for (modelStr, colorsDict) in modelsDict {
                    let colors = Array(colorsDict.keys).sorted()
                    var variants: [String: [DeviceOrientation: VariantConfig]] = [:]
                    
                    for (colorStr, orientationsDict) in colorsDict {
                        var orientationMap: [DeviceOrientation: VariantConfig] = [:]
                        for (oriStr, config) in orientationsDict {
                            if let orientation = DeviceOrientation(rawValue: oriStr) {
                                orientationMap[orientation] = config
                            }
                        }
                        variants[colorStr] = orientationMap
                    }
                    
                    let model = DeviceModel(
                        name: modelStr,
                        category: category,
                        colors: colors,
                        variants: variants
                    )
                    devices.append(model)
                }
            }
            
            self.allDevices = devices.sorted { $0.name < $1.name }
        } catch {
            print("Error parsing device_models.json: \(error)")
        }
    }
    
    /// 按品类筛选设备
    func devices(for category: DeviceCategory) -> [DeviceModel] {
        allDevices.filter { $0.category == category }
    }
}
