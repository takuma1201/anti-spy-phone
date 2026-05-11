import SwiftUI

struct HardeningCategoryView: View {
    @Binding var category: HardeningCategory

    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack {
                Text(category.name.uppercased())
                    .font(NFont.heading)
                    .foregroundStyle(Color.ndTextDisplay)
                    .tracking(0.5)

                Spacer()

                Text("\(category.settings.count) SETTINGS")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(2)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)

            Divider().background(Color.ndBorderVisible)

            // Settings list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach($category.settings) { $setting in
                        SettingRow(setting: $setting)
                        Divider().background(Color.ndBorder)
                    }
                }
            }
        }
        .background(Color.ndBlack)
    }
}

// MARK: - Setting row

private struct SettingRow: View {
    @Binding var setting: HardeningSetting

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            // LEFT: display name + technical key
            VStack(alignment: .leading, spacing: 4) {
                Text(setting.displayName)
                    .font(NFont.body)
                    .foregroundStyle(Color.ndTextPrimary)

                Text(setting.key)
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // RIGHT: control
            control
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var control: some View {
        switch setting.value {
        case .toggle(let on):
            NothingToggle(isOn: Binding(
                get: { on },
                set: { setting.value = .toggle($0) }
            ))

        case .option(let current, let choices):
            Menu {
                ForEach(choices, id: \.self) { choice in
                    Button(choice.uppercased()) {
                        setting.value = .option(current: choice, choices: choices)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(current.uppercased())
                        .font(NFont.label)
                        .foregroundStyle(Color.ndTextPrimary)
                        .tracking(1)
                    Text("▾")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.ndTextSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(Color.ndBorderVisible, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .pointingHandCursor()

        case .readOnly(let value):
            Text(value.uppercased())
                .font(NFont.label)
                .foregroundStyle(Color.ndSuccess)
                .tracking(1.5)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(Color.ndSuccess.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Nothing toggle (white track / black thumb — the physical switch look)

struct NothingToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            // Track
            Capsule()
                .fill(isOn ? Color.ndTextDisplay : Color.ndSurfaceRaised)
                .frame(width: 44, height: 24)
                .overlay(
                    Capsule().stroke(
                        isOn ? Color.clear : Color.ndBorderVisible,
                        lineWidth: 1
                    )
                )

            // Thumb — black on white, matches Nothing physical switches
            Circle()
                .fill(isOn ? Color.ndBlack : Color.ndTextDisabled)
                .frame(width: 18, height: 18)
                .padding(3)
        }
        .animation(.easeOut(duration: 0.2), value: isOn)
        .onTapGesture { isOn.toggle() }
        .pointingHandCursor()
    }
}
