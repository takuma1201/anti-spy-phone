import SwiftUI

enum TimeRange: String, CaseIterable {
    case hour  = "1H"
    case today = "TODAY"
    case week  = "7D"

    var cutoff: Date {
        switch self {
        case .hour:  return Date().addingTimeInterval(-3600)
        case .today: return Calendar.current.startOfDay(for: Date())
        case .week:  return Date().addingTimeInterval(-604800)
        }
    }
}

struct LogsView: View {
    let device: Device?

    @State private var allEvents: [SecurityEvent] = SecurityEvent.mock(count: 120)
    @State private var selectedEvent: SecurityEvent?
    @State private var timeRange: TimeRange   = .today
    @State private var typeFilter: EventType? = nil

    private var filteredEvents: [SecurityEvent] {
        allEvents.filter { e in
            e.timestamp >= timeRange.cutoff &&
            (typeFilter == nil || e.type == typeFilter)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().background(Color.ndBorderVisible)

            HSplitView {
                eventList.frame(minWidth: 480)

                if let event = selectedEvent {
                    LogDetailView(event: event).frame(minWidth: 300)
                } else {
                    emptyDetail.frame(minWidth: 300)
                }
            }
        }
        .background(Color.ndBlack)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 20) {
            // Time range — Nothing segmented control style
            HStack(spacing: 0) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button {
                        timeRange = range
                    } label: {
                        Text(range.rawValue)
                            .font(NFont.label)
                            .foregroundStyle(timeRange == range ? Color.ndBlack : Color.ndTextSecondary)
                            .tracking(2)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(timeRange == range ? Color.ndTextDisplay : Color.clear)
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(Color.ndBorderVisible, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 999))

            Rectangle().fill(Color.ndBorderVisible).frame(width: 1, height: 18)

            // Type filter chips — Nothing tag style (border only)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    NothingChip(label: "ALL", isSelected: typeFilter == nil) {
                        typeFilter = nil
                    }
                    ForEach(EventType.allCases) { type in
                        NothingChip(
                            label: type.label,
                            valueColor: type.color,
                            isSelected: typeFilter == type
                        ) {
                            typeFilter = typeFilter == type ? nil : type
                        }
                    }
                }
            }

            Spacer()

            // Event count
            Text("\(filteredEvents.count) EVENTS")
                .font(NFont.label)
                .foregroundStyle(Color.ndTextDisabled)
                .tracking(2)

            // Export
            Button {
                let text = filteredEvents.map { "[\($0.timestamp)] \($0.type.rawValue) \($0.appPackage) \($0.detail)" }
                    .joined(separator: "\n")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            } label: {
                Text("[ EXPORT ]")
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextSecondary)
                    .tracking(1.5)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.ndBlack)
    }

    // MARK: - Event list

    private var eventList: some View {
        List(filteredEvents, selection: $selectedEvent) { event in
            LogEventRow(event: event)
                .tag(event)
                .listRowBackground(
                    selectedEvent?.id == event.id
                        ? Color.ndSurface
                        : Color.ndBlack
                )
                .listRowSeparatorTint(Color.ndBorder)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.ndBlack)
    }

    // MARK: - Empty detail

    private var emptyDetail: some View {
        VStack(spacing: 8) {
            Text("SELECT AN EVENT")
                .font(NFont.label)
                .foregroundStyle(Color.ndTextDisabled)
                .tracking(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ndSurface)
    }
}

// MARK: - Nothing chip (border-only tag)

private struct NothingChip: View {
    let label: String
    var valueColor: Color = .ndTextSecondary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(NFont.label)
                .tracking(1.5)
                .foregroundStyle(isSelected ? valueColor : Color.ndTextDisabled)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .overlay(
                    Capsule().stroke(
                        isSelected ? valueColor.opacity(0.6) : Color.ndBorderVisible,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }
}

// MARK: - Event row

struct LogEventRow: View {
    let event: SecurityEvent

    private static let tsFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            // Accent bar for sandbox violations
            Rectangle()
                .fill(event.type == .sandboxViolation ? Color.ndAccent : Color.clear)
                .frame(width: 2)

            HStack(spacing: 14) {
                // Timestamp — TERTIARY
                Text(Self.tsFormatter.string(from: event.timestamp))
                    .font(NFont.label)
                    .foregroundStyle(Color.ndTextDisabled)
                    .tracking(1)
                    .frame(width: 56, alignment: .leading)

                // Type badge — value color
                Text(event.type.label)
                    .font(NFont.label)
                    .foregroundStyle(event.type.color)
                    .tracking(1)
                    .frame(width: 72, alignment: .leading)

                // Package — SECONDARY
                Text(event.appPackage)
                    .font(NFont.monoData)
                    .foregroundStyle(Color.ndTextSecondary)
                    .lineLimit(1)
                    .frame(width: 190, alignment: .leading)

                // Detail — PRIMARY
                Text(event.detail)
                    .font(NFont.bodySM)
                    .foregroundStyle(Color.ndTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
    }
}
