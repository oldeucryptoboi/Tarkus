import SwiftUI

// MARK: - ConnectionSetupView

/// First-run screen that collects server host, port, and API token,
/// then validates the connection before allowing the user to proceed.
struct ConnectionSetupView: View {

    // MARK: - State

    @State private var viewModel = ConnectionViewModel()
    @Binding var isConnected: Bool

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

                // Connection fields
                Section("Server") {
                    TextField("Host (e.g. 192.168.1.50)", text: $viewModel.host)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    TextField("Port", text: $viewModel.port)
                        .keyboardType(.numberPad)
                }

                Section("Authentication") {
                    SecureField("API Token", text: $viewModel.token)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
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
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    ConnectionSetupView(isConnected: .constant(false))
}
