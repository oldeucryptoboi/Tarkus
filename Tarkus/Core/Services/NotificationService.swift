import Foundation
import UserNotifications

/// Manages local notifications for the Tarkus app, including actionable
/// approval request notifications that let the user allow or deny directly
/// from the notification banner.
@Observable
class NotificationService {

    // MARK: - Constants

    private static let approvalCategoryIdentifier = "APPROVAL_REQUEST"
    private static let allowOnceActionIdentifier = "ALLOW_ONCE"
    private static let denyOnceActionIdentifier = "DENY_ONCE"

    // MARK: - Properties

    var isAuthorized: Bool = false

    // MARK: - Authorization

    /// Requests notification permission from the user and updates
    /// `isAuthorized` with the result.
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])

            await MainActor.run {
                self.isAuthorized = granted
            }
        } catch {
            await MainActor.run {
                self.isAuthorized = false
            }
        }
    }

    // MARK: - Action Registration

    /// Registers the actionable notification category used for approval
    /// requests. Call this early in the app lifecycle (e.g. on launch).
    func registerActions() {
        let allowAction = UNNotificationAction(
            identifier: Self.allowOnceActionIdentifier,
            title: "Allow Once",
            options: []
        )

        let denyAction = UNNotificationAction(
            identifier: Self.denyOnceActionIdentifier,
            title: "Deny Once",
            options: [.destructive]
        )

        let approvalCategory = UNNotificationCategory(
            identifier: Self.approvalCategoryIdentifier,
            actions: [allowAction, denyAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current()
            .setNotificationCategories([approvalCategory])
    }

    // MARK: - Send Notification

    /// Posts a local notification for the given approval request. The
    /// notification includes actionable buttons so the user can respond
    /// without opening the app.
    func sendApprovalNotification(approval: Approval) {
        let content = UNMutableNotificationContent()
        content.title = "Permission Requested"
        content.body = approval.permission.description
        content.sound = .default
        content.categoryIdentifier = Self.approvalCategoryIdentifier
        content.userInfo = [
            "approvalId": approval.id,
            "sessionId": approval.sessionId
        ]

        // Fire almost immediately (minimum interval is 1 second)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "approval-\(approval.id)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationService] Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
}
