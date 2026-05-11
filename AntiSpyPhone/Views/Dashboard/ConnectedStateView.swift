import SwiftUI

struct ConnectedStateView: View {
    let device: Device

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Device header bar ─────────────────────────────────
                deviceHeader

                Divider().background(Color.ndBorderVisible)

                // ── Body: two-column layout ───────────────────────────
                HStack(alignment: .top, spacing: 0) {
                    // Left column: hero metric + stat rows
                    VStack(alignment: .leading, spacing: 0) {
                        latencyHero
                        Divider().background(Color.ndBorder)
                        statRows
                    }
                    .frame(maxWidth: .infinity)

                    Divider().background(Color.ndBorderVisible)
                        .frame(width: 1)
                        .padding(.vertical, 0)

                    // Right column: quick status panel
                    quickStatusPanel
                        .frame(width: 280)
                }
            }
        }
        .background(Color.ndBlack)
    }

    // MARK: - Device header

    private var deviceHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                // PRIMARY row
                HStack(spacing: 12) {
                    Text(device.name.uppercased())
                        .font(NFont.heading)
                        .foregroundStyle(Color.ndTextDisplay)
                        .tracking(0.5)

                    // LIVE pill
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.ndSuccess)
                            .frame(width: 5, height: 5)
                        Text("LIVE")
                            .font(NFont.label)
                            .foregroundStyle(Color.ndSuccess)
                            .tracking(2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .overlay(Capsule().stroke(Color.ndSuccess.opacity(0.4), lineWidth: 1))
                }

                // TERTIARY row
                Text(device.serialNumber)
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(1.5)
            }

            Spacer()

            // Sync time
            VStack(alignment: .trailing, spacing: 3) {
                Text("LAST SYNC")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(2)
                Text(device.lastSeen, style: .relative)
                    .font(NFont.monoData)
                    .foregroundStyle(Color.ndTextSecondary)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
    }

    // MARK: - Latency hero (the PRIMARY element — Doto hero number)

    private var latencyHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ADB LATENCY")
                .font(NFont.label)
                .foregroundStyle(Color.ndTextSecondary)
                .tracking(2)
                .padding(.horizontal, 32)
                .padding(.top, 32)
                .padding(.bottom, 12)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(device.adbLatency.map { "\($0)" } ?? "—")
                    .font(NFont.displayXL)
                    .foregroundStyle(Color.ndTextDisplay)
                    .tracking(-2)

                Text("MS")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextSecondary)
                    .tracking(2)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Stat rows (SECONDARY — data table)

    private var statRows: some View {
        VStack(spacing: 0) {
            ForEach(stats, id: \.0) { label, value, status in
                StatRow(label: label, value: value, status: status)
                Divider().background(Color.ndBorder)
            }

            // CTA row
            HStack {
                Text("MANAGE HARDENING SETTINGS")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndInteractive)
                    .tracking(1.5)
                Spacer()
                Text("→")
                    .font(NFont.mono(12))
                    .foregroundStyle(Color.ndInteractive)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .pointingHandCursor()
        }
    }

    private var stats: [(String, String, StatStatus)] {
        [
            ("GRAPHENEOS VERSION", device.grapheneOSVersionDisplay, .neutral),
            ("VERIFIED BOOT",      "VERIFIED",                      .good),
            ("BOOTLOADER",         "LOCKED",                        .good),
            ("MTE (MEMORY TAG)",   "ENABLED",                       .good),
            ("ALWAYS-ON VPN",      "ACTIVE",                        .good),
        ]
    }

    // MARK: - Quick status panel (TERTIARY)

    private var quickStatusPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SECURITY STATUS")
                .font(NFont.label)
                .foregroundStyle(Color.ndTextSecondary)
                .tracking(2)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 16)

            ForEach(quickItems, id: \.0) { label, enabled in
                QuickStatusRow(label: label, enabled: enabled)
                Divider().background(Color.ndBorder)
            }
        }
    }

    private var quickItems: [(String, Bool)] {
        [
            ("SENSOR KILL SWITCH",   false),
            ("CONNECTIVITY CHECK",   false),
            ("JIT COMPILATION",      false),
            ("CONTACT SCOPES",       true),
            ("STORAGE SCOPES",       true),
            ("REMOTE ATTESTATION",   false),
            ("EXPLOIT PROTECTION",   true),
            ("NETWORK SANDBOX",      true),
        ]
    }
}

// MARK: - Stat row

enum StatStatus { case good, warning, bad, neutral }

private struct StatRow: View {
    let label: String
    let value: String
    let status: StatStatus

    var valueColor: Color {
        switch status {
        case .good:    return .ndSuccess
        case .warning: return .ndWarning
        case .bad:     return .ndAccent
        case .neutral: return .ndTextPrimary
        }
    }

    var body: some View {
        HStack {
            Text(label)
                .font(NFont.label)
                .foregroundStyle(Color.ndTextSecondary)
                .tracking(1.5)
            Spacer()
            Text(value)
                .font(NFont.monoData)
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

// MARK: - Quick status row

private struct QuickStatusRow: View {
    let label: String
    let enabled: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(NFont.label)
                .foregroundStyle(Color.ndTextSecondary)
                .tracking(1.5)
            Spacer()
            Text(enabled ? "ON" : "OFF")
                .font(NFont.label)
                .foregroundStyle(enabled ? Color.ndSuccess : Color.ndTextDisabled)
                .tracking(2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}
