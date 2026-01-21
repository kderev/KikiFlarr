import Foundation

actor SonarrService {
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
    
    func getSystemStatus() async throws -> SonarrSystemStatus {
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
                message: "Connecté - Sonarr v\(status.version)",
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
    
    // MARK: - Series
    
    func getSeries() async throws -> [SonarrSeries] {
        let url = try buildURL(path: "/series")
        return try await client.request(url: url, headers: headers)
    }
    
    func getSeries(id: Int) async throws -> SonarrSeries {
        let url = try buildURL(path: "/series/\(id)")
        return try await client.request(url: url, headers: headers)
    }
    
    func lookupSeries(term: String) async throws -> [SonarrLookupResult] {
        let url = try buildURL(path: "/series/lookup", queryItems: [
            URLQueryItem(name: "term", value: term)
        ])
        return try await client.request(url: url, headers: headers)
    }
    
    func lookupSeriesByTvdbId(_ tvdbId: Int) async throws -> [SonarrLookupResult] {
        let url = try buildURL(path: "/series/lookup", queryItems: [
            URLQueryItem(name: "term", value: "tvdb:\(tvdbId)")
        ])
        return try await client.request(url: url, headers: headers)
    }
    
    func addSeries(_ request: SonarrAddSeriesRequest) async throws -> SonarrSeries {
        let url = try buildURL(path: "/series")
        let body = try client.encode(request)
        return try await client.request(url: url, method: .post, headers: headers, body: body)
    }
    
    func deleteSeries(id: Int, deleteFiles: Bool = false, addImportListExclusion: Bool = false) async throws {
        let url = try buildURL(path: "/series/\(id)", queryItems: [
            URLQueryItem(name: "deleteFiles", value: String(deleteFiles)),
            URLQueryItem(name: "addImportListExclusion", value: String(addImportListExclusion))
        ])
        try await client.requestVoid(url: url, method: .delete, headers: headers)
    }
    
    // MARK: - Quality Profiles
    
    func getQualityProfiles() async throws -> [SonarrQualityProfile] {
        let url = try buildURL(path: "/qualityprofile")
        return try await client.request(url: url, headers: headers)
    }
    
    // MARK: - Root Folders
    
    func getRootFolders() async throws -> [SonarrRootFolder] {
        let url = try buildURL(path: "/rootfolder")
        return try await client.request(url: url, headers: headers)
    }
    
    // MARK: - Queue
    
    func getQueue(page: Int = 1, pageSize: Int = 20) async throws -> SonarrQueue {
        let url = try buildURL(path: "/queue", queryItems: [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "includeSeries", value: "true"),
            URLQueryItem(name: "includeEpisode", value: "true")
        ])
        return try await client.request(url: url, headers: headers)
    }

    // MARK: - Calendar

    func getCalendar(startDate: String, endDate: String, includeUnmonitored: Bool = true) async throws -> [SonarrCalendarEpisode] {
        let url = try buildURL(path: "/calendar", queryItems: [
            URLQueryItem(name: "start", value: startDate),
            URLQueryItem(name: "end", value: endDate),
            URLQueryItem(name: "includeUnmonitored", value: includeUnmonitored ? "true" : "false"),
            URLQueryItem(name: "includeSeries", value: "true"),
            URLQueryItem(name: "includeEpisodeFile", value: "true")
        ])
        return try await client.request(url: url, headers: headers)
    }
    
    // MARK: - Commands
    
    func searchSeries(seriesId: Int) async throws {
        let url = try buildURL(path: "/command")
        let command = ["name": "SeriesSearch", "seriesId": seriesId] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: command)
        try await client.requestVoid(url: url, method: .post, headers: headers, body: body)
    }
    
    func searchSeason(seriesId: Int, seasonNumber: Int) async throws {
        let url = try buildURL(path: "/command")
        let command = ["name": "SeasonSearch", "seriesId": seriesId, "seasonNumber": seasonNumber] as [String : Any]
        let body = try JSONSerialization.data(withJSONObject: command)
        try await client.requestVoid(url: url, method: .post, headers: headers, body: body)
    }

    // MARK: - Episodes

    func updateEpisodeMonitor(episodeIds: [Int], monitored: Bool) async throws {
        let url = try buildURL(path: "/episode/monitor")
        let body: [String: Any] = [
            "episodeIds": episodeIds,
            "monitored": monitored
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        try await client.requestVoid(url: url, method: .put, headers: headers, body: jsonData)
    }

    // MARK: - Series Updates

    func updateSeriesQualityProfile(seriesId: Int, qualityProfileId: Int) async throws {
        var series = try await getSeries(id: seriesId)
        series.qualityProfileId = qualityProfileId
        let url = try buildURL(path: "/series")
        let body = try client.encode(series)
        try await client.requestVoid(url: url, method: .put, headers: headers, body: body)
    }
    
    // MARK: - Releases (Interactive Search)
    
    func getReleases(seriesId: Int, seasonNumber: Int? = nil) async throws -> [SonarrRelease] {
        var queryItems = [URLQueryItem(name: "seriesId", value: String(seriesId))]
        if let seasonNumber = seasonNumber {
            queryItems.append(URLQueryItem(name: "seasonNumber", value: String(seasonNumber)))
        }
        let url = try buildURL(path: "/release", queryItems: queryItems)
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
