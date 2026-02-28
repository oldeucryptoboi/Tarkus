import SwiftUI

// MARK: - SessionDetailView

/// Detailed view for a single session, showing header info, journal steps,
/// and usage metrics.
struct SessionDetailView: View {

    // MARK: - Properties

    let session: Session
    let client: KarnEvil9Client

    @State private var steps: [Step] = []
    @State private var isLoadingSteps = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                stepsSection
                metricsSection

                if session.state.isActive {
                    monitorButton
                }
            }
            .padding()
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadJournal()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                stateBadge
                Spacer()
                if let plugin = session.plugin {
                    Label(plugin, systemImage: "puzzlepiece")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(session.task)
                .font(.body)

            HStack(spacing: 16) {
                Label {
                    Text(session.createdAt, style: .date)
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Label {
                    Text(session.updatedAt, style: .relative)
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

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
        case .running: return .green
        case .paused: return .yellow
        case .failed: return .red
        case .completed: return .blue
        case .waitingForApproval: return .orange
        case .idle: return .gray
        case .aborted: return .red
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Journal")
                    .font(.headline)
                Spacer()
                if isLoadingSteps {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if steps.isEmpty && !isLoadingSteps {
                Text("No steps recorded.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(steps) { step in
                        StepRowView(step: step)
                        if step.id != steps.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Metrics

    @ViewBuilder
    private var metricsSection: some View {
        if let usage = session.usage {
            VStack(alignment: .leading, spacing: 8) {
                Text("Usage")
                    .font(.headline)

                VStack(spacing: 8) {
                    metricRow("Input Tokens", value: "\(usage.inputTokens)")
                    metricRow("Output Tokens", value: "\(usage.outputTokens)")
                    metricRow("Cache Read", value: "\(usage.cacheReadTokens)")
                    metricRow("Cache Write", value: "\(usage.cacheWriteTokens)")
                    Divider()
                    metricRow("Total Cost", value: String(format: "$%.4f", usage.totalCost))
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func metricRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
        }
    }

    // MARK: - Monitor Button

    private var monitorButton: some View {
        NavigationLink {
            let sseClient = SSEClient(serverConfig: client.serverConfig)
            let dashboardVM = DashboardViewModel(client: client, sseClient: sseClient)
            DashboardView(viewModel: dashboardVM)
                .task {
                    await dashboardVM.startMonitoring(sessionId: session.id)
                }
        } label: {
            Label("Monitor Live", systemImage: "waveform.path.ecg")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
    }

    // MARK: - Data Loading

    @MainActor
    private func loadJournal() async {
        isLoadingSteps = true
        do {
            steps = try await client.getSessionJournal(id: session.id)
        } catch {
            // Steps remain empty on failure
        }
        isLoadingSteps = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SessionDetailView(
            session: Session(
                id: "session-1",
                task: "Refactor the authentication module to use modern async/await patterns",
                state: .running,
                plugin: "code-review",
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date(),
                usage: UsageMetrics(
                    inputTokens: 15000,
                    outputTokens: 4200,
                    cacheReadTokens: 8000,
                    cacheWriteTokens: 1200,
                    totalCost: 0.0521
                ),
                stepCount: 12
            ),
            client: KarnEvil9Client(serverConfig: .default)
        )
    }
}
