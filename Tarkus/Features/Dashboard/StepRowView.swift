import SwiftUI

// MARK: - EventRowView

/// A single row in the event timeline representing one journal event.
/// Displays a type icon, event type label, optional payload summary,
/// and timestamp.
struct EventRowView: View {

    // MARK: - Properties

    let event: JournalEvent

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            eventIcon
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.typeLabel)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text(event.timestamp, style: .time)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if let summary = event.payloadSummary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Event Icon

    @ViewBuilder
    private var eventIcon: some View {
        let type = event.type

        if type.hasSuffix(".completed") || type.hasSuffix(".plan_generated") {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
        } else if type.hasSuffix(".failed") || type.hasSuffix(".aborted") {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.title3)
        } else if type.hasSuffix(".started") || type.hasSuffix(".requested") {
            Image(systemName: "arrow.clockwise.circle.fill")
                .foregroundStyle(.blue)
                .font(.title3)
        } else if type.hasPrefix("planner.") {
            Image(systemName: "map.circle.fill")
                .foregroundStyle(.purple)
                .font(.title3)
        } else if type.hasPrefix("approval.") {
            Image(systemName: "hand.raised.circle.fill")
                .foregroundStyle(.orange)
                .font(.title3)
        } else if type.hasPrefix("session.") {
            Image(systemName: "bolt.circle.fill")
                .foregroundStyle(.teal)
                .font(.title3)
        } else {
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
                .font(.title3)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        EventRowView(event: JournalEvent(
            eventId: "1", timestamp: Date().addingTimeInterval(-60),
            sessionId: "s1", type: "session.created",
            payload: ["task": AnyCodable("Build API")], seq: 1
        ))
        Divider().padding(.leading, 52)
        EventRowView(event: JournalEvent(
            eventId: "2", timestamp: Date().addingTimeInterval(-50),
            sessionId: "s1", type: "planner.plan_generated",
            payload: ["plan": AnyCodable("1. Read files\n2. Edit code")], seq: 2
        ))
        Divider().padding(.leading, 52)
        EventRowView(event: JournalEvent(
            eventId: "3", timestamp: Date().addingTimeInterval(-40),
            sessionId: "s1", type: "step.started",
            payload: ["tool": AnyCodable("Read")], seq: 3
        ))
        Divider().padding(.leading, 52)
        EventRowView(event: JournalEvent(
            eventId: "4", timestamp: Date().addingTimeInterval(-30),
            sessionId: "s1", type: "step.completed",
            payload: ["tool": AnyCodable("Read")], seq: 4
        ))
        Divider().padding(.leading, 52)
        EventRowView(event: JournalEvent(
            eventId: "5", timestamp: Date().addingTimeInterval(-20),
            sessionId: "s1", type: "approval.requested",
            payload: ["tool": AnyCodable("Bash")], seq: 5
        ))
    }
}
