import SwiftUI

// MARK: - StepTimelineView

/// Scrollable timeline of session steps that auto-scrolls to the latest
/// entry as new steps arrive.
struct StepTimelineView: View {

    // MARK: - Properties

    var steps: [Step]

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(steps) { step in
                        StepRowView(step: step)
                            .id(step.id)
                        if step.id != steps.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .onChange(of: steps.count) { _, _ in
                if let lastStep = steps.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastStep.id, anchor: .bottom)
                    }
                }
            }
            .overlay {
                if steps.isEmpty {
                    ContentUnavailableView {
                        Label("No Steps Yet", systemImage: "list.bullet.circle")
                    } description: {
                        Text("Steps will appear here as the session progresses.")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StepTimelineView(steps: [
        Step(
            id: "step-1",
            index: 0,
            state: .completed,
            toolCall: ToolCall(id: "tc-1", tool: "Read", input: ["path": AnyCodable("/src/main.swift")]),
            assistantMessage: "Reading the main entry point...",
            startedAt: Date().addingTimeInterval(-10),
            completedAt: Date().addingTimeInterval(-5),
            duration: 5.0
        ),
        Step(
            id: "step-2",
            index: 1,
            state: .running,
            toolCall: ToolCall(id: "tc-2", tool: "Edit", input: ["path": AnyCodable("/src/auth.swift")]),
            startedAt: Date().addingTimeInterval(-2)
        ),
    ])
}
