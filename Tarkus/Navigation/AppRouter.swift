import SwiftUI

// MARK: - Deep Link

/// Represents a deep-link destination that the app can navigate to,
/// typically triggered by a notification tap.
enum DeepLink: Equatable {
    case approval(id: String)
    case session(id: String)
}

// MARK: - AppRouter

/// Central navigation coordinator that manages tab selection, badge counts,
/// and deep-link routing from push/local notifications.
@Observable
class AppRouter {

    // MARK: - Properties

    /// The currently selected tab index in the root `TabView`.
    var selectedTab: Int = 0

    /// The badge count displayed on the Approvals tab.
    var approvalsBadgeCount: Int = 0

    /// A pending deep link waiting to be consumed by a destination view.
    var pendingDeepLink: DeepLink? = nil

    // MARK: - Notification Handling

    /// Extracts routing information from a notification's `userInfo` dictionary
    /// and configures the router to navigate to the appropriate screen.
    ///
    /// Expected keys:
    /// - `"approvalId"`: routes to the Approvals tab with a deep link to the
    ///   specific approval.
    /// - `"sessionId"`: routes to the Sessions tab with a deep link to the
    ///   specific session.
    func handleNotification(userInfo: [AnyHashable: Any]) {
        if let approvalId = userInfo["approvalId"] as? String {
            selectedTab = 1
            pendingDeepLink = .approval(id: approvalId)
        } else if let sessionId = userInfo["sessionId"] as? String {
            selectedTab = 2
            pendingDeepLink = .session(id: sessionId)
        }
    }

    // MARK: - Programmatic Navigation

    /// Navigates to the tab and destination described by the given deep link.
    func navigate(to deepLink: DeepLink) {
        switch deepLink {
        case .approval:
            selectedTab = 1
            pendingDeepLink = deepLink
        case .session:
            selectedTab = 2
            pendingDeepLink = deepLink
        }
    }

    /// Clears the pending deep link after the destination view has consumed it.
    func clearDeepLink() {
        pendingDeepLink = nil
    }
}
