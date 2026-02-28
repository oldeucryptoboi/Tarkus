import SwiftUI

// MARK: - EventTimelineView

/// Scrollable timeline of session journal events that auto-scrolls to the
/// latest entry as new events arrive.
struct EventTimelineView: View {

    // MARK: - Properties

    var events: [JournalEvent]

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(events) { event in
                        EventRowView(event: event)
                            .id(event.id)
                        if event.id != events.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .onChange(of: events.count) { _, _ in
                if let lastEvent = events.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastEvent.id, anchor: .bottom)
                    }
                }
            }
            .overlay {
                if events.isEmpty {
                    ContentUnavailableView {
                        Label("No Events Yet", systemImage: "list.bullet.circle")
                    } description: {
                        Text("Events will appear here as the session progresses.")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EventTimelineView(events: [
        JournalEvent(
            eventId: "evt-1",
            timestamp: Date().addingTimeInterval(-10),
            sessionId: "sess-1",
            type: "session.created",
            payload: ["task": AnyCodable("Build a REST API")],
            seq: 1
        ),
        JournalEvent(
            eventId: "evt-2",
            timestamp: Date().addingTimeInterval(-5),
            sessionId: "sess-1",
            type: "step.started",
            payload: ["tool": AnyCodable("Read")],
            seq: 2
        ),
    ])
}
