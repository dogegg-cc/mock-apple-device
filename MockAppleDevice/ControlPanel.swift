import SwiftUI

struct ControlPanel: View {
    @Bindable var state: MockupState
    
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
                            Text(color).tag(color)
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
                            Text(orientation.displayName)
                                .foregroundColor(isSupported ? .primary : .secondary.opacity(0.4))
                        }
                        .disabled(!isSupported)
                    }
                    
                    if state.selectedOrientations.count > 1 {
                        Picker("预览方向", selection: $state.previewOrientation) {
                            ForEach(Array(state.selectedOrientations).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { ori in
                                Text(ori.displayName).tag(ori)
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
                    Text(totalExportCount > 0 ? "一键批量导出 (\(totalExportCount)张)" : "请先导入截图")
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
}
