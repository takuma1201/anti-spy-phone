import SwiftUI

struct DashboardView: View {
    let device: Device?

    var body: some View {
        Group {
            if let device, device.isConnected {
                ConnectedStateView(device: device)
            } else {
                DisconnectedStateView(device: device)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ndBlack)
    }
}
