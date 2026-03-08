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
    @State private var history: [String] = []
    @State private var historyIndex: Int = -1
    @State private var draft: String = ""

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
                    .onKeyPress(.upArrow) {
                        guard !history.isEmpty else { return .ignored }
                        if historyIndex == -1 {
                            draft = text
                            historyIndex = history.count - 1
                        } else if historyIndex > 0 {
                            historyIndex -= 1
                        }
                        text = history[historyIndex]
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        guard historyIndex != -1 else { return .ignored }
                        historyIndex += 1
                        if historyIndex >= history.count {
                            historyIndex = -1
                            text = draft
                        } else {
                            text = history[historyIndex]
                        }
                        return .handled
                    }
                    .onSubmit {
                        sendWithHistory()
                    }

                // Send button
                Button(action: sendWithHistory) {
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

    private func sendWithHistory() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        history.append(trimmed)
        historyIndex = -1
        draft = ""
        onSend()
    }

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
