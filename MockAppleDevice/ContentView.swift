import SwiftUI

struct ContentView: View {
    // State Model
    @State private var state = MockupState()
    @AppStorage("app_language") private var appLanguage: String = "zh-Hans"
    
    // Body
    var body: some View {
        NavigationSplitView {
            DeviceSidebar(
                allDevices: state.allDevices,
                selectedCategory: $state.selectedCategory,
                selectedDevice: $state.selectedDevice
            )
            .padding(.top, 12)
        } detail: {
            ZStack {
                HStack(spacing: 0) {
                    // 中间预览工作区与拖入模块
                    CanvasPreview(state: state)
                    
                    Divider()
                    
                    // 右侧属性定制与批量导出面板
                    ControlPanel(state: state)
                }
                .disabled(state.isExporting)
                
                if state.isExporting {
                    ZStack {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)
                            Text("正在导出高品质样机，请稍候...")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("保存过程中请勿关闭应用")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                        )
                        .frame(width: 320)
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            .frame(minWidth: 700, minHeight: 600)
            .background(Color(red: 0.95, green: 0.95, blue: 0.97).ignoresSafeArea())
            .navigationTitle("MockAppleDevice - 全品类高清套壳工具")
            .toolbarBackground(Color.clear, for: .windowToolbar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            appLanguage = "zh-Hans"
                        } label: {
                            HStack {
                                Text("简体中文")
                                if appLanguage == "zh-Hans" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Button {
                            appLanguage = "en"
                        } label: {
                            HStack {
                                Text("English")
                                if appLanguage == "en" {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        Label("语言", systemImage: "globe")
                    }
                }
            }
        }
        .frame(minWidth: 1050, minHeight: 700)
        .preferredColorScheme(.light)
    }
}
