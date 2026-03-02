import SwiftUI

// MARK: - SettingsView

/// Application settings screen with sections for connection configuration,
/// server health, available tools, and app information.
struct SettingsView: View {

    // MARK: - State

    @State var viewModel: SettingsViewModel
    @State private var showingConnectionSetup = false
    @State private var isConnected = true

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                connectionSection
                serverHealthSection
                debugSection
                aboutSection
                toolsSection
            }
            .navigationTitle("Settings")
            .task {
                await viewModel.checkHealth()
                await viewModel.loadTools()
            }
            .refreshable {
                await viewModel.checkHealth()
                await viewModel.loadTools()
            }
            .sheet(isPresented: $showingConnectionSetup) {
                ConnectionSetupView(isConnected: $isConnected)
            }
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        Section("Connection") {
            HStack {
                Label {
                    VStack(alignment: .leading) {
                        Text("\(viewModel.client.serverConfig.host):\(viewModel.client.serverConfig.port)")
                            .font(.body)
                        Text("Server Address")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "server.rack")
                }

                Spacer()

                Button("Edit") {
                    showingConnectionSetup = true
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Server Health Section

    private var serverHealthSection: some View {
        Section("Server Health") {
            HStack {
                Label {
                    Text("Status")
                } icon: {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else if let isHealthy = viewModel.isHealthy {
                        Image(systemName: isHealthy ? "circle.fill" : "circle.fill")
                            .foregroundStyle(isHealthy ? .green : .red)
                            .font(.caption)
                    } else {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let isHealthy = viewModel.isHealthy {
                    Text(isHealthy ? "Connected" : "Unreachable")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let version = viewModel.serverVersion {
                HStack {
                    Label("Version", systemImage: "tag")
                    Spacer()
                    Text(version)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Tools Section

    private var toolsSection: some View {
        Section {
            NavigationLink {
                List {
                    if viewModel.tools.isEmpty {
                        Text("No tools loaded")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.tools) { tool in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tool.name)
                                    .font(.subheadline.weight(.medium))
                                if let description = tool.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .navigationTitle("Available Tools")
            } label: {
                Label {
                    Text("Available Tools")
                    Spacer()
                    Text("\(viewModel.tools.count)")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "wrench.and.screwdriver")
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("App Version", systemImage: "info.circle")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Build", systemImage: "hammer")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Debug Section

    private var debugSection: some View {
        Section("Debug") {
            NavigationLink {
                MarkdownTestView()
            } label: {
                Label("Markdown A/B Test", systemImage: "doc.richtext")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        viewModel: SettingsViewModel(client: KarnEvil9Client(serverConfig: .default))
    )
}
