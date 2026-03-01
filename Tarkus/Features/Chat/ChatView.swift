import SwiftUI

// MARK: - ChatView

/// Main chat interface for conversing with EDDIE. Displays message bubbles
/// in a scrolling list with an input bar at the bottom.
struct ChatView: View {

    // MARK: - State

    @State var viewModel: ChatViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }

                ChatInputBar(
                    text: $viewModel.inputText,
                    isConnected: viewModel.isConnected,
                    onSend: {
                        viewModel.sendMessage()
                    }
                )
            }
            .navigationTitle("EDDIE")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                viewModel.connect()
            }
            .onDisappear {
                viewModel.disconnect()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(.purple.opacity(0.6))

            Text("What can I help you with?")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Ask EDDIE anything. I can manage tasks, check on your projects, and more.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message) { requestId, decision in
                            viewModel.submitApproval(requestId: requestId, decision: decision)
                        }
                        .id(message.id)
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.messages.last?.steps.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    // MARK: - Helpers

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ServerConfig.default
    let client = KarnEvil9Client(serverConfig: config)
    let ws = WebSocketClient()
    ChatView(viewModel: ChatViewModel(webSocket: ws, client: client))
}
