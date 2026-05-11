import Foundation

struct Device: Identifiable, Hashable {
    let id: UUID
    var name: String
    var serialNumber: String
    var isConnected: Bool
    var grapheneOSVersion: String
    var adbLatency: Int?   // ms; nil when disconnected
    var lastSeen: Date

    var serialShort: String { String(serialNumber.prefix(8)) + "…" }

    var grapheneOSVersionDisplay: String {
        // "2025040100" → "2025.04.01 (build 00)"
        guard grapheneOSVersion.count == 10 else { return grapheneOSVersion }
        let y  = String(grapheneOSVersion.prefix(4))
        let mo = String(grapheneOSVersion.dropFirst(4).prefix(2))
        let d  = String(grapheneOSVersion.dropFirst(6).prefix(2))
        let b  = String(grapheneOSVersion.dropFirst(8))
        return "\(y).\(mo).\(d) · build \(b)"
    }

    static let mockDevices: [Device] = [
        Device(
            id: UUID(),
            name: "Pixel 9 Pro",
            serialNumber: "2B041JEGR01234",
            isConnected: true,
            grapheneOSVersion: "2025040100",
            adbLatency: 12,
            lastSeen: Date()
        ),
        Device(
            id: UUID(),
            name: "Pixel 8",
            serialNumber: "1A039KFGP05678",
            isConnected: false,
            grapheneOSVersion: "2025030500",
            adbLatency: nil,
            lastSeen: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date()
        )
    ]
}
