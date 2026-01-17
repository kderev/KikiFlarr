import Foundation

actor RadarrService {
    private let client = APIClient()
    private let baseURL: String
    private let apiKey: String
    
    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.apiKey = apiKey
    }
    
    private var headers: [String: String] {
        ["X-Api-Key": apiKey]
    }
    
    private func buildURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents(string: "\(baseURL)/api/v3\(path)")
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        return url
    }
    
    // MARK: - System
    
    func getSystemStatus() async throws -> RadarrSystemStatus {
        let url = try buildURL(path: "/system/status")
        return try await client.request(url: url, headers: headers)
    }
    
    func testConnection() async throws -> ConnectionTestResult {
        let startTime = Date()
        do {
            let status = try await getSystemStatus()
            let responseTime = Date().timeIntervalSince(startTime)
            return ConnectionTestResult(
                success: true,
                message: "Connecté - Radarr v\(status.version)",
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
                httpCode = 401
                suggestion = "Vérifiez que votre clé API est correcte et valide"
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
    
    // MARK: - Movies
    
    func getMovies() async throws -> [RadarrMovie] {
        let url = try buildURL(path: "/movie")
        return try await client.request(url: url, headers: headers)
    }
    
    func getMovie(id: Int) async throws -> RadarrMovie {
        let url = try buildURL(path: "/movie/\(id)")
        return try await client.request(url: url, headers: headers)
    }
    
    func lookupMovie(term: String) async throws -> [RadarrLookupResult] {
        let url = try buildURL(path: "/movie/lookup", queryItems: [
            URLQueryItem(name: "term", value: term)
        ])
        return try await client.request(url: url, headers: headers)
    }
    
    func lookupMovieByTmdbId(_ tmdbId: Int) async throws -> RadarrLookupResult {
        let url = try buildURL(path: "/movie/lookup/tmdb", queryItems: [
            URLQueryItem(name: "tmdbId", value: String(tmdbId))
        ])
        return try await client.request(url: url, headers: headers)
    }
    
    func addMovie(_ request: RadarrAddMovieRequest) async throws -> RadarrMovie {
        let url = try buildURL(path: "/movie")
        let body = try client.encode(request)
        return try await client.request(url: url, method: .post, headers: headers, body: body)
    }
    
    func deleteMovie(id: Int, deleteFiles: Bool = false, addImportExclusion: Bool = false) async throws {
        let url = try buildURL(path: "/movie/\(id)", queryItems: [
            URLQueryItem(name: "deleteFiles", value: String(deleteFiles)),
            URLQueryItem(name: "addImportExclusion", value: String(addImportExclusion))
        ])
        try await client.requestVoid(url: url, method: .delete, headers: headers)
    }
    
    // MARK: - Quality Profiles
    
    func getQualityProfiles() async throws -> [RadarrQualityProfile] {
        let url = try buildURL(path: "/qualityprofile")
        return try await client.request(url: url, headers: headers)
    }
    
    // MARK: - Root Folders
    
    func getRootFolders() async throws -> [RadarrRootFolder] {
        let url = try buildURL(path: "/rootfolder")
        return try await client.request(url: url, headers: headers)
    }
    
    // MARK: - Queue
    
    func getQueue(page: Int = 1, pageSize: Int = 20) async throws -> RadarrQueue {
        let url = try buildURL(path: "/queue", queryItems: [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "includeMovie", value: "true")
        ])
        return try await client.request(url: url, headers: headers)
    }
    
    // MARK: - Commands
    
    func searchMovie(movieId: Int) async throws {
        let url = try buildURL(path: "/command")
        let command = ["name": "MoviesSearch", "movieIds": [movieId]] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: command)
        try await client.requestVoid(url: url, method: .post, headers: headers, body: body)
    }
    
    // MARK: - Releases (Interactive Search)
    
    func getReleases(movieId: Int) async throws -> [RadarrRelease] {
        let url = try buildURL(path: "/release", queryItems: [
            URLQueryItem(name: "movieId", value: String(movieId))
        ])
        return try await client.request(url: url, headers: headers)
    }
    
    func downloadRelease(guid: String, indexerId: Int) async throws {
        let url = try buildURL(path: "/release")
        let body: [String: Any] = [
            "guid": guid,
            "indexerId": indexerId
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        try await client.requestVoid(url: url, method: .post, headers: headers, body: jsonData)
    }
}
