import Foundation

// MARK: - Value types

enum SettingValue {
    case toggle(Bool)
    case option(current: String, choices: [String])
    case readOnly(String)
}

// MARK: - Setting

struct HardeningSetting: Identifiable {
    let id: UUID
    let key: String           // raw GrapheneOS key
    let displayName: String
    var value: SettingValue
}

// MARK: - Category

struct HardeningCategory: Identifiable {
    let id: UUID
    let name: String
    let systemImage: String
    var settings: [HardeningSetting]
}

// MARK: - Mock data

extension HardeningCategory {
    static let mock: [HardeningCategory] = [
        HardeningCategory(
            id: UUID(), name: "Sensor Permissions", systemImage: "sensor.tag.radiowaves.forward",
            settings: [
                .init(id: UUID(), key: "sensors.all_sensors.toggle",           displayName: "All sensors kill switch",           value: .toggle(false)),
                .init(id: UUID(), key: "sensors.camera.disallow_third_party",  displayName: "Disallow camera — third-party apps", value: .toggle(false)),
                .init(id: UUID(), key: "sensors.microphone.disallow_third_party", displayName: "Disallow microphone — third-party apps", value: .toggle(true)),
                .init(id: UUID(), key: "sensors.location.precision",           displayName: "Location precision override",        value: .option(current: "Exact", choices: ["Exact", "Approximate", "Blocked"])),
                .init(id: UUID(), key: "sensors.uwb.enabled",                  displayName: "UWB hardware enabled",               value: .toggle(true)),
                .init(id: UUID(), key: "sensors.nfc.enabled",                  displayName: "NFC hardware enabled",               value: .toggle(true)),
            ]
        ),
        HardeningCategory(
            id: UUID(), name: "Network Sandbox", systemImage: "network.badge.shield.half.filled",
            settings: [
                .init(id: UUID(), key: "network.internet_permission.default",  displayName: "Default INTERNET permission",        value: .option(current: "Allow", choices: ["Allow", "Deny"])),
                .init(id: UUID(), key: "network.connectivity_check.enabled",   displayName: "Connectivity check (captive portal)", value: .toggle(false)),
                .init(id: UUID(), key: "network.dns.private_dns_mode",         displayName: "Private DNS mode",                   value: .option(current: "Automatic", choices: ["Off", "Automatic", "Strict"])),
                .init(id: UUID(), key: "network.dns.server",                   displayName: "Private DNS hostname",               value: .readOnly("dns.quad9.net")),
                .init(id: UUID(), key: "network.vpn.always_on",                displayName: "Always-on VPN",                     value: .toggle(true)),
                .init(id: UUID(), key: "network.vpn.block_without",            displayName: "Block connections without VPN",      value: .toggle(true)),
            ]
        ),
        HardeningCategory(
            id: UUID(), name: "App Sandbox", systemImage: "app.badge.checkmark",
            settings: [
                .init(id: UUID(), key: "sandbox.contact_scopes.enabled",       displayName: "Contact scopes",                     value: .toggle(true)),
                .init(id: UUID(), key: "sandbox.storage_scopes.enabled",       displayName: "Storage scopes",                     value: .toggle(true)),
                .init(id: UUID(), key: "sandbox.clipboard.auto_deny",          displayName: "Auto-deny clipboard access",         value: .toggle(false)),
                .init(id: UUID(), key: "sandbox.exploit_protection.auto",      displayName: "Auto-grant exploit protection",      value: .toggle(true)),
                .init(id: UUID(), key: "sandbox.user_profiles.enabled",        displayName: "Work profile / secondary user",      value: .toggle(false)),
            ]
        ),
        HardeningCategory(
            id: UUID(), name: "Storage Scopes", systemImage: "externaldrive.badge.shield",
            settings: [
                .init(id: UUID(), key: "storage.media_access.default",         displayName: "Media access default",               value: .option(current: "None", choices: ["None", "Read-only", "Read/Write"])),
                .init(id: UUID(), key: "storage.external.block_usb",           displayName: "Block USB mass storage",             value: .toggle(false)),
                .init(id: UUID(), key: "storage.external.block_sdcard",        displayName: "Block SD card access",               value: .toggle(false)),
            ]
        ),
        HardeningCategory(
            id: UUID(), name: "Exploit Mitigations", systemImage: "lock.shield",
            settings: [
                .init(id: UUID(), key: "exploit.memory_tagging.enabled",       displayName: "Memory Tagging Extension (MTE)",     value: .toggle(true)),
                .init(id: UUID(), key: "exploit.ptrace.disallow",              displayName: "Disallow ptrace",                    value: .toggle(true)),
                .init(id: UUID(), key: "exploit.jit.disallow",                 displayName: "Disallow JIT compilation",           value: .toggle(false)),
                .init(id: UUID(), key: "exploit.spectre.mitigation",           displayName: "Spectre mitigation level",           value: .option(current: "Full", choices: ["None", "Partial", "Full"])),
                .init(id: UUID(), key: "exploit.webview.renderer_process",     displayName: "WebView renderer process isolation",  value: .toggle(true)),
            ]
        ),
        HardeningCategory(
            id: UUID(), name: "Attestation", systemImage: "checkmark.seal",
            settings: [
                .init(id: UUID(), key: "attestation.verified_boot.status",     displayName: "Verified Boot status",               value: .readOnly("VERIFIED")),
                .init(id: UUID(), key: "attestation.bootloader.locked",        displayName: "Bootloader locked",                  value: .readOnly("true")),
                .init(id: UUID(), key: "attestation.remote.enabled",           displayName: "Remote attestation",                 value: .toggle(false)),
                .init(id: UUID(), key: "attestation.key_rotation.days",        displayName: "Attestation key rotation interval",  value: .option(current: "30 days", choices: ["7 days", "30 days", "90 days"])),
            ]
        ),
    ]
}
