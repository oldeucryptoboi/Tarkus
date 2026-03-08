import SwiftUI

// MARK: - ConnectionSetupView

/// First-run screen that collects server host, port, and API token,
/// then validates the connection before allowing the user to proceed.
struct ConnectionSetupView: View {

    // MARK: - State

    @State private var viewModel = ConnectionViewModel()
    @Binding var isConnected: Bool
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Branding header
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.accentColor)
                        Text("Tarkus")
                            .font(.largeTitle.bold())
                        Text("Connect to EDDIE (KarnEvil9)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                // Discovered servers
                if !viewModel.bonjourBrowser.servers.isEmpty {
                    Section("Discovered Servers") {
                        ForEach(viewModel.bonjourBrowser.servers) { server in
                            Button {
                                viewModel.selectServer(server)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(server.name)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        Text("\(server.host):\(server.port)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if viewModel.host == server.host
                                        && viewModel.port == "\(server.port)" {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                } else if viewModel.bonjourBrowser.isSearching {
                    Section("Discovered Servers") {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Scanning for servers...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Connection fields
                Section("Server") {
                    TextField("Host", text: $viewModel.host)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif

                    TextField("Port", text: $viewModel.port)
                        #if os(iOS)
                        .keyboardType(.asciiCapableNumberPad)
                        #endif
                }

                Section {
                    SecureField("API Token", text: $viewModel.token)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                } header: {
                    Text("Authentication")
                } footer: {
                    Text("Optional. Only needed if the server requires a token.")
                }

                // Validation status
                if let isValid = viewModel.isValid {
                    Section {
                        HStack {
                            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(isValid ? .green : .red)
                                .font(.title3)
                            Text(isValid ? "Connection successful" : "Connection failed")
                                .foregroundColor(isValid ? .primary : .red)
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                // Connect button
                Section {
                    Button {
                        Task {
                            await viewModel.validate()
                            if viewModel.isValid == true {
                                isConnected = true
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isValidating {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Validating...")
                            } else {
                                Text("Connect")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.canValidate || viewModel.isValidating)
                }
            }
            .navigationTitle("Setup")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 12)
            .task {
                viewModel.startDiscovery()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ConnectionSetupView(isConnected: .constant(false))
}
