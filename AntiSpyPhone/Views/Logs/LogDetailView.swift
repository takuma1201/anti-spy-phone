import SwiftUI

struct LogDetailView: View {
    let event: SecurityEvent
    @State private var copied = false

    private static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("EVENT DETAIL")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(2)

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(event.rawJSON, forType: .string)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Text(copied ? "[ COPIED ]" : "[ COPY JSON ]")
                        .font(NFont.label)
                        .foregroundStyle(copied ? Color.ndSuccess : Color.ndTextSecondary)
                        .tracking(1.5)
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.ndBlack)

            Divider().background(Color.ndBorderVisible)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Type — the single accent moment
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(event.type.color)
                            .frame(width: 3, height: 24)

                        Text(event.type.rawValue)
                            .font(NFont.monoData)
                            .foregroundStyle(event.type.color)
                            .tracking(1)
                    }

                    // Fields — stat row style
                    VStack(spacing: 0) {
                        DetailRow(label: "TIMESTAMP", value: Self.fullFormatter.string(from: event.timestamp))
                        Divider().background(Color.ndBorder)
                        DetailRow(label: "PACKAGE",   value: event.appPackage)
                        Divider().background(Color.ndBorder)
                        DetailRow(label: "DETAIL",    value: event.detail)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.ndBorderVisible, lineWidth: 1))

                    // Raw JSON
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RAW JSON")
                            .font(NFont.label)
                            .foregroundStyle(Color.ndTextDisabled)
                            .tracking(2)

                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(event.rawJSON)
                                .font(NFont.monoBody)
                                .foregroundStyle(Color.ndTextPrimary)
                                .textSelection(.enabled)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color.ndSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.ndBorderVisible, lineWidth: 1)
                        )
                    }
                }
                .padding(20)
            }
        }
        .background(Color.ndSurface)
    }
}

// MARK: - Detail row

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(NFont.label)
                .foregroundStyle(Color.ndTextSecondary)
                .tracking(1.5)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(NFont.monoData)
                .foregroundStyle(Color.ndTextPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
