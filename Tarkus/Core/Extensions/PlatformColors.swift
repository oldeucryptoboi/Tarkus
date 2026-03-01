import SwiftUI

// MARK: - Cross-Platform Colors

extension Color {

    /// Grouped background color that adapts to the current platform.
    static var groupedBackground: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #else
        Color(.windowBackgroundColor)
        #endif
    }

    /// Secondary grouped background color that adapts to the current platform.
    static var secondaryGroupedBackground: Color {
        #if os(iOS)
        Color(.secondarySystemGroupedBackground)
        #else
        Color(.controlBackgroundColor)
        #endif
    }

    /// Tertiary grouped background color that adapts to the current platform.
    static var tertiaryGroupedBackground: Color {
        #if os(iOS)
        Color(.tertiarySystemGroupedBackground)
        #else
        Color(.textBackgroundColor)
        #endif
    }
}
