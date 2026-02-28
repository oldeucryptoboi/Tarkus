import Foundation

/// Server connection configuration for communicating with the KarnEvil9 API.
/// The authentication token is stored separately via KeychainService and is
/// intentionally excluded from Codable serialization.
struct ServerConfig: Codable, Equatable {

    // MARK: - Properties

    var host: String
    var port: Int

    // MARK: - Computed Properties

    var baseURL: URL? {
        URL(string: "http://\(host):\(port)")
    }

    // MARK: - Defaults

    static let `default` = ServerConfig(host: "localhost", port: 3100)

    // MARK: - UserDefaults Persistence

    private static let userDefaultsKey = "com.tarkus.serverConfig"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }

    static func load() -> ServerConfig {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let config = try? JSONDecoder().decode(ServerConfig.self, from: data) else {
            return .default
        }
        return config
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
