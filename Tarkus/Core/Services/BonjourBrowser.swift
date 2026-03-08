import Foundation
import Network

// MARK: - DiscoveredServer

/// A KarnEvil9 server discovered via mDNS/Bonjour.
struct DiscoveredServer: Identifiable, Equatable {
    let id: String
    let name: String
    let host: String
    let port: Int
}

// MARK: - BonjourBrowser

/// Browses for `_karnevil9._tcp.` Bonjour services on the local network
/// using `NWBrowser` from the Network framework.
@Observable
class BonjourBrowser {

    // MARK: - Properties

    var servers: [DiscoveredServer] = []
    var isSearching: Bool = false

    private var browser: NWBrowser?
    private var resolutionConnections: [String: NWConnection] = [:]

    // MARK: - Browsing

    func startBrowsing() {
        stopBrowsing()

        let descriptor = NWBrowser.Descriptor.bonjour(type: "_karnevil9._tcp.", domain: nil)
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let browser = NWBrowser(for: descriptor, using: parameters)

        browser.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isSearching = true
                case .cancelled, .failed:
                    self?.isSearching = false
                default:
                    break
                }
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            self?.handleResultsChanged(results)
        }

        browser.start(queue: .main)
        self.browser = browser
    }

    func stopBrowsing() {
        browser?.cancel()
        browser = nil
        isSearching = false
        cancelAllResolutions()
    }

    // MARK: - Resolution

    private func handleResultsChanged(_ results: Set<NWBrowser.Result>) {
        let currentIDs = Set(results.map { resultID(for: $0) })
        for key in resolutionConnections.keys where !currentIDs.contains(key) {
            resolutionConnections[key]?.cancel()
            resolutionConnections.removeValue(forKey: key)
        }

        servers.removeAll { !currentIDs.contains($0.id) }

        for result in results {
            let id = resultID(for: result)
            guard !servers.contains(where: { $0.id == id }) else { continue }
            resolve(result: result, id: id)
        }
    }

    private func resolve(result: NWBrowser.Result, id: String) {
        guard case let .service(name, _, _, _) = result.endpoint else { return }

        // Connect briefly to resolve the service endpoint and extract host + port.
        let connection = NWConnection(to: result.endpoint, using: .tcp)
        resolutionConnections[id] = connection

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                if let resolved = connection.currentPath?.remoteEndpoint,
                   case let .hostPort(host, port) = resolved {
                    // Prefer IPv4 dotted-decimal for URL safety.
                    // Fall back to the Bonjour service name, which for dns-sd
                    // registrations defaults to the machine's .local hostname
                    // (e.g. "Mac-mini.local") — resolvable via mDNS on iOS.
                    let hostString: String
                    if case .ipv4 = host {
                        // debugDescription may include a zone ID (e.g. "192.168.4.41%en0")
                        // which is invalid in URLs — strip it.
                        let raw = host.debugDescription
                        hostString = raw.components(separatedBy: "%").first ?? raw
                    } else {
                        hostString = name
                    }
                    let server = DiscoveredServer(
                        id: id,
                        name: name,
                        host: hostString,
                        port: Int(port.rawValue)
                    )
                    DispatchQueue.main.async {
                        if !self.servers.contains(where: { $0.id == id }) {
                            self.servers.append(server)
                        }
                    }
                }
                connection.cancel()
                self.resolutionConnections.removeValue(forKey: id)

            case .failed, .cancelled:
                self.resolutionConnections.removeValue(forKey: id)

            default:
                break
            }
        }

        connection.start(queue: .main)
    }

    private func cancelAllResolutions() {
        for connection in resolutionConnections.values {
            connection.cancel()
        }
        resolutionConnections.removeAll()
    }

    private func resultID(for result: NWBrowser.Result) -> String {
        switch result.endpoint {
        case .service(let name, let type, let domain, _):
            return "\(name).\(type)\(domain)"
        default:
            return "\(result.endpoint)"
        }
    }
}
