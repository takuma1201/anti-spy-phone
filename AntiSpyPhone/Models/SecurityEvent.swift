import Foundation
import SwiftUI

enum EventType: String, CaseIterable, Identifiable {
    case permissionGrant   = "PERMISSION_GRANT"
    case permissionDeny    = "PERMISSION_DENY"
    case sensorAccess      = "SENSOR_ACCESS"
    case sandboxViolation  = "SANDBOX_VIOLATION"
    case networkBlock      = "NETWORK_BLOCK"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .permissionGrant:  return "GRANT"
        case .permissionDeny:   return "DENY"
        case .sensorAccess:     return "SENSOR"
        case .sandboxViolation: return "SANDBOX"
        case .networkBlock:     return "NET_BLOCK"
        }
    }

    var color: Color {
        switch self {
        case .permissionGrant:  return .ndSuccess
        case .permissionDeny:   return .ndAccent
        case .sensorAccess:     return .ndWarning
        case .sandboxViolation: return .ndAccent
        case .networkBlock:     return .ndTextSecondary
        }
    }
}

struct SecurityEvent: Identifiable {
    let id: UUID
    let timestamp: Date
    let type: EventType
    let appPackage: String
    let detail: String
    let rawJSON: String

    static func mock(count: Int = 120) -> [SecurityEvent] {
        let packages = [
            "com.google.chrome",
            "org.signal.messenger",
            "com.protonvpn.android",
            "org.bromite.bromite",
            "com.whatsapp"
        ]
        let types = EventType.allCases
        return (0..<count).map { i in
            let type    = types[i % types.count]
            let package = packages[i % packages.count]
            let ago     = TimeInterval(i * 47)
            return SecurityEvent(
                id:        UUID(),
                timestamp: Date().addingTimeInterval(-ago),
                type:      type,
                appPackage: package,
                detail:    Self.detail(for: type, package: package),
                rawJSON:   Self.rawJSON(type: type, package: package, uid: 10000 + i, ago: Int(ago))
            )
        }
    }

    private static func detail(for type: EventType, package: String) -> String {
        switch type {
        case .permissionGrant:
            return "\(package) granted android.permission.CAMERA"
        case .permissionDeny:
            return "\(package) denied android.permission.RECORD_AUDIO"
        case .sensorAccess:
            return "\(package) accessed TYPE_ACCELEROMETER (profile 0)"
        case .sandboxViolation:
            return "\(package) attempted cross-profile file access: /data/user/10/"
        case .networkBlock:
            return "\(package) blocked: 192.168.0.1:8080 — firewall rule #4"
        }
    }

    private static func rawJSON(type: EventType, package: String, uid: Int, ago: Int) -> String {
        """
        {
          "event": "\(type.rawValue)",
          "uid": \(uid),
          "package": "\(package)",
          "profile": 0,
          "timestamp_unix": \(Int(Date().timeIntervalSince1970) - ago),
          "granted": \(type == .permissionGrant),
          "source": "grapheneos.permission_controller"
        }
        """
    }
}
