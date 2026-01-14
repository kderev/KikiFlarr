import Foundation

actor OverseerrService {
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
        var components = URLComponents(string: "\(baseURL)/api/v1\(path)")
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        return url
    }
    
    // MARK: - Status
    
    func getStatus() async throws -> OverseerrStatus {
        let url = try buildURL(path: "/status")
        return try await client.request(url: url, headers: headers)
    }
    
    func testConnection() async throws -> ConnectionTestResult {
        let startTime = Date()
        do {
            let status = try await getStatus()
            let responseTime = Date().timeIntervalSince(startTime)
            return ConnectionTestResult(
                success: true,
                message: "Connecté - Overseerr v\(status.version)",
                responseTime: responseTime
            )
        } catch {
            return ConnectionTestResult(
                success: false,
                message: error.localizedDescription,
                responseTime: nil
            )
        }
    }
    
    // MARK: - Search (avec cache)
    
    func search(query: String, page: Int = 1) async throws -> OverseerrSearchResults {
        let cacheKey = ResponseCache.searchCacheKey(query: query)
        
        if let cached: OverseerrSearchResults = await ResponseCache.shared.get(cacheKey) {
            return cached
        }
        
        let url = try buildURL(path: "/search", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page))
        ])
        let results: OverseerrSearchResults = try await client.request(url: url, headers: headers)
        
        await ResponseCache.shared.set(cacheKey, value: results, ttl: 120)
        
        return results
    }
    
    func discoverMovies(page: Int = 1) async throws -> OverseerrSearchResults {
        let cacheKey = ResponseCache.discoverMoviesCacheKey()
        
        if let cached: OverseerrSearchResults = await ResponseCache.shared.get(cacheKey) {
            return cached
        }
        
        let url = try buildURL(path: "/discover/movies", queryItems: [
            URLQueryItem(name: "page", value: String(page))
        ])
        let results: OverseerrSearchResults = try await client.request(url: url, headers: headers)
        
        await ResponseCache.shared.set(cacheKey, value: results, ttl: 300)
        
        return results
    }
    
    func discoverTV(page: Int = 1) async throws -> OverseerrSearchResults {
        let cacheKey = ResponseCache.discoverTVCacheKey()
        
        if let cached: OverseerrSearchResults = await ResponseCache.shared.get(cacheKey) {
            return cached
        }
        
        let url = try buildURL(path: "/discover/tv", queryItems: [
            URLQueryItem(name: "page", value: String(page))
        ])
        let results: OverseerrSearchResults = try await client.request(url: url, headers: headers)
        
        await ResponseCache.shared.set(cacheKey, value: results, ttl: 300)
        
        return results
    }
    
    func trendingMovies() async throws -> OverseerrSearchResults {
        let url = try buildURL(path: "/discover/trending", queryItems: [
            URLQueryItem(name: "page", value: "1")
        ])
        return try await client.request(url: url, headers: headers)
    }
    
    // MARK: - Movie Details
    
    func getMovieDetails(tmdbId: Int) async throws -> OverseerrMovieDetails {
        let url = try buildURL(path: "/movie/\(tmdbId)")
        return try await client.request(url: url, headers: headers)
    }
    
    // MARK: - TV Details
    
    func getTVDetails(tmdbId: Int) async throws -> OverseerrTVDetails {
        let url = try buildURL(path: "/tv/\(tmdbId)")
        return try await client.request(url: url, headers: headers)
    }
    
    // MARK: - Requests
    
    func getRequests(take: Int = 20, skip: Int = 0, filter: RequestFilter = .all) async throws -> RequestsResponse {
        let url = try buildURL(path: "/request", queryItems: [
            URLQueryItem(name: "take", value: String(take)),
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "filter", value: filter.rawValue)
        ])
        return try await client.request(url: url, headers: headers)
    }
    
    func getRequestsWithMedia(take: Int = 20) async throws -> [RequestWithMedia] {
        let requestsResponse = try await getRequests(take: take)
        
        return await withTaskGroup(of: RequestWithMedia?.self) { group in
            for request in requestsResponse.results {
                group.addTask {
                    guard let media = request.media, let tmdbId = media.tmdbId else { return nil }
                    
                    do {
                        if request.type == "movie" {
                            let details = try await self.getMovieDetails(tmdbId: tmdbId)
                            return RequestWithMedia(
                                request: request,
                                title: details.title ?? "Film inconnu",
                                posterPath: details.posterPath,
                                year: details.displayYear,
                                overview: details.overview
                            )
                        } else {
                            let details = try await self.getTVDetails(tmdbId: tmdbId)
                            return RequestWithMedia(
                                request: request,
                                title: details.name ?? "Série inconnue",
                                posterPath: details.posterPath,
                                year: details.displayYear,
                                overview: details.overview
                            )
                        }
                    } catch {
                        return RequestWithMedia(
                            request: request,
                            title: request.type == "movie" ? "Film" : "Série",
                            posterPath: nil,
                            year: "",
                            overview: nil
                        )
                    }
                }
            }
            
            var results: [RequestWithMedia] = []
            for await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            return results
        }
    }
    
    func createRequest(mediaType: MediaType, mediaId: Int, is4k: Bool = false, seasons: [Int]? = nil) async throws -> OverseerrRequest {
        let url = try buildURL(path: "/request")
        
        var requestBody: [String: Any] = [
            "mediaType": mediaType.rawValue,
            "mediaId": mediaId,
            "is4k": is4k
        ]
        
        if let seasons = seasons {
            requestBody["seasons"] = seasons
        }
        
        let body = try JSONSerialization.data(withJSONObject: requestBody)
        return try await client.request(url: url, method: .post, headers: headers, body: body)
    }
    
    func deleteRequest(requestId: Int) async throws {
        let url = try buildURL(path: "/request/\(requestId)")
        try await client.requestVoid(url: url, method: .delete, headers: headers)
    }
    
    // MARK: - User
    
    func getCurrentUser() async throws -> OverseerrUser {
        let url = try buildURL(path: "/auth/me")
        return try await client.request(url: url, headers: headers)
    }
    
    // MARK: - Settings (Radarr/Sonarr servers)
    
    func getRadarrServers() async throws -> [OverseerrRadarrServer] {
        let url = try buildURL(path: "/settings/radarr")
        return try await client.request(url: url, headers: headers)
    }
    
    func getSonarrServers() async throws -> [OverseerrSonarrServer] {
        let url = try buildURL(path: "/settings/sonarr")
        return try await client.request(url: url, headers: headers)
    }
    
    func getRadarrProfiles(serverId: Int) async throws -> OverseerrServiceSettings {
        let url = try buildURL(path: "/settings/radarr/\(serverId)")
        return try await client.request(url: url, headers: headers)
    }
    
    func getSonarrProfiles(serverId: Int) async throws -> OverseerrServiceSettings {
        let url = try buildURL(path: "/settings/sonarr/\(serverId)")
        return try await client.request(url: url, headers: headers)
    }
    
    func createRequestWithOptions(
        mediaType: MediaType,
        mediaId: Int,
        is4k: Bool = false,
        serverId: Int? = nil,
        profileId: Int? = nil,
        rootFolder: String? = nil,
        seasons: [Int]? = nil
    ) async throws -> OverseerrRequest {
        let url = try buildURL(path: "/request")
        
        var requestBody: [String: Any] = [
            "mediaType": mediaType.rawValue,
            "mediaId": mediaId,
            "is4k": is4k
        ]
        
        if let serverId = serverId {
            requestBody["serverId"] = serverId
        }
        if let profileId = profileId {
            requestBody["profileId"] = profileId
        }
        if let rootFolder = rootFolder {
            requestBody["rootFolder"] = rootFolder
        }
        if let seasons = seasons {
            requestBody["seasons"] = seasons
        }
        
        let body = try JSONSerialization.data(withJSONObject: requestBody)
        return try await client.request(url: url, method: .post, headers: headers, body: body)
    }
}

struct RequestsResponse: Codable {
    let pageInfo: PageInfo
    let results: [OverseerrRequest]
}

struct PageInfo: Codable {
    let pages: Int
    let pageSize: Int
    let results: Int
    let page: Int
}

enum RequestFilter: String {
    case all = "all"
    case approved = "approved"
    case available = "available"
    case pending = "pending"
    case processing = "processing"
    case unavailable = "unavailable"
}
