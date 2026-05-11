import SwiftUI

enum NavItem: String, Hashable, CaseIterable {
    case dashboard = "Dashboard"
    case settings  = "Settings"
    case logs      = "Logs"

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .settings:  return "slider.horizontal.3"
        case .logs:      return "list.bullet.rectangle"
        }
    }

    var labelJP: String {
        switch self {
        case .dashboard: return "ダッシュボード"
        case .settings:  return "セキュリティ設定"
        case .logs:      return "セキュリティログ"
        }
    }
}

struct ContentView: View {
    @State private var devices: [Device]     = Device.mockDevices
    @State private var selectedDevice: Device?
    @State private var selectedNav: NavItem  = .dashboard

    init() {
        _selectedDevice = State(initialValue: Device.mockDevices.first)
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                devices: $devices,
                selectedDevice: $selectedDevice,
                selectedNav: $selectedNav
            )
        } detail: {
            Group {
                switch selectedNav {
                case .dashboard:
                    DashboardView(device: selectedDevice)
                case .settings:
                    SettingsView(device: selectedDevice)
                case .logs:
                    LogsView(device: selectedDevice)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.ndBlack)
        }
        .navigationSplitViewStyle(.balanced)
        .background(Color.ndBlack)
    }
}
