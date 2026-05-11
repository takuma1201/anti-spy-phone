import SwiftUI

struct DisconnectedStateView: View {
    let device: Device?

    var body: some View {
        ZStack {
            Color.ndBlack.ignoresSafeArea()

            // Dot-grid — the "empty instrument panel" feel
            DotGridBackground(spacing: 16, dotSize: 1, opacity: 0.08)

            VStack(spacing: 0) {
                Spacer()

                // PRIMARY — "NO DEVICE" as Doto hero
                VStack(spacing: 8) {
                    Text("NO")
                        .font(NFont.displayXL)
                        .foregroundStyle(Color.ndTextDisabled)
                        .tracking(-2)
                    Text("DEVICE")
                        .font(NFont.displayXL)
                        .foregroundStyle(Color.ndTextDisabled)
                        .tracking(-2)
                }

                Spacer().frame(height: 48)

                // SECONDARY — instruction
                Text("USB ケーブルでデバイスを接続してください")
                    .font(NFont.body)
                    .foregroundStyle(Color.ndTextPrimary)

                Spacer().frame(height: 8)

                // TERTIARY — system label
                Text("CONNECT VIA USB TO BEGIN")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(2)

                Spacer().frame(height: 40)

                // Last seen device (if any)
                if let device {
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(Color.ndBorderVisible)
                            .frame(width: 1, height: 20)

                        Text("LAST SEEN")
                            .font(NFont.label)
                            .foregroundStyle(Color.ndTextDisabled)
                            .tracking(2)

                        Text(device.name.uppercased())
                            .font(NFont.mono(11))
                            .foregroundStyle(Color.ndTextSecondary)
                            .tracking(1)

                        Text("·")
                            .foregroundStyle(Color.ndTextDisabled)

                        Text(device.lastSeen, style: .relative)
                            .font(NFont.label)
                            .foregroundStyle(Color.ndTextDisabled)
                            .tracking(1)

                        Text("AGO")
                            .font(NFont.label)
                            .foregroundStyle(Color.ndTextDisabled)
                            .tracking(2)
                    }
                }

                Spacer()
            }
            .padding(48)
        }
    }
}
