import SwiftUI

// MARK: - StepRowView

/// A single row in the step timeline representing one unit of work.
/// Displays a status icon, tool name, optional assistant message preview,
/// and duration.
struct StepRowView: View {

    // MARK: - Properties

    let step: Step

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            statusIcon
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let toolCall = step.toolCall {
                        Text(toolCall.tool)
                            .font(.subheadline.weight(.semibold))
                    } else {
                        Text("Step \(step.index + 1)")
                            .font(.subheadline.weight(.semibold))
                    }

                    Spacer()

                    if let duration = step.duration {
                        Text(Self.formatDuration(duration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else if step.state == .running {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }

                if let message = step.assistantMessage, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let toolResult = step.toolResult, toolResult.isError,
                   let errorText = toolResult.error {
                    Text(errorText)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        switch step.state {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.title3)
        case .running:
            Image(systemName: "arrow.clockwise.circle.fill")
                .foregroundStyle(.blue)
                .font(.title3)
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
                .font(.title3)
        }
    }

    // MARK: - Helpers

    private static func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 1 {
            return String(format: "%.0fms", seconds * 1000)
        } else if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return "\(minutes)m \(secs)s"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        StepRowView(step: Step(
            id: "1", index: 0, state: .completed,
            toolCall: ToolCall(id: "tc-1", tool: "Read", input: [:]),
            assistantMessage: "Reading the configuration file to understand the project structure.",
            duration: 1.2
        ))
        Divider().padding(.leading, 52)
        StepRowView(step: Step(
            id: "2", index: 1, state: .running,
            toolCall: ToolCall(id: "tc-2", tool: "Edit", input: [:]),
            startedAt: Date()
        ))
        Divider().padding(.leading, 52)
        StepRowView(step: Step(
            id: "3", index: 2, state: .failed,
            toolCall: ToolCall(id: "tc-3", tool: "Bash", input: [:]),
            toolResult: ToolResult(id: "tr-3", output: nil, error: "Command failed with exit code 1", isError: true),
            duration: 0.5
        ))
        Divider().padding(.leading, 52)
        StepRowView(step: Step(
            id: "4", index: 3, state: .pending
        ))
    }
}
