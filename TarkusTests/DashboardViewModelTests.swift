import XCTest
@testable import Tarkus

// MARK: - DashboardViewModelTests

/// Basic tests for the DashboardViewModel. Since the view model relies on
/// SSE streams for live data, these tests focus on initial state and
/// simple in-memory operations rather than network interactions.
final class DashboardViewModelTests: XCTestCase {

    // MARK: - AppRouter Tests (used by the dashboard for navigation)

    func testAppRouterInitialState() {
        let router = AppRouter()

        XCTAssertEqual(router.selectedTab, 0)
        XCTAssertEqual(router.approvalsBadgeCount, 0)
        XCTAssertNil(router.pendingDeepLink)
    }

    func testAppRouterHandleNotificationWithApprovalId() {
        let router = AppRouter()
        let userInfo: [AnyHashable: Any] = ["approvalId": "appr_test_001"]

        router.handleNotification(userInfo: userInfo)

        XCTAssertEqual(router.selectedTab, 1)
        XCTAssertEqual(router.pendingDeepLink, .approval(id: "appr_test_001"))
    }

    func testAppRouterHandleNotificationWithSessionId() {
        let router = AppRouter()
        let userInfo: [AnyHashable: Any] = ["sessionId": "sess_test_001"]

        router.handleNotification(userInfo: userInfo)

        XCTAssertEqual(router.selectedTab, 2)
        XCTAssertEqual(router.pendingDeepLink, .session(id: "sess_test_001"))
    }

    func testAppRouterNavigateToApproval() {
        let router = AppRouter()

        router.navigate(to: .approval(id: "appr_nav_001"))

        XCTAssertEqual(router.selectedTab, 1)
        XCTAssertEqual(router.pendingDeepLink, .approval(id: "appr_nav_001"))
    }

    func testAppRouterNavigateToSession() {
        let router = AppRouter()

        router.navigate(to: .session(id: "sess_nav_001"))

        XCTAssertEqual(router.selectedTab, 2)
        XCTAssertEqual(router.pendingDeepLink, .session(id: "sess_nav_001"))
    }

    func testAppRouterClearDeepLink() {
        let router = AppRouter()
        router.navigate(to: .approval(id: "appr_clear"))

        XCTAssertNotNil(router.pendingDeepLink)

        router.clearDeepLink()

        XCTAssertNil(router.pendingDeepLink)
    }

    func testAppRouterBadgeCount() {
        let router = AppRouter()

        router.approvalsBadgeCount = 5
        XCTAssertEqual(router.approvalsBadgeCount, 5)

        router.approvalsBadgeCount = 0
        XCTAssertEqual(router.approvalsBadgeCount, 0)
    }

    // MARK: - DeepLink Equatable

    func testDeepLinkEquatable() {
        XCTAssertEqual(DeepLink.approval(id: "a"), DeepLink.approval(id: "a"))
        XCTAssertNotEqual(DeepLink.approval(id: "a"), DeepLink.approval(id: "b"))
        XCTAssertNotEqual(DeepLink.approval(id: "a"), DeepLink.session(id: "a"))
        XCTAssertEqual(DeepLink.session(id: "s"), DeepLink.session(id: "s"))
    }

    // MARK: - PreviewData Smoke Tests

    /// Verifies that preview data objects are well-formed and accessible.
    func testPreviewDataSessionsExist() {
        XCTAssertFalse(PreviewData.sessions.isEmpty)
        XCTAssertEqual(PreviewData.sessions.count, 2)
        XCTAssertEqual(PreviewData.session.state, .running)
        XCTAssertEqual(PreviewData.completedSession.state, .completed)
    }

    func testPreviewDataEventsExist() {
        XCTAssertFalse(PreviewData.events.isEmpty)
        XCTAssertEqual(PreviewData.events.count, 5)
        XCTAssertEqual(PreviewData.sessionCreatedEvent.type, "session.created")
        XCTAssertEqual(PreviewData.stepStartedEvent.type, "step.started")
    }

    func testPreviewDataApprovalsExist() {
        XCTAssertFalse(PreviewData.approvals.isEmpty)
        XCTAssertEqual(PreviewData.approval.status, "pending")
        XCTAssertEqual(PreviewData.approval.permission.tool, "Bash")
    }

    func testPreviewDataUsageMetrics() {
        let metrics = PreviewData.usageMetrics
        XCTAssertGreaterThan(metrics.inputTokens, 0)
        XCTAssertGreaterThan(metrics.outputTokens, 0)
        XCTAssertGreaterThan(metrics.totalCost, 0)
        XCTAssertEqual(metrics.totalTokens, metrics.inputTokens + metrics.outputTokens)
    }

    // MARK: - ServerConfig Tests

    func testServerConfigDefaultValues() {
        let config = ServerConfig.default
        XCTAssertEqual(config.host, "localhost")
        XCTAssertEqual(config.port, 3100)
        XCTAssertNotNil(config.baseURL)
        XCTAssertEqual(config.baseURL?.absoluteString, "http://localhost:3100")
    }

    func testServerConfigCustomValues() {
        let config = ServerConfig(host: "192.168.1.50", port: 8080)
        XCTAssertEqual(config.host, "192.168.1.50")
        XCTAssertEqual(config.port, 8080)
        XCTAssertEqual(config.baseURL?.absoluteString, "http://192.168.1.50:8080")
    }

    // MARK: - UsageMetrics Computed Properties

    func testUsageMetricsTotalTokens() {
        let metrics = UsageMetrics(
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: 200,
            cacheWriteTokens: 100,
            totalCost: 0.01
        )

        XCTAssertEqual(metrics.totalTokens, 1500)
    }
}
