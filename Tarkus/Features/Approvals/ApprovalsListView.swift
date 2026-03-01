import SwiftUI

// MARK: - ApprovalsListView

/// List of pending tool approval requests with swipe actions for quick
/// allow/deny decisions and pull-to-refresh support.
struct ApprovalsListView: View {

    // MARK: - State

    @State var viewModel: ApprovalsViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.approvals.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    approvalsList
                }
            }
            .navigationTitle("Approvals")
            .refreshable {
                await viewModel.loadApprovals()
            }
            .task {
                await viewModel.loadApprovals()
            }
            .overlay {
                if viewModel.isLoading && viewModel.approvals.isEmpty {
                    ProgressView("Loading approvals...")
                }
            }
        }
    }

    // MARK: - List

    private var approvalsList: some View {
        List {
            ForEach(viewModel.approvals) { approval in
                NavigationLink {
                    ApprovalDetailView(
                        approval: approval,
                        viewModel: viewModel
                    )
                } label: {
                    approvalRow(approval)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        Task {
                            try? await viewModel.submitDecision(
                                approvalId: approval.id,
                                decision: .denyOnce
                            )
                        }
                    } label: {
                        Label("Deny", systemImage: "xmark.circle")
                    }
                    .tint(.red)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        Task {
                            try? await viewModel.submitDecision(
                                approvalId: approval.id,
                                decision: .allowOnce
                            )
                        }
                    } label: {
                        Label("Allow", systemImage: "checkmark.circle")
                    }
                    .tint(.green)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }

    // MARK: - Row

    private func approvalRow(_ approval: Approval) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(approval.permission.tool)
                .font(.headline)

            Text(approval.permission.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(approval.createdAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Pending Approvals", systemImage: "checkmark.shield")
        } description: {
            Text("When a tool requires permission, approval requests will appear here.")
        }
    }
}

// MARK: - Preview

#Preview {
    let client = KarnEvil9Client(serverConfig: .default)
    ApprovalsListView(viewModel: ApprovalsViewModel(client: client))
}
