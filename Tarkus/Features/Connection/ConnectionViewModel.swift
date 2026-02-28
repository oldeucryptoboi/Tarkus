import Foundation

// MARK: - ConnectionViewModel

/// ViewModel for the first-run connection setup screen.
/// Validates server connectivity and persists configuration.
@Observable
class ConnectionViewModel {

    // MARK: - Properties

    var host: String = ""
    var port: String = "3100"
    var token: String = ""
    var isValidating: Bool = false
    var isValid: Bool?
    var errorMessage: String?

    // MARK: - Computed Properties

    /// Builds a `ServerConfig` from the current host and port fields.
    var serverConfig: ServerConfig {
        let portInt = Int(port) ?? 3100
        return ServerConfig(host: host, port: portInt)
    }

    /// Whether the form has enough input to attempt validation.
    var canValidate: Bool {
        !host.trimmingCharacters(in: .whitespaces).isEmpty
            && !port.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    /// Validates the connection by performing a health check against the server.
    /// On success, persists the server config to UserDefaults and the token to
    /// the Keychain.
    @MainActor
    func validate() async {
        isValidating = true
        isValid = nil
        errorMessage = nil

        let config = serverConfig
        let client = KarnEvil9Client(serverConfig: config)

        // Store the token if provided, otherwise clear any existing one
        let trimmedToken = token.trimmingCharacters(in: .whitespaces)
        if !trimmedToken.isEmpty {
            do {
                try KeychainService.saveToken(trimmedToken)
            } catch {
                isValidating = false
                isValid = false
                errorMessage = "Failed to save token: \(error.localizedDescription)"
                return
            }
        } else {
            try? KeychainService.deleteToken()
        }

        do {
            let _ = try await client.healthCheck()
            config.save()
            isValid = true
            errorMessage = nil
        } catch {
            isValid = false
            errorMessage = error.localizedDescription
            // Clean up the stored token on failure only if one was provided
            if !trimmedToken.isEmpty {
                try? KeychainService.deleteToken()
            }
        }

        isValidating = false
    }
}
