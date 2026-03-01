import SwiftUI
#if os(iOS)
import UserNotifications
#endif

// MARK: - TarkusApp

/// Main entry point for the Tarkus iOS application.
///
/// On launch the app checks for a previously saved `ServerConfig` and
/// Keychain token. If both exist it creates a `KarnEvil9Client` and
/// `WebSocketClient`, then presents the main tab interface; otherwise
/// it shows the first-run connection setup screen.
@main
struct TarkusApp: App {

    // MARK: - State

    @State private var client: KarnEvil9Client?
    @State private var webSocket = WebSocketClient()
    @State private var isConfigured: Bool = false
    @State private var appRouter = AppRouter()
    @State private var notificationService = NotificationService()

    // MARK: - App Delegate

    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    // MARK: - Initialization

    init() {
        // Attempt to restore a previously saved server configuration.
        // A token is not required — the server may not need authentication.
        if ServerConfig.hasSavedConfig {
            let savedConfig = ServerConfig.load()
            let configuredClient = KarnEvil9Client(serverConfig: savedConfig)
            _client = State(initialValue: configuredClient)
            _isConfigured = State(initialValue: true)
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if isConfigured, let client {
                    AppTabView(client: client, webSocket: webSocket)
                        .environment(appRouter)
                        .environment(notificationService)
                        .onAppear {
                            #if os(iOS)
                            // Share the router with the app delegate for notification routing.
                            appDelegate.appRouter = appRouter
                            #endif
                            // Register notification actions and request permission.
                            notificationService.registerActions()
                            Task {
                                await notificationService.requestAuthorization()
                            }
                        }
                } else {
                    ConnectionSetupView(isConnected: $isConfigured)
                }
            }
            .onChange(of: isConfigured) { _, newValue in
                if newValue && client == nil {
                    // Re-read config after successful connection setup.
                    let config = ServerConfig.load()
                    client = KarnEvil9Client(serverConfig: config)
                }
            }
        }
    }
}

#if os(iOS)
// MARK: - AppDelegate

/// UIKit app delegate used to handle notification center delegate callbacks
/// and route notification taps through `AppRouter`.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// Injected by `TarkusApp` after the scene is created so that notification
    /// taps can trigger deep-link navigation.
    var appRouter: AppRouter?

    // MARK: - UIApplicationDelegate

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when the user taps a notification (app in background or terminated).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        appRouter?.handleNotification(userInfo: userInfo)
        completionHandler()
    }

    /// Called when a notification arrives while the app is in the foreground.
    /// Shows the notification banner even when the app is active.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }
}
#endif
