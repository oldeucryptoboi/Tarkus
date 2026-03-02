import SwiftUI

// MARK: - MessageBubbleView

/// Renders a single chat message as a styled bubble. User messages appear
/// right-aligned with a tinted background; EDDIE's responses appear left-aligned
/// with an avatar, step activity disclosure, and inline approval cards.
struct MessageBubbleView: View {

    // MARK: - Properties

    let message: ChatMessage
    var onApproval: ((String, ApprovalDecision) -> Void)?

    // MARK: - Body

    var body: some View {
        switch message.role {
        case .user:
            userBubble
        case .assistant:
            assistantBubble
        case .system:
            systemBubble
        }
    }

    // MARK: - User Bubble

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 60)

            Text(message.text)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.secondary.opacity(0.2))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Assistant Bubble

    private var assistantBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            if message.status == .thinking {
                thinkingIndicator

                if !message.steps.isEmpty {
                    stepsDisclosure
                }

                if let approval = message.approval, !approval.isResolved {
                    approvalCard(approval)
                }
            } else if message.status == .streaming {
                if !message.text.isEmpty {
                    MarkdownText(content: message.text, streaming: true)
                }

                if !message.steps.isEmpty {
                    stepsDisclosure
                }
            } else {
                if !message.text.isEmpty {
                    if message.status == .failed {
                        Label(message.text, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    } else {
                        MarkdownText(content: message.text)
                    }
                } else if message.status == .failed {
                    Label("Something went wrong", systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                if !message.steps.isEmpty {
                    stepsDisclosure
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - System Bubble

    private var systemBubble: some View {
        HStack {
            Spacer()
            Text(message.text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Thinking Indicator

    private var thinkingIndicator: some View {
        HStack(spacing: 4) {
            Text("EDDIE is thinking")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ThinkingDotsView()
        }
    }

    // MARK: - Steps Disclosure

    private var stepsDisclosure: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(message.steps) { step in
                    HStack(spacing: 8) {
                        stepStatusIcon(step.status)
                            .frame(width: 16, height: 16)

                        Text(step.tool)
                            .font(.caption.weight(.semibold))

                        if let output = step.output {
                            Text(output)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.top, 4)
        } label: {
            HStack(spacing: 4) {
                Text("\(message.steps.count) step\(message.steps.count == 1 ? "" : "s")")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                if message.steps.contains(where: { $0.status == .running }) {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
        }
        .font(.caption)
    }

    // MARK: - Approval Card

    private func approvalCard(_ approval: InlineApproval) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "hand.raised.circle.fill")
                    .foregroundStyle(.orange)
                Text("Permission Required")
                    .font(.subheadline.weight(.semibold))
            }

            Text("\(approval.tool): \(approval.description)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button {
                    onApproval?(approval.id, .allowOnce)
                } label: {
                    Label("Allow", systemImage: "checkmark.circle")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Button {
                    onApproval?(approval.id, .denyOnce)
                } label: {
                    Label("Deny", systemImage: "xmark.circle")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(10)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func stepStatusIcon(_ status: StepInfo.StepStatus) -> some View {
        switch status {
        case .running:
            ProgressView()
                .scaleEffect(0.5)
        case .succeeded:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption2)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption2)
        }
    }
}

// MARK: - ThinkingDotsView

/// Animated dots that indicate EDDIE is working.
struct ThinkingDotsView: View {

    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 5, height: 5)
                    .opacity(phase == index ? 1.0 : 0.3)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    phase = (phase + 1) % 3
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            MessageBubbleView(message: .user("How are the Moltbook posts performing?"))

            MessageBubbleView(message: ChatMessage(
                id: UUID(),
                role: .assistant,
                text: "",
                timestamp: Date(),
                sessionId: "s1",
                status: .thinking,
                steps: [
                    StepInfo(id: "1", stepId: "step-01", title: "Reading data", tool: "Read", status: .succeeded, output: "moltbook_posts.json"),
                    StepInfo(id: "2", stepId: "step-02", title: "Analyzing", tool: "Bash", status: .running, output: nil)
                ],
                approval: nil
            ))

            MessageBubbleView(message: ChatMessage(
                id: UUID(),
                role: .assistant,
                text: "Your Moltbook posts are performing well! The latest post got 1,200 views.",
                timestamp: Date(),
                sessionId: "s1",
                status: .completed,
                steps: [],
                approval: nil
            ))

            MessageBubbleView(message: .system("Connected to EDDIE"))
        }
    }
}
