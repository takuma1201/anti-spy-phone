import SwiftUI

struct SidebarView: View {
    @Binding var devices: [Device]
    @Binding var selectedDevice: Device?
    @Binding var selectedNav: NavItem

    var body: some View {
        VStack(spacing: 0) {
            // App wordmark
            HStack(spacing: 0) {
                Text("ANTISPY")
                    .font(NFont.mono(13, weight: .bold))
                    .foregroundStyle(Color.ndTextDisplay)
                    .tracking(3)
                Text("·PHONE")
                    .font(NFont.mono(13))
                    .foregroundStyle(Color.ndAccent)
                    .tracking(3)
                Spacer()

                // Signal dot
                Circle()
                    .fill(Color.ndAccent)
                    .frame(width: 5, height: 5)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.ndBlack)

            Divider().background(Color.ndBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // DEVICES
                    sectionLabel("DEVICES")

                    ForEach(devices) { device in
                        DeviceRow(
                            device: device,
                            isSelected: selectedDevice?.id == device.id
                        )
                        .onTapGesture {
                            selectedDevice = device
                            selectedNav = .dashboard
                        }
                        .pointingHandCursor()
                    }

                    Rectangle()
                        .fill(Color.ndBorderVisible)
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)

                    // NAVIGATE
                    sectionLabel("NAVIGATE")

                    ForEach(NavItem.allCases, id: \.self) { item in
                        NavRow(item: item, isSelected: selectedNav == item)
                            .onTapGesture { selectedNav = item }
                            .pointingHandCursor()
                    }
                }
                .padding(.vertical, 8)
            }

            Spacer()

            Divider().background(Color.ndBorder)

            // Footer — ADB bridge status
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.ndSuccess)
                    .frame(width: 5, height: 5)
                Text("ADB BRIDGE ACTIVE")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(1.5)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.ndBlack)
        }
        .frame(minWidth: 220, idealWidth: 220, maxWidth: 240)
        .background(Color.ndBlack)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(NFont.label)
            .foregroundStyle(Color.ndTextDisabled)
            .tracking(2)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }
}

// MARK: - Device row

private struct DeviceRow: View {
    let device: Device
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Rectangle()
                .fill(device.isConnected ? Color.ndSuccess : Color.ndTextDisabled)
                .frame(width: 2, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(device.name.uppercased())
                    .font(NFont.mono(12, weight: .bold))
                    .foregroundStyle(isSelected ? Color.ndTextDisplay : Color.ndTextPrimary)
                    .tracking(0.5)

                Text(device.serialShort)
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(1)
            }

            Spacer()

            if device.isConnected {
                Text("LIVE")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndSuccess)
                    .tracking(1.5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(isSelected ? Color.ndSurface : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Nav row

private struct NavRow: View {
    let item: NavItem
    let isSelected: Bool

    var label: String {
        isSelected ? "[ \(item.rawValue.uppercased()) ]" : item.rawValue.uppercased()
    }

    var body: some View {
        HStack {
            Text(label)
                .font(NFont.mono(12))
                .foregroundStyle(isSelected ? Color.ndTextDisplay : Color.ndTextDisabled)
                .tracking(1.5)
                .animation(.easeOut(duration: 0.15), value: isSelected)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(isSelected ? Color.ndSurface : Color.clear)
        .contentShape(Rectangle())
    }
}
