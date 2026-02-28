import SwiftUI

// MARK: - NewSessionView

/// Sheet form for creating a new KarnEvil9 session with a task description.
struct NewSessionView: View {

    // MARK: - State

    @State var viewModel: NewSessionViewModel
    @Environment(\.dismiss) private var dismiss

    /// Callback invoked with the newly created session on success.
    var onCreated: ((Session) -> Void)?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Task description
                Section("Task") {
                    TextField("Describe the task...", text: $viewModel.task, axis: .vertical)
                        .lineLimit(3...8)
                }

                // Error display
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                // Submit button
                Section {
                    Button {
                        Task {
                            do {
                                let session = try await viewModel.createSession()
                                onCreated?(session)
                            } catch {
                                // Error is displayed via viewModel.errorMessage
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Creating...")
                            } else {
                                Text("Create Session")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!viewModel.canCreate || viewModel.isLoading)
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NewSessionView(
        viewModel: NewSessionViewModel(client: KarnEvil9Client(serverConfig: .default))
    )
}
