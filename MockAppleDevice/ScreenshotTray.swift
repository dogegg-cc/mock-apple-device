import SwiftUI
import UniformTypeIdentifiers

/// 底部截图管理托盘
struct ScreenshotTray: View {
    @Bindable var state: MockupState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TrayHeader(
                screenshotCount: state.screenshots.count,
                clearAction: { state.clearScreenshots() },
                importAction: selectFileManually
            )
            
            if state.screenshots.isEmpty {
                EmptyTrayPlaceholder()
            } else {
                TrayScrollContent(
                    screenshots: state.screenshots,
                    selectedId: state.selectedScreenshotId,
                    selectAction: { state.selectedScreenshotId = $0 },
                    deleteAction: { state.removeScreenshot(id: $0) }
                )
            }
        }
        .background(Color(red: 0.90, green: 0.90, blue: 0.93))
    }
    
    private func selectFileManually() {
        let panel = NSOpenPanel()
        panel.title = "选择导入的屏幕截图"
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    state.addScreenshot(url: url)
                }
            }
        }
    }
}

// MARK: - 子视图

private struct TrayHeader: View {
    let screenshotCount: Int
    let clearAction: () -> Void
    let importAction: () -> Void
    
    var body: some View {
        HStack {
            Text(LocalizedStringKey("待处理截图 (\(screenshotCount))"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            if screenshotCount > 0 {
                Button(role: .destructive, action: clearAction) {
                    Label("清空", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Button(action: importAction) {
                Label("导入图片", systemImage: "photo.badge.plus")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

private struct EmptyTrayPlaceholder: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 24))
                    .foregroundColor(.gray.opacity(0.5))
                Text("拖入或导入多张截图进行批量套壳")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
}

private struct TrayScrollContent: View {
    let screenshots: [ScreenshotItem]
    let selectedId: UUID?
    let selectAction: (UUID) -> Void
    let deleteAction: (UUID) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 12) {
                ForEach(screenshots) { item in
                    TrayItemCard(
                        item: item,
                        isSelected: selectedId == item.id,
                        selectAction: { selectAction(item.id) },
                        deleteAction: { deleteAction(item.id) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(height: 100)
    }
}

private struct TrayItemCard: View {
    let item: ScreenshotItem
    let isSelected: Bool
    let selectAction: () -> Void
    let deleteAction: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: selectAction) {
                VStack(spacing: 4) {
                    Image(nsImage: item.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 50)
                        .cornerRadius(4)
                        .clipped()
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                    
                    Text(item.name)
                        .font(.system(size: 9))
                        .lineLimit(1)
                        .frame(width: 80)
                        .foregroundColor(isSelected ? .primary : .secondary)
                }
            }
            .buttonStyle(.plain)
            
            Button(action: deleteAction) {
                Image(systemName: "multiply.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white.cornerRadius(6))
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)
        }
        .padding(.top, 4)
    }
}
