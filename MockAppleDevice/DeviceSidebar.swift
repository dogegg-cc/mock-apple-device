import SwiftUI

struct DeviceSidebar: View {
    // Stored Properties
    let categories: [DeviceCategory] = DeviceCategory.allCases
    let allDevices: [DeviceModel]
    
    @Binding var selectedCategory: DeviceCategory
    @Binding var selectedDevice: DeviceModel?
    
    // Body
    var body: some View {
        List(selection: $selectedDevice) {
            // 分类筛选区域
            Section(header: Text("分类").font(.subheadline).foregroundColor(.secondary)) {
                ForEach(categories) { category in
                    CategoryRow(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            
            // 设备型号列表
            Section(header: Text("型号").font(.subheadline).foregroundColor(.secondary)) {
                let filteredDevices = allDevices.filter { $0.category == selectedCategory }
                if filteredDevices.isEmpty {
                    Text("未扫描到设备").foregroundColor(.secondary).italic()
                } else {
                    ForEach(filteredDevices) { device in
                        NavigationLink(value: device) {
                            HStack(spacing: 8) {
                                Image(systemName: selectedCategory.systemImage)
                                    .font(.system(size: 13))
                                    .foregroundColor(selectedDevice == device ? .accentColor : .secondary)
                                Text(device.name)
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200, idealWidth: 220)
    }
}

// 独立的分类行子 View
private struct CategoryRow: View {
    let category: DeviceCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 24, height: 24)
                    .background(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
                    .cornerRadius(6)
                
                Text(category.displayName)
                    .font(.body)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}
