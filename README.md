# Tarkus

A native macOS/iOS chat client for **EDDIE** — the AI assistant powered by the [KarnEvil9](https://github.com/oldeucryptoboi/KarnEvil9) runtime.

## Features

- **Real-time chat** with EDDIE over WebSocket (REST + SSE fallback)
- **Live step activity** — see EDDIE thinking, planning, and working in real time
- **Inline approvals** — grant or deny tool permissions directly in the chat
- **Session history** — browse past sessions in the Activity tab
- **Custom Markdown rendering** — code highlighting via Highlightr, full GFM support via swift-markdown

## Requirements

- macOS 14.0+ / iOS 17.0+
- Xcode 16.0+
- Swift 5.9+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Getting Started

```bash
# Generate the Xcode project
xcodegen generate

# Build
xcodebuild build -scheme Tarkus -destination 'platform=macOS'
```

Then configure your KarnEvil9 server address in the **Settings** tab.

## Project Structure

```
Tarkus/
├── TarkusApp.swift              # App entry point
├── Navigation/
│   ├── AppTabView.swift         # Root tab view (Chat, Activity, Approvals, Settings)
│   └── AppRouter.swift          # Navigation state & notification routing
├── Features/
│   └── Chat/
│       ├── ChatView.swift       # Message list + input bar
│       ├── ChatViewModel.swift  # WebSocket event routing & session tracking
│       ├── ChatInputBar.swift   # Text field, send button, connection indicator
│       ├── MessageBubbleView.swift  # User/assistant/system chat bubbles
│       └── Markdown/            # Custom cmark-gfm + Highlightr renderer
└── Core/
    ├── Networking/
    │   ├── WebSocketClient.swift    # URLSessionWebSocketTask with auto-reconnect
    │   ├── KarnEvil9Client.swift    # REST API client
    │   └── SSEClient.swift          # Server-Sent Events client
    ├── Models/                      # ChatMessage, JournalEvent, Approval, etc.
    └── Extensions/                  # Cross-platform helpers
```

## Dependencies

| Package | Purpose |
|---------|---------|
| [swift-markdown](https://github.com/swiftlang/swift-markdown) | cmark-gfm AST parsing for Markdown rendering |
| [Highlightr](https://github.com/raspu/Highlightr) | Syntax highlighting for code blocks |

## License

All rights reserved.
