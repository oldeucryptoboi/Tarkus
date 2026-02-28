import Foundation

// MARK: - ApprovalsViewModel

/// ViewModel that manages the list of pending approval requests
/// and supports submitting decisions.
@Observable
class ApprovalsViewModel {

    // MARK: - Properties

    var approvals: [Approval] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let client: KarnEvil9Client

    // MARK: - Initialization

    init(client: KarnEvil9Client) {
        self.client = client
    }

    // MARK: - Computed Properties

    /// The number of approvals still in the pending state.
    var pendingCount: Int {
        approvals.filter { $0.status == "pending" }.count
    }

    // MARK: - Actions

    /// Fetches the current list of approval requests from the server.
    @MainActor
    func loadApprovals() async {
        isLoading = true
        errorMessage = nil

        do {
            approvals = try await client.listApprovals()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Submits a user decision for a specific approval and refreshes the list.
    @MainActor
    func submitDecision(approvalId: String, decision: ApprovalDecision) async throws {
        try await client.submitApproval(id: approvalId, decision: decision)

        // Remove the resolved approval from the local list
        approvals.removeAll { $0.id == approvalId }
    }
}
