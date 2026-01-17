import Foundation

// MARK: - Configuration TMDB

struct TMDBConfiguration: Codable {
    let images: TMDBImageConfiguration
}

struct TMDBImageConfiguration: Codable {
    let baseUrl: String
    let secureBaseUrl: String
    let posterSizes: [String]
    let backdropSizes: [String]
    
    enum CodingKeys: String, CodingKey {
        case baseUrl
        case secureBaseUrl
        case posterSizes
        case backdropSizes
    }
}

// MARK: - Recherche de films

struct TMDBSearchResponse: Codable {
    let page: Int
    let results: [TMDBMovie]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages
        case totalResults
    }
}

struct TMDBMovie: Codable, Identifiable, Hashable {
    static func == (lhs: TMDBMovie, rhs: TMDBMovie) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: Int
    let title: String
    let originalTitle: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let genreIds: [Int]?
    let genres: [TMDBGenre]?
    let runtime: Int?
    let adult: Bool?
    let popularity: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case originalTitle
        case overview
        case posterPath
        case backdropPath
        case releaseDate
        case voteAverage
        case voteCount
        case genreIds
        case genres
        case runtime
        case adult
        case popularity
    }
    
    var year: Int {
        guard let dateString = releaseDate,
              let year = Int(dateString.prefix(4)) else {
            return 0
        }
        return year
    }
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(path)")
    }
    
    var genreNames: [String] {
        genres?.map { $0.name } ?? []
    }
}

// MARK: - Genres

struct TMDBGenre: Codable, Identifiable {
    let id: Int
    let name: String
}

struct TMDBGenreResponse: Codable {
    let genres: [TMDBGenre]
}

// MARK: - Films populaires / tendance

struct TMDBTrendingResponse: Codable {
    let page: Int
    let results: [TMDBMovie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages
        case totalResults
    }
}

// MARK: - Conversion vers WatchedMovie

extension TMDBMovie {
    func toWatchedMovie(rating: Int? = nil, notes: String? = nil) -> WatchedMovie {
        WatchedMovie(
            tmdbId: id,
            radarrId: nil,
            title: title,
            year: year,
            posterURL: posterURL?.absoluteString,
            fanartURL: backdropURL?.absoluteString,
            genres: genreNames,
            runtime: runtime,
            watchedDate: Date(),
            rating: rating,
            notes: notes
        )
    }
}

// MARK: - Recherche de séries TV

struct TMDBTVSearchResponse: Codable {
    let page: Int
    let results: [TMDBTVShow]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages
        case totalResults
    }
}

struct TMDBTVShow: Codable, Identifiable, Hashable {
    static func == (lhs: TMDBTVShow, rhs: TMDBTVShow) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: Int
    let name: String
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let voteCount: Int?
    let genreIds: [Int]?
    let genres: [TMDBGenre]?
    let numberOfEpisodes: Int?
    let numberOfSeasons: Int?
    let popularity: Double?
    let seasons: [TMDBSeason]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName
        case overview
        case posterPath
        case backdropPath
        case firstAirDate
        case voteAverage
        case voteCount
        case genreIds
        case genres
        case numberOfEpisodes
        case numberOfSeasons
        case popularity
        case seasons
    }
    
    var title: String { name }
    
    var year: Int {
        guard let dateString = firstAirDate,
              let year = Int(dateString.prefix(4)) else {
            return 0
        }
        return year
    }
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(path)")
    }
    
    var genreNames: [String] {
        genres?.map { $0.name } ?? []
    }
}

// MARK: - Saison TMDB

struct TMDBSeason: Codable, Identifiable, Hashable {
    static func == (lhs: TMDBSeason, rhs: TMDBSeason) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let seasonNumber: Int
    let episodeCount: Int?
    let airDate: String?
    let voteAverage: Double?
    
    // Épisodes (disponibles quand on récupère les détails de la saison)
    let episodes: [TMDBEpisode]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath
        case seasonNumber
        case episodeCount
        case airDate
        case voteAverage
        case episodes
    }
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    var year: Int {
        guard let dateString = airDate,
              let year = Int(dateString.prefix(4)) else {
            return 0
        }
        return year
    }
}

// MARK: - Épisode TMDB

struct TMDBEpisode: Codable, Identifiable, Hashable {
    static func == (lhs: TMDBEpisode, rhs: TMDBEpisode) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: Int
    let name: String
    let overview: String?
    let stillPath: String?
    let episodeNumber: Int
    let seasonNumber: Int
    let airDate: String?
    let runtime: Int?
    let voteAverage: Double?
    let voteCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case stillPath
        case episodeNumber
        case seasonNumber
        case airDate
        case runtime
        case voteAverage
        case voteCount
    }
    
    var stillURL: URL? {
        guard let path = stillPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    var formattedRuntime: String? {
        guard let runtime = runtime, runtime > 0 else { return nil }
        if runtime >= 60 {
            return "\(runtime / 60)h \(runtime % 60)min"
        }
        return "\(runtime) min"
    }
    
    var episodeCode: String {
        String(format: "S%02dE%02d", seasonNumber, episodeNumber)
    }
}

// MARK: - Conversion vers WatchedSeries

extension TMDBTVShow {
    func toWatchedSeries(rating: Int? = nil, notes: String? = nil, watchedDate: Date = Date()) -> WatchedSeries {
        WatchedSeries(
            tvdbId: id, // On utilise TMDB ID car on n'a pas le TVDB ID
            sonarrId: nil,
            title: name,
            year: year,
            posterURL: posterURL?.absoluteString,
            fanartURL: backdropURL?.absoluteString,
            genres: genreNames.isEmpty ? TMDBGenreMapper.tvGenreNames(from: genreIds) : genreNames,
            totalEpisodes: numberOfEpisodes ?? 0,
            watchedEpisodes: numberOfEpisodes ?? 0,
            watchedDate: watchedDate,
            rating: rating,
            notes: notes
        )
    }
}

// MARK: - Mapping des genres par ID

struct TMDBGenreMapper {
    static let movieGenres: [Int: String] = [
        28: "Action",
        12: "Adventure",
        16: "Animation",
        35: "Comedy",
        80: "Crime",
        99: "Documentary",
        18: "Drama",
        10751: "Family",
        14: "Fantasy",
        36: "History",
        27: "Horror",
        10402: "Music",
        9648: "Mystery",
        10749: "Romance",
        878: "Science Fiction",
        10770: "TV Movie",
        53: "Thriller",
        10752: "War",
        37: "Western"
    ]
    
    static func genreNames(from ids: [Int]?) -> [String] {
        guard let ids = ids else { return [] }
        return ids.compactMap { movieGenres[$0] }
    }
    
    // Genres TV
    static let tvGenres: [Int: String] = [
        10759: "Action & Adventure",
        16: "Animation",
        35: "Comedy",
        80: "Crime",
        99: "Documentary",
        18: "Drama",
        10751: "Family",
        10762: "Kids",
        9648: "Mystery",
        10763: "News",
        10764: "Reality",
        10765: "Sci-Fi & Fantasy",
        10766: "Soap",
        10767: "Talk",
        10768: "War & Politics",
        37: "Western"
    ]
    
    static func tvGenreNames(from ids: [Int]?) -> [String] {
        guard let ids = ids else { return [] }
        return ids.compactMap { tvGenres[$0] }
    }
}
