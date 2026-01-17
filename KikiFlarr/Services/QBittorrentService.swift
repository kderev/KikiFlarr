import Foundation

actor QBittorrentService {
    private let client = APIClient()
    private let baseURL: String
    private let username: String
    private let password: String
    private var sid: String?
    private var qbVersion: QBittorrentVersion?
    
    /// Structure pour parser et comparer les versions de qBittorrent
    struct QBittorrentVersion {
        let major: Int
        let minor: Int
        let patch: Int
        let raw: String
        
        init?(versionString: String) {
            self.raw = versionString
            // Format: "v4.6.2" ou "4.6.2" ou "v5.0.0"
            let cleaned = versionString.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "v", with: "")
            let components = cleaned.split(separator: ".").compactMap { Int($0) }
            
            guard components.count >= 2 else { return nil }
            
            self.major = components[0]
            self.minor = components[1]
            self.patch = components.count > 2 ? components[2] : 0
        }
        
        /// qBittorrent v5.0+ utilise stop/start au lieu de pause/resume
        var usesStopStartAPI: Bool {
            return major >= 5
        }
    }
    
    init(baseURL: String, username: String, password: String) {
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.username = username
        self.password = password
    }
    
    private func buildURL(path: String) throws -> URL {
        guard let url = URL(string: "\(baseURL)/api/v2\(path)") else {
            throw NetworkError.invalidURL
        }
        return url
    }
    
    private var authHeaders: [String: String] {
        if let sid = sid {
            return ["Cookie": "SID=\(sid)"]
        }
        return [:]
    }
    
    // MARK: - Authentication
    
    func login() async throws {
        let url = try buildURL(path: "/auth/login")
        let formData = [
            "username": username,
            "password": password
        ]
        
        let (data, response) = try await client.requestFormURLEncoded(
            url: url,
            formData: formData
        )
        
        let responseString = String(data: data, encoding: .utf8) ?? ""
        
        if response.statusCode == 200 && responseString.lowercased().contains("ok") {
            if let cookies = response.value(forHTTPHeaderField: "Set-Cookie") {
                let components = cookies.components(separatedBy: ";")
                for component in components {
                    let trimmed = component.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("SID=") {
                        self.sid = String(trimmed.dropFirst(4))
                        break
                    }
                }
            }
            // Après le login, récupérer la version pour savoir quelle API utiliser
            try await detectVersion()
            return
        } else if response.statusCode == 403 {
            throw NetworkError.unauthorized
        } else {
            throw NetworkError.serverError(response.statusCode)
        }
    }
    
    /// Détecte la version de qBittorrent pour utiliser les bons endpoints
    private func detectVersion() async throws {
        let url = try buildURL(path: "/app/version")
        let versionString = try await client.requestString(url: url, headers: authHeaders)
        self.qbVersion = QBittorrentVersion(versionString: versionString)
        
        #if DEBUG
        if let version = qbVersion {
            print("🔧 qBittorrent version détectée: \(version.raw) (API: \(version.usesStopStartAPI ? "stop/start" : "pause/resume"))")
        }
        #endif
    }
    
    func logout() async throws {
        let url = try buildURL(path: "/auth/logout")
        try await client.requestVoid(url: url, headers: authHeaders)
        self.sid = nil
        self.qbVersion = nil
    }
    
    private func ensureAuthenticated() async throws {
        if sid == nil {
            try await login()
        }
    }
    
    // MARK: - Application
    
    func getVersion() async throws -> String {
        try await ensureAuthenticated()
        let url = try buildURL(path: "/app/version")
        return try await client.requestString(url: url, headers: authHeaders)
    }
    
    func getWebAPIVersion() async throws -> String {
        try await ensureAuthenticated()
        let url = try buildURL(path: "/app/webapiVersion")
        return try await client.requestString(url: url, headers: authHeaders)
    }
    
    func testConnection() async throws -> ConnectionTestResult {
        let startTime = Date()
        do {
            let version = try await getVersion()
            let responseTime = Date().timeIntervalSince(startTime)
            let apiType = qbVersion?.usesStopStartAPI == true ? " (API v5+)" : ""
            return ConnectionTestResult(
                success: true,
                message: "Connecté - qBittorrent \(version)\(apiType)",
                responseTime: responseTime,
                httpStatusCode: 200
            )
        } catch {
            let (httpCode, recoverySuggestion) = extractErrorDetails(from: error)
            return ConnectionTestResult(
                success: false,
                message: error.localizedDescription,
                responseTime: nil,
                httpStatusCode: httpCode,
                recoverySuggestion: recoverySuggestion
            )
        }
    }

    private func extractErrorDetails(from error: Error) -> (httpCode: Int?, suggestion: String?) {
        var suggestion: String? = nil
        var httpCode: Int? = nil

        if let networkError = error as? NetworkError {
            suggestion = networkError.recoverySuggestion

            switch networkError {
            case .serverError(let code):
                httpCode = code
            case .unauthorized:
                httpCode = 403
                suggestion = "Vérifiez que vos identifiants (nom d'utilisateur et mot de passe) sont corrects"
            case .notFound:
                httpCode = 404
            case .timeout, .noConnection:
                suggestion = (suggestion ?? "") + "\n• Vérifiez que vous êtes connecté au VPN si nécessaire\n• Vérifiez l'URL du reverse proxy si utilisé"
            default:
                break
            }
        }

        return (httpCode, suggestion)
    }
    
    // MARK: - Torrents
    
    func getTorrents(filter: TorrentFilter = .all, category: String? = nil, sort: String = "added_on", reverse: Bool = true) async throws -> [QBittorrentTorrent] {
        try await ensureAuthenticated()
        
        var queryItems = [
            URLQueryItem(name: "filter", value: filter.rawValue),
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "reverse", value: String(reverse))
        ]
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        var components = URLComponents(string: "\(baseURL)/api/v2/torrents/info")
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        return try await client.request(url: url, headers: authHeaders)
    }
    
    func getTorrent(hash: String) async throws -> QBittorrentTorrent {
        try await ensureAuthenticated()
        let torrents = try await getTorrents()
        guard let torrent = torrents.first(where: { $0.hash == hash }) else {
            throw NetworkError.notFound
        }
        return torrent
    }
    
    /// Met en pause les torrents (compatible qBittorrent v4 et v5+)
    func pauseTorrents(hashes: [String]) async throws {
        try await ensureAuthenticated()
        
        // qBittorrent v5+ utilise /torrents/stop au lieu de /torrents/pause
        let endpoint = (qbVersion?.usesStopStartAPI == true) ? "/torrents/stop" : "/torrents/pause"
        let url = try buildURL(path: endpoint)
        let hashesString = hashes.joined(separator: "|")
        
        let (_, response) = try await client.requestFormURLEncoded(
            url: url,
            headers: authHeaders,
            formData: ["hashes": hashesString]
        )
        
        // Vérifier que la requête a réussi
        guard response.statusCode >= 200 && response.statusCode < 300 else {
            // Si l'endpoint échoue, essayer l'autre endpoint (fallback)
            if response.statusCode == 404 {
                try await pauseTorrentsFallback(hashes: hashes)
                return
            }
            throw NetworkError.serverError(response.statusCode)
        }
        
        // Petit délai pour laisser qBittorrent mettre à jour l'état
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
    }
    
    /// Fallback pour pause si l'endpoint principal échoue
    private func pauseTorrentsFallback(hashes: [String]) async throws {
        // Essayer l'autre endpoint
        let alternateEndpoint = (qbVersion?.usesStopStartAPI == true) ? "/torrents/pause" : "/torrents/stop"
        let url = try buildURL(path: alternateEndpoint)
        let hashesString = hashes.joined(separator: "|")
        
        let (_, response) = try await client.requestFormURLEncoded(
            url: url,
            headers: authHeaders,
            formData: ["hashes": hashesString]
        )
        
        guard response.statusCode >= 200 && response.statusCode < 300 else {
            throw NetworkError.serverError(response.statusCode)
        }
        
        // Mettre à jour la détection de version si le fallback a fonctionné
        if qbVersion?.usesStopStartAPI == true {
            // En fait c'est une ancienne version
            qbVersion = nil
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
    }
    
    /// Reprend les torrents (compatible qBittorrent v4 et v5+)
    func resumeTorrents(hashes: [String]) async throws {
        try await ensureAuthenticated()
        
        // qBittorrent v5+ utilise /torrents/start au lieu de /torrents/resume
        let endpoint = (qbVersion?.usesStopStartAPI == true) ? "/torrents/start" : "/torrents/resume"
        let url = try buildURL(path: endpoint)
        let hashesString = hashes.joined(separator: "|")
        
        let (_, response) = try await client.requestFormURLEncoded(
            url: url,
            headers: authHeaders,
            formData: ["hashes": hashesString]
        )
        
        // Vérifier que la requête a réussi
        guard response.statusCode >= 200 && response.statusCode < 300 else {
            // Si l'endpoint échoue, essayer l'autre endpoint (fallback)
            if response.statusCode == 404 {
                try await resumeTorrentsFallback(hashes: hashes)
                return
            }
            throw NetworkError.serverError(response.statusCode)
        }
        
        // Petit délai pour laisser qBittorrent mettre à jour l'état
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
    }
    
    /// Fallback pour resume si l'endpoint principal échoue
    private func resumeTorrentsFallback(hashes: [String]) async throws {
        // Essayer l'autre endpoint
        let alternateEndpoint = (qbVersion?.usesStopStartAPI == true) ? "/torrents/resume" : "/torrents/start"
        let url = try buildURL(path: alternateEndpoint)
        let hashesString = hashes.joined(separator: "|")
        
        let (_, response) = try await client.requestFormURLEncoded(
            url: url,
            headers: authHeaders,
            formData: ["hashes": hashesString]
        )
        
        guard response.statusCode >= 200 && response.statusCode < 300 else {
            throw NetworkError.serverError(response.statusCode)
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
    }
    
    func deleteTorrents(hashes: [String], deleteFiles: Bool = false) async throws {
        try await ensureAuthenticated()
        let url = try buildURL(path: "/torrents/delete")
        let hashesString = hashes.joined(separator: "|")
        let (_, _) = try await client.requestFormURLEncoded(
            url: url,
            headers: authHeaders,
            formData: [
                "hashes": hashesString,
                "deleteFiles": String(deleteFiles)
            ]
        )
    }
    
    func recheckTorrents(hashes: [String]) async throws {
        try await ensureAuthenticated()
        let url = try buildURL(path: "/torrents/recheck")
        let hashesString = hashes.joined(separator: "|")
        let (_, _) = try await client.requestFormURLEncoded(
            url: url,
            headers: authHeaders,
            formData: ["hashes": hashesString]
        )
    }
    
    // MARK: - Transfer Info
    
    func getTransferInfo() async throws -> QBittorrentServerState {
        try await ensureAuthenticated()
        let url = try buildURL(path: "/transfer/info")
        return try await client.request(url: url, headers: authHeaders)
    }
    
    // MARK: - Sync
    
    func getMainData(rid: Int = 0) async throws -> QBittorrentMainData {
        try await ensureAuthenticated()
        var components = URLComponents(string: "\(baseURL)/api/v2/sync/maindata")
        components?.queryItems = [URLQueryItem(name: "rid", value: String(rid))]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        return try await client.request(url: url, headers: authHeaders)
    }
}

enum TorrentFilter: String {
    case all = "all"
    case downloading = "downloading"
    case seeding = "seeding"
    case completed = "completed"
    case paused = "paused"
    case active = "active"
    case inactive = "inactive"
    case resumed = "resumed"
    case stalled = "stalled"
    case stalledUploading = "stalled_uploading"
    case stalledDownloading = "stalled_downloading"
    case errored = "errored"
}
