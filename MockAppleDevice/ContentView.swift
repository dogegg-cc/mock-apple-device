import SwiftUI

struct ContentView: View {
    // State Model
    @State private var state = MockupState()
    
    // Body
    var body: some View {
        NavigationSplitView {
            DeviceSidebar(
                allDevices: state.allDevices,
                selectedCategory: $state.selectedCategory,
                selectedDevice: $state.selectedDevice
            )
        } detail: {
            HStack(spacing: 0) {
                // 中间预览工作区与拖入模块
                CanvasPreview(state: state)
                
                Divider()
                
                // 右侧属性定制与批量导出面板
                ControlPanel(state: state)
            }
            .frame(minWidth: 700, minHeight: 600)
        }
        .frame(minWidth: 1050, minHeight: 700)
        .navigationTitle("MockAppleDevice - 全品类高清套壳工具")
        // 强制启用浅色系主题 (解决问题 5)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
