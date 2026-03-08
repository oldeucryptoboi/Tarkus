import SwiftUI

// MARK: - ChatInputBar

/// Bottom input bar for composing messages to EDDIE. Features a multiline
/// text field, send button, and connection status indicator.
struct ChatInputBar: View {

    // MARK: - Bindings

    @Binding var text: String
    let onSend: () -> Void

    // MARK: - State

    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 8) {
                // Text field
                TextField("Ask EDDIE...", text: $text, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(1...6)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .padding(10)
                    .background(Color.tertiaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .onSubmit {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSend()
                        }
                    }

                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? Color.blue : Color.secondary)
                }
                .disabled(!canSend)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    // MARK: - Computed

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        ChatInputBar(
            text: .constant(""),
            onSend: {}
        )
    }
}
