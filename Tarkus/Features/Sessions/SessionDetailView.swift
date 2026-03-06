import SwiftUI

// MARK: - SessionDetailView

/// Detailed view for a single session, showing header info and journal events.
struct SessionDetailView: View {

    // MARK: - Properties

    let session: Session
    let client: KarnEvil9Client

    @State private var events: [JournalEvent] = []
    @State private var isLoadingEvents = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                eventsSection

                if session.state.isActive {
                    monitorButton
                }
            }
            .padding()
        }
        .navigationTitle("Session")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
                if let mode = session.mode {
                    Label(mode, systemImage: "gearshape")
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
        .background(Color.secondaryGroupedBackground)
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
        case .planning: return .purple
        case .live: return .green
        case .paused: return .yellow
        case .failed: return .red
        case .completed: return .blue
        case .aborted: return .red
        case .unknown: return .gray
        }
    }

    // MARK: - Events

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Journal")
                    .font(.headline)
                Spacer()
                if isLoadingEvents {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if events.isEmpty && !isLoadingEvents {
                Text("No events recorded.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(events) { event in
                        EventRowView(event: event)
                        if event.id != events.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color.secondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Monitor Button

    private var monitorButton: some View {
        NavigationLink {
            let sseClient = SSEClient(serverConfig: client.serverConfig)
            let dashboardVM = DashboardViewModel(client: client, sseClient: sseClient)
            DashboardView(viewModel: dashboardVM)
                .task {
                    await dashboardVM.startMonitoring(session: session)
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
        isLoadingEvents = true
        do {
            events = try await client.getSessionJournal(id: session.id)
        } catch {
            // Events remain empty on failure
        }
        isLoadingEvents = false
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
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date()
            ),
            client: KarnEvil9Client(serverConfig: .default)
        )
    }
}
