import SwiftUI
import UniformTypeIdentifiers

/// 中央主预览画布（精简版：仅包含画布容器逻辑）
struct CanvasPreview: View {
    @Bindable var state: MockupState
    
    var body: some View {
        VStack(spacing: 0) {
            // 中央主预览画布
            ZStack {
                Color(red: 0.95, green: 0.95, blue: 0.97)
                    .ignoresSafeArea()
                
                if let device = state.selectedDevice {
                    DeviceMockupView(
                        screenshot: state.selectedScreenshot?.image,
                        device: device,
                        color: state.selectedColor,
                        orientation: state.previewOrientation
                    )
                    .padding(40)
                } else {
                    EmptyDevicePlaceholder()
                }
            }
            
            Divider()
            
            // 底部截图管理托盘
            ScreenshotTray(state: state)
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
    }
}

// MARK: - 占位符

private struct EmptyDevicePlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("没有选中设备或素材加载失败")
                .font(.headline)
                .foregroundColor(.primary)
            Text("请确保运行 scan_custom_devices.py 脚本导入了素材。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CanvasPreview(state: MockupState())
}
