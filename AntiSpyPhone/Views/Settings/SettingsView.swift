import SwiftUI

struct SettingsView: View {
    let device: Device?
    @State private var categories: [HardeningCategory] = HardeningCategory.mock
    @State private var selectedCategory: HardeningCategory.ID?

    var selectedCategoryBinding: Binding<HardeningCategory>? {
        guard let id = selectedCategory,
              let idx = categories.firstIndex(where: { $0.id == id })
        else { return nil }
        return Binding(get: { self.categories[idx] }, set: { self.categories[idx] = $0 })
    }

    var body: some View {
        Group {
            if let device, device.isConnected {
                HSplitView {
                    categoryList
                        .frame(minWidth: 220, idealWidth: 240, maxWidth: 260)

                    if let binding = selectedCategoryBinding {
                        HardeningCategoryView(category: binding)
                    } else {
                        Color.ndBlack
                    }
                }
            } else {
                notConnected
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ndBlack)
        .onAppear {
            if selectedCategory == nil { selectedCategory = categories.first?.id }
        }
    }

    // MARK: - Category list

    private var categoryList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("HARDENING CATEGORIES")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(2)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.ndBlack)

            Divider().background(Color.ndBorderVisible)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(categories) { cat in
                        CategoryRow(category: cat, isSelected: selectedCategory == cat.id)
                            .onTapGesture { selectedCategory = cat.id }
                            .pointingHandCursor()
                        Divider().background(Color.ndBorder)
                    }
                }
            }
        }
        .background(Color.ndBlack)
    }

    // MARK: - Not connected

    private var notConnected: some View {
        VStack(spacing: 12) {
            Text("NO DEVICE")
                .font(NFont.displayMD)
                .foregroundStyle(Color.ndTextDisabled)
            Text("CONNECT VIA USB TO MANAGE SETTINGS")
                .font(NFont.label)
                .foregroundStyle(Color.ndTextDisabled)
                .tracking(2)
        }
    }
}

// MARK: - Category row

private struct CategoryRow: View {
    let category: HardeningCategory
    let isSelected: Bool

    private var enabledCount: Int {
        category.settings.filter {
            if case .toggle(true) = $0.value { return true }
            return false
        }.count
    }

    var body: some View {
        HStack(spacing: 0) {
            // Active indicator bar
            Rectangle()
                .fill(isSelected ? Color.ndAccent : Color.clear)
                .frame(width: 2)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name.uppercased())
                        .font(NFont.mono(12))
                        .foregroundStyle(isSelected ? Color.ndTextDisplay : Color.ndTextPrimary)
                        .tracking(0.5)

                    Text("\(category.settings.count) SETTINGS · \(enabledCount) ACTIVE")
                        .font(NFont.label)
                        .foregroundStyle(Color.ndTextDisabled)
                        .tracking(1.5)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(isSelected ? Color.ndSurface : Color.clear)
        .contentShape(Rectangle())
    }
}
