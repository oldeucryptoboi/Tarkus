import SwiftUI

// MARK: - ApprovalDetailView

/// Full detail view for a single approval request, showing tool info,
/// input parameters, and action buttons for all four decision types.
struct ApprovalDetailView: View {

    // MARK: - Properties

    let approval: Approval
    let viewModel: ApprovalsViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                toolInfoSection
                descriptionSection
                inputParametersSection
                sessionInfoSection
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle(approval.permission.tool)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Tool Info

    private var toolInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tool", systemImage: "wrench.and.screwdriver")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(approval.permission.tool)
                .font(.title2.weight(.bold))
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Description", systemImage: "doc.text")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(approval.permission.description)
                .font(.body)
        }
    }

    // MARK: - Input Parameters

    @ViewBuilder
    private var inputParametersSection: some View {
        if let input = approval.permission.input, !input.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Parameters", systemImage: "list.bullet.rectangle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(input.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack(alignment: .top, spacing: 8) {
                            Text(key)
                                .font(.caption.monospaced().weight(.semibold))
                                .foregroundStyle(.blue)
                            Text(formatAnyCodable(value))
                                .font(.caption.monospaced())
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tertiaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Session Info

    private var sessionInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Session", systemImage: "link")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(approval.sessionId)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                decisionButton(
                    title: "Allow Once",
                    decision: .allowOnce,
                    color: .blue,
                    icon: "checkmark.circle"
                )
                decisionButton(
                    title: "Allow Always",
                    decision: .allowAlways,
                    color: .green,
                    icon: "checkmark.shield"
                )
            }
            HStack(spacing: 12) {
                decisionButton(
                    title: "Deny Once",
                    decision: .denyOnce,
                    color: .orange,
                    icon: "hand.raised"
                )
                decisionButton(
                    title: "Deny Always",
                    decision: .denyAlways,
                    color: .red,
                    icon: "xmark.shield"
                )
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Decision Button

    private func decisionButton(
        title: String,
        decision: ApprovalDecision,
        color: Color,
        icon: String
    ) -> some View {
        Button {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
            Task {
                try? await viewModel.submitDecision(
                    approvalId: approval.id,
                    decision: decision
                )
                dismiss()
            }
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }

    // MARK: - Helpers

    private func formatAnyCodable(_ value: AnyCodable) -> String {
        if let string = value.stringValue {
            return "\"\(string)\""
        } else if let int = value.intValue {
            return "\(int)"
        } else if let double = value.doubleValue {
            return "\(double)"
        } else if let bool = value.boolValue {
            return bool ? "true" : "false"
        } else if value.isNil {
            return "null"
        } else {
            return "..."
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ApprovalDetailView(
            approval: Approval(
                id: "approval-1",
                sessionId: "session-abc-123",
                permission: Permission(
                    tool: "Bash",
                    description: "Execute shell command: rm -rf /tmp/build",
                    input: [
                        "command": AnyCodable("rm -rf /tmp/build"),
                        "timeout": AnyCodable(30)
                    ]
                ),
                status: "pending",
                createdAt: Date()
            ),
            viewModel: ApprovalsViewModel(client: KarnEvil9Client(serverConfig: .default))
        )
    }
}
