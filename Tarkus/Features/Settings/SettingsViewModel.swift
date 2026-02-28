import Foundation

// MARK: - SettingsViewModel

/// ViewModel for the Settings screen. Manages server health status,
/// version info, and available tools.
@Observable
class SettingsViewModel {

    // MARK: - Properties

    var isHealthy: Bool?
    var serverVersion: String?
    var tools: [ToolInfo] = []
    var isLoading: Bool = false

    // MARK: - Dependencies

    let client: KarnEvil9Client

    // MARK: - Initialization

    init(client: KarnEvil9Client) {
        self.client = client
    }

    // MARK: - Actions

    /// Performs a health check against the server and updates status.
    @MainActor
    func checkHealth() async {
        isLoading = true

        do {
            let response = try await client.healthCheck()
            isHealthy = response.status == "ok"
            serverVersion = response.version
        } catch {
            isHealthy = false
            serverVersion = nil
        }

        isLoading = false
    }

    /// Fetches the list of tools available on the server.
    @MainActor
    func loadTools() async {
        do {
            tools = try await client.listTools()
        } catch {
            tools = []
        }
    }
}
