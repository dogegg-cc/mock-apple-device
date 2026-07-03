import SwiftUI

struct ControlPanel: View {
    @Bindable var state: MockupState
    @AppStorage("app_language") private var appLanguage: String = "zh-Hans"
    
    // 计算即将导出的总张数
    private var totalExportCount: Int {
        state.screenshots.count * state.selectedOrientations.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 1. 设备颜色与表带选择 (动态联动机型颜色)
            if let device = state.selectedDevice {
                VStack(alignment: .leading, spacing: 8) {
                    Text("设备颜色 / 样式")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("选择外观", selection: $state.selectedColor) {
                        ForEach(device.colors, id: \.self) { color in
                            Text(localizedColor(color, forLanguage: appLanguage)).tag(color)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Divider()
                
                // 2. 设备方向勾选与预览联动 (解决问题 1)
                VStack(alignment: .leading, spacing: 8) {
                    Text("导出方向 (多选)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    let availableOrientations = getAvailableOrientations(for: device)
                    
                    ForEach(DeviceOrientation.allCases) { orientation in
                        let isSupported = availableOrientations.contains(orientation)
                        
                        Toggle(isOn: Binding(
                            get: { state.selectedOrientations.contains(orientation) },
                            set: { isChecked in
                                if isChecked {
                                    state.selectedOrientations.insert(orientation)
                                } else {
                                    if state.selectedOrientations.count > 1 {
                                        state.selectedOrientations.remove(orientation)
                                    }
                                }
                                // 同步预览方向为勾选的任一有效方向
                                if !state.selectedOrientations.contains(state.previewOrientation) {
                                    state.previewOrientation = state.selectedOrientations.first ?? .portrait
                                }
                            }
                        )) {
                            Text(orientation.localizedName(forLanguage: appLanguage))
                                .foregroundColor(isSupported ? .primary : .secondary.opacity(0.4))
                        }
                        .disabled(!isSupported)
                    }
                    
                    if state.selectedOrientations.count > 1 {
                        Picker("预览方向", selection: $state.previewOrientation) {
                            ForEach(Array(state.selectedOrientations).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { ori in
                                Text(ori.localizedName(forLanguage: appLanguage)).tag(ori)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, 4)
                    }
                }
                
                Divider()
            }
            
            Spacer()
            
            // 3. 批量打包导出按钮 (一键启动高保真导出)
            Button(action: { state.exportAll() }) {
                HStack {
                    Spacer()
                    Image(systemName: "square.and.arrow.up.on.square.fill")
                    let exportButtonKey: LocalizedStringKey = totalExportCount > 0 ? "一键批量导出 (\(totalExportCount)张)" : "请先导入截图"
                    Text(exportButtonKey)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(state.screenshots.isEmpty || state.selectedDevice == nil)
        }
        .padding(16)
        .frame(minWidth: 260, idealWidth: 280, maxWidth: 320)
        // 浅色面板背景 (解决问题 5)
        .background(Color(red: 0.94, green: 0.94, blue: 0.96))
    }
    
    // 助手函数：获取设备支持的所有方向
    private func getAvailableOrientations(for device: DeviceModel) -> Set<DeviceOrientation> {
        guard let variantMap = device.variants[state.selectedColor] else { return [] }
        return Set(variantMap.keys)
    }
    
    // 颜色本地化翻译字典
    private func localizedColor(_ color: String, forLanguage language: String) -> String {
        guard language == "zh-Hans" else { return color }
        let translations: [String: String] = [
            "42mm": "42毫米",
            "46mm": "46毫米",
            "Black": "黑色",
            "Black + Alpine Loop Black": "黑色 + 黑色高山回环式表带",
            "Black + Alpine Loop Light Blue": "黑色 + 浅蓝色高山回环式表带",
            "Black + Milanese Loop": "黑色 + 米兰尼斯表带",
            "Black + Ocean Band Anchor Blue": "黑色 + 深蓝色海洋表带",
            "Black + Ocean Band Black": "黑色 + 黑色海洋表带",
            "Black + Trail Loop Black Charcoal": "黑色 + 黑色/炭灰色野径回环式表带",
            "Black Titanium": "黑色钛金属",
            "Blue": "蓝色",
            "Blush": "腮红金",
            "Citrus": "柑橘色",
            "Cloud White": "云白色",
            "Cosmic Orange": "宇宙橙色",
            "Deep Blue": "深蓝色",
            "Desert Titanium": "沙漠色钛金属",
            "Indigo": "靛蓝色",
            "Lavender": "薰衣草紫",
            "Light Gold": "浅金色",
            "Midnight": "午夜色",
            "Mist Blue": "薄雾蓝",
            "Natural + Alpine Loop Light Blue": "原色 + 浅蓝色高山回环式表带",
            "Natural + Alpine Loop Terra Cotta": "原色 + 陶瓦色高山回环式表带",
            "Natural + Milanese Loop": "原色 + 米兰尼斯表带",
            "Natural + Ocean Band Anchor Blue": "原色 + 深蓝色海洋表带",
            "Natural + Ocean Band Neon Green": "原色 + 荧光绿色海洋表带",
            "Natural + Trail Loop Blue Bright Blue": "原色 + 蓝色/亮蓝色野径回环式表带",
            "Natural + Trail Loop Green Neon": "原色 + 绿色/荧光黄色野径回环式表带",
            "Natural Titanium": "原色钛金属",
            "Pink": "粉色",
            "Purple": "紫色",
            "Sage": "鼠尾草绿",
            "Silver": "银色",
            "Sky Blue": "天蓝色",
            "Space Black": "深空黑色",
            "Space Gray": "深空灰色",
            "Starlight": "星光色",
            "Teal": "深青色",
            "Ultramarine": "群青色",
            "White": "白色",
            "White Titanium": "白色钛金属",
            "Yellow": "黄色"
        ]
        return translations[color] ?? color
    }
}
