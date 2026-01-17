import Foundation

actor TMDBService {
    private let apiKey: String
    private let baseURL = "https://api.themoviedb.org/3"
    private let language: String
    
    init(apiKey: String, language: String = "fr-FR") {
        self.apiKey = apiKey
        self.language = language
    }
    
    // MARK: - URL Building
    
    private func buildURL(endpoint: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: "\(baseURL)\(endpoint)")
        var items = queryItems
        items.append(URLQueryItem(name: "api_key", value: apiKey))
        items.append(URLQueryItem(name: "language", value: language))
        components?.queryItems = items
        return components?.url
    }
    
    // MARK: - Generic Request
    
    private func request<T: Decodable>(_ url: URL?) async throws -> T {
        guard let url = url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Test Connection
    
    func testConnection() async throws -> ConnectionTestResult {
        let start = Date()

        do {
            let url = buildURL(endpoint: "/configuration")
            let _: TMDBConfiguration = try await request(url)

            let elapsed = Date().timeIntervalSince(start)
            return ConnectionTestResult(
                success: true,
                message: "Connexion TMDB réussie",
                responseTime: elapsed,
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
                suggestion = "Vérifiez que votre clé API TMDB est correcte et valide"
            case .notFound:
                httpCode = 404
            case .timeout, .noConnection:
                suggestion = "Vérifiez votre connexion Internet"
            default:
                break
            }
        }

        return (httpCode, suggestion)
    }
    
    // MARK: - Search Movies
    
    func searchMovies(query: String, page: Int = 1) async throws -> TMDBSearchResponse {
        let url = buildURL(endpoint: "/search/movie", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "include_adult", value: "false")
        ])
        
        return try await request(url)
    }
    
    // MARK: - Get Movie Details
    
    func getMovieDetails(id: Int) async throws -> TMDBMovie {
        let url = buildURL(endpoint: "/movie/\(id)")
        return try await request(url)
    }
    
    // MARK: - Popular Movies
    
    func getPopularMovies(page: Int = 1) async throws -> TMDBSearchResponse {
        let url = buildURL(endpoint: "/movie/popular", queryItems: [
            URLQueryItem(name: "page", value: String(page))
        ])
        
        return try await request(url)
    }
    
    // MARK: - Now Playing
    
    func getNowPlayingMovies(page: Int = 1) async throws -> TMDBSearchResponse {
        let url = buildURL(endpoint: "/movie/now_playing", queryItems: [
            URLQueryItem(name: "page", value: String(page))
        ])
        
        return try await request(url)
    }
    
    // MARK: - Top Rated
    
    func getTopRatedMovies(page: Int = 1) async throws -> TMDBSearchResponse {
        let url = buildURL(endpoint: "/movie/top_rated", queryItems: [
            URLQueryItem(name: "page", value: String(page))
        ])
        
        return try await request(url)
    }
    
    // MARK: - Trending
    
    func getTrendingMovies(timeWindow: String = "week", page: Int = 1) async throws -> TMDBTrendingResponse {
        let url = buildURL(endpoint: "/trending/movie/\(timeWindow)", queryItems: [
            URLQueryItem(name: "page", value: String(page))
        ])
        
        return try await request(url)
    }
    
    // MARK: - Search TV Shows
    
    func searchTVShows(query: String, page: Int = 1) async throws -> TMDBTVSearchResponse {
        let url = buildURL(endpoint: "/search/tv", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "include_adult", value: "false")
        ])
        
        return try await request(url)
    }
    
    // MARK: - Get TV Show Details
    
    func getTVShowDetails(id: Int) async throws -> TMDBTVShow {
        let url = buildURL(endpoint: "/tv/\(id)")
        return try await request(url)
    }
    
    // MARK: - Get Season Details (with episodes)
    
    func getSeasonDetails(tvId: Int, seasonNumber: Int) async throws -> TMDBSeason {
        let url = buildURL(endpoint: "/tv/\(tvId)/season/\(seasonNumber)")
        return try await request(url)
    }
    
    // MARK: - Get Episode Details
    
    func getEpisodeDetails(tvId: Int, seasonNumber: Int, episodeNumber: Int) async throws -> TMDBEpisode {
        let url = buildURL(endpoint: "/tv/\(tvId)/season/\(seasonNumber)/episode/\(episodeNumber)")
        return try await request(url)
    }
    
    // MARK: - Popular TV Shows
    
    func getPopularTVShows(page: Int = 1) async throws -> TMDBTVSearchResponse {
        let url = buildURL(endpoint: "/tv/popular", queryItems: [
            URLQueryItem(name: "page", value: String(page))
        ])
        
        return try await request(url)
    }
    
    // MARK: - Get Genres
    
    func getGenres() async throws -> [TMDBGenre] {
        let url = buildURL(endpoint: "/genre/movie/list")
        let response: TMDBGenreResponse = try await request(url)
        return response.genres
    }
    
    func getTVGenres() async throws -> [TMDBGenre] {
        let url = buildURL(endpoint: "/genre/tv/list")
        let response: TMDBGenreResponse = try await request(url)
        return response.genres
    }
    
    // MARK: - Discover Movies
    
    func discoverMovies(
        page: Int = 1,
        genreId: Int? = nil,
        year: Int? = nil,
        sortBy: String = "popularity.desc"
    ) async throws -> TMDBSearchResponse {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sort_by", value: sortBy),
            URLQueryItem(name: "include_adult", value: "false")
        ]
        
        if let genreId = genreId {
            queryItems.append(URLQueryItem(name: "with_genres", value: String(genreId)))
        }
        
        if let year = year {
            queryItems.append(URLQueryItem(name: "primary_release_year", value: String(year)))
        }
        
        let url = buildURL(endpoint: "/discover/movie", queryItems: queryItems)
        return try await request(url)
    }
}
