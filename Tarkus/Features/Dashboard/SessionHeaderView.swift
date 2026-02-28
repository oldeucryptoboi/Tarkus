import SwiftUI

// MARK: - SessionHeaderView

/// Compact header displaying the current session's state badge,
/// task description, and auto-updating elapsed time.
struct SessionHeaderView: View {

    // MARK: - Properties

    let session: Session

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                stateBadge
                Spacer()
                elapsedTimeView
            }

            Text(session.task)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - State Badge

    private var stateBadge: some View {
        Text(session.state.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch session.state {
        case .running:
            return .green
        case .planning:
            return .purple
        case .live:
            return .green
        case .paused:
            return .yellow
        case .failed:
            return .red
        case .completed:
            return .blue
        case .aborted:
            return .red
        case .unknown:
            return .gray
        }
    }

    // MARK: - Elapsed Time

    private var elapsedTimeView: some View {
        TimelineView(.periodic(from: session.createdAt, by: 1.0)) { context in
            let elapsed = context.date.timeIntervalSince(session.createdAt)
            Text(Self.formatElapsed(elapsed))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private static func formatElapsed(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

#Preview {
    SessionHeaderView(
        session: Session(
            id: "preview-1",
            task: "Refactor the authentication module to use async/await patterns",
            state: .running,
            createdAt: Date().addingTimeInterval(-125),
            updatedAt: Date()
        )
    )
}
