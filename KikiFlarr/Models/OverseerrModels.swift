import Foundation

enum MediaType: String, Codable {
    case movie = "movie"
    case tv = "tv"
}

struct OverseerrSearchResults: Codable {
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let results: [OverseerrSearchResult]
}

struct OverseerrSearchResult: Codable, Identifiable {
    let id: Int
    let mediaType: MediaType?
    let popularity: Double?
    let posterPath: String?
    let backdropPath: String?
    let voteCount: Int?
    let voteAverage: Double?
    let genreIds: [Int]?
    let overview: String?
    let originalLanguage: String?
    
    // Movie specific
    let title: String?
    let originalTitle: String?
    let releaseDate: String?
    let adult: Bool?
    let video: Bool?
    
    // TV specific
    let name: String?
    let originalName: String?
    let firstAirDate: String?
    let originCountry: [String]?
    
    // Media info from Overseerr
    let mediaInfo: OverseerrMediaInfo?
    
    var displayTitle: String {
        title ?? name ?? "Inconnu"
    }
    
    var displayYear: String {
        let dateString = releaseDate ?? firstAirDate ?? ""
        return String(dateString.prefix(4))
    }
    
    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var fullBackdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(backdropPath)")
    }
    
    var resolvedMediaType: MediaType {
        if let mediaType = mediaType {
            return mediaType
        }
        return title != nil ? .movie : .tv
    }
}

struct OverseerrMediaInfo: Codable {
    let id: Int?
    let tmdbId: Int?
    let tvdbId: Int?
    let status: Int?
    let requests: [OverseerrRequest]?
    let createdAt: String?
    let updatedAt: String?
    
    var statusDescription: String {
        switch status {
        case 1: return "Inconnu"
        case 2: return "En attente"
        case 3: return "En cours"
        case 4: return "Partiellement disponible"
        case 5: return "Disponible"
        default: return "Inconnu"
        }
    }
    
    var isAvailable: Bool {
        status == 5
    }
    
    var isPartiallyAvailable: Bool {
        status == 4
    }
    
    var isRequested: Bool {
        status == 2 || status == 3
    }
}

struct OverseerrRequest: Codable, Identifiable {
    let id: Int
    let status: Int
    let createdAt: String?
    let updatedAt: String?
    let type: String?
    let is4k: Bool?
    let serverId: Int?
    let profileId: Int?
    let rootFolder: String?
    let languageProfileId: Int?
    let tags: [Int]?
    let media: OverseerrMediaInfo?
    let requestedBy: OverseerrUser?
    let modifiedBy: OverseerrUser?
    let seasons: [OverseerrRequestSeason]?
    
    var statusDescription: String {
        switch status {
        case 1: return "En attente d'approbation"
        case 2: return "Approuvé"
        case 3: return "Refusé"
        default: return "Inconnu"
        }
    }
}

struct OverseerrRequestSeason: Codable {
    let id: Int
    let seasonNumber: Int
    let status: Int
    let createdAt: String?
    let updatedAt: String?
}

struct OverseerrUser: Codable, Identifiable {
    let id: Int
    let email: String?
    let username: String?
    let plexToken: String?
    let plexUsername: String?
    let avatar: String?
    let permissions: Int?
    let userType: Int?
    let createdAt: String?
    let updatedAt: String?
    let requestCount: Int?
    
    var displayName: String {
        username ?? plexUsername ?? email ?? "Utilisateur"
    }
}

struct OverseerrMovieDetails: Identifiable {
    let id: Int
    let imdbId: String?
    let adult: Bool?
    let backdropPath: String?
    let posterPath: String?
    let budget: Int64?
    let genres: [OverseerrGenre]?
    let homepage: String?
    let originalLanguage: String?
    let originalTitle: String?
    let overview: String?
    let popularity: Double?
    let productionCompanies: [OverseerrProductionCompany]?
    let productionCountries: [OverseerrProductionCountry]?
    let releaseDate: String?
    let revenue: Int64?
    let runtime: Int?
    let spokenLanguages: [OverseerrSpokenLanguage]?
    let status: String?
    let tagline: String?
    let title: String?
    let video: Bool?
    let voteAverage: Double?
    let voteCount: Int?
    let credits: OverseerrCredits?
    let externalIds: OverseerrExternalIds?
    let mediaInfo: OverseerrMediaInfo?
    
    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var fullBackdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(backdropPath)")
    }
    
    var displayYear: String {
        guard let releaseDate = releaseDate else { return "" }
        return String(releaseDate.prefix(4))
    }
    
    var formattedRuntime: String {
        guard let runtime = runtime else { return "" }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        }
        return "\(minutes)min"
    }
}

extension OverseerrMovieDetails: Codable {
    enum CodingKeys: String, CodingKey {
        case id, imdbId, adult, backdropPath, posterPath, budget, genres
        case homepage, originalLanguage, originalTitle, overview, popularity
        case productionCompanies, productionCountries, releaseDate, revenue
        case runtime, spokenLanguages, status, tagline, title, video
        case voteAverage, voteCount, credits, externalIds, mediaInfo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        imdbId = try? container.decodeIfPresent(String.self, forKey: .imdbId)
        adult = try? container.decodeIfPresent(Bool.self, forKey: .adult)
        backdropPath = try? container.decodeIfPresent(String.self, forKey: .backdropPath)
        posterPath = try? container.decodeIfPresent(String.self, forKey: .posterPath)
        budget = try? container.decodeIfPresent(Int64.self, forKey: .budget)
        genres = try? container.decodeIfPresent([OverseerrGenre].self, forKey: .genres)
        homepage = try? container.decodeIfPresent(String.self, forKey: .homepage)
        originalLanguage = try? container.decodeIfPresent(String.self, forKey: .originalLanguage)
        originalTitle = try? container.decodeIfPresent(String.self, forKey: .originalTitle)
        overview = try? container.decodeIfPresent(String.self, forKey: .overview)
        popularity = try? container.decodeIfPresent(Double.self, forKey: .popularity)
        productionCompanies = try? container.decodeIfPresent([OverseerrProductionCompany].self, forKey: .productionCompanies)
        productionCountries = try? container.decodeIfPresent([OverseerrProductionCountry].self, forKey: .productionCountries)
        releaseDate = try? container.decodeIfPresent(String.self, forKey: .releaseDate)
        revenue = try? container.decodeIfPresent(Int64.self, forKey: .revenue)
        runtime = try? container.decodeIfPresent(Int.self, forKey: .runtime)
        spokenLanguages = try? container.decodeIfPresent([OverseerrSpokenLanguage].self, forKey: .spokenLanguages)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
        tagline = try? container.decodeIfPresent(String.self, forKey: .tagline)
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        video = try? container.decodeIfPresent(Bool.self, forKey: .video)
        voteAverage = try? container.decodeIfPresent(Double.self, forKey: .voteAverage)
        voteCount = try? container.decodeIfPresent(Int.self, forKey: .voteCount)
        credits = try? container.decodeIfPresent(OverseerrCredits.self, forKey: .credits)
        externalIds = try? container.decodeIfPresent(OverseerrExternalIds.self, forKey: .externalIds)
        mediaInfo = try? container.decodeIfPresent(OverseerrMediaInfo.self, forKey: .mediaInfo)
    }
}

struct OverseerrTVDetails: Identifiable {
    let id: Int
    let backdropPath: String?
    let posterPath: String?
    let contentRatings: OverseerrContentRatings?
    let createdBy: [OverseerrCreator]?
    let episodeRunTime: [Int]?
    let firstAirDate: String?
    let genres: [OverseerrGenre]?
    let homepage: String?
    let inProduction: Bool?
    let languages: [String]?
    let lastAirDate: String?
    let name: String?
    let networks: [OverseerrNetwork]?
    let numberOfEpisodes: Int?
    let numberOfSeasons: Int?
    let originCountry: [String]?
    let originalLanguage: String?
    let originalName: String?
    let overview: String?
    let popularity: Double?
    let productionCompanies: [OverseerrProductionCompany]?
    let productionCountries: [OverseerrProductionCountry]?
    let seasons: [OverseerrTVSeason]?
    let spokenLanguages: [OverseerrSpokenLanguage]?
    let status: String?
    let tagline: String?
    let type: String?
    let voteAverage: Double?
    let voteCount: Int?
    let credits: OverseerrCredits?
    let externalIds: OverseerrExternalIds?
    let mediaInfo: OverseerrMediaInfo?
    
    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var fullBackdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(backdropPath)")
    }
    
    var displayYear: String {
        guard let firstAirDate = firstAirDate else { return "" }
        return String(firstAirDate.prefix(4))
    }
    
    var formattedRuntime: String {
        guard let episodeRunTime = episodeRunTime, let runtime = episodeRunTime.first else { return "" }
        return "\(runtime)min/épisode"
    }
}

extension OverseerrTVDetails: Codable {
    enum CodingKeys: String, CodingKey {
        case id, backdropPath, posterPath, contentRatings, createdBy, episodeRunTime
        case firstAirDate, genres, homepage, inProduction, languages, lastAirDate
        case name, networks, numberOfEpisodes, numberOfSeasons, originCountry
        case originalLanguage, originalName, overview, popularity
        case productionCompanies, productionCountries, seasons, spokenLanguages
        case status, tagline, type, voteAverage, voteCount, credits, externalIds, mediaInfo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        backdropPath = try? container.decodeIfPresent(String.self, forKey: .backdropPath)
        posterPath = try? container.decodeIfPresent(String.self, forKey: .posterPath)
        contentRatings = try? container.decodeIfPresent(OverseerrContentRatings.self, forKey: .contentRatings)
        createdBy = try? container.decodeIfPresent([OverseerrCreator].self, forKey: .createdBy)
        episodeRunTime = try? container.decodeIfPresent([Int].self, forKey: .episodeRunTime)
        firstAirDate = try? container.decodeIfPresent(String.self, forKey: .firstAirDate)
        genres = try? container.decodeIfPresent([OverseerrGenre].self, forKey: .genres)
        homepage = try? container.decodeIfPresent(String.self, forKey: .homepage)
        inProduction = try? container.decodeIfPresent(Bool.self, forKey: .inProduction)
        languages = try? container.decodeIfPresent([String].self, forKey: .languages)
        lastAirDate = try? container.decodeIfPresent(String.self, forKey: .lastAirDate)
        name = try? container.decodeIfPresent(String.self, forKey: .name)
        networks = try? container.decodeIfPresent([OverseerrNetwork].self, forKey: .networks)
        numberOfEpisodes = try? container.decodeIfPresent(Int.self, forKey: .numberOfEpisodes)
        numberOfSeasons = try? container.decodeIfPresent(Int.self, forKey: .numberOfSeasons)
        originCountry = try? container.decodeIfPresent([String].self, forKey: .originCountry)
        originalLanguage = try? container.decodeIfPresent(String.self, forKey: .originalLanguage)
        originalName = try? container.decodeIfPresent(String.self, forKey: .originalName)
        overview = try? container.decodeIfPresent(String.self, forKey: .overview)
        popularity = try? container.decodeIfPresent(Double.self, forKey: .popularity)
        productionCompanies = try? container.decodeIfPresent([OverseerrProductionCompany].self, forKey: .productionCompanies)
        productionCountries = try? container.decodeIfPresent([OverseerrProductionCountry].self, forKey: .productionCountries)
        seasons = try? container.decodeIfPresent([OverseerrTVSeason].self, forKey: .seasons)
        spokenLanguages = try? container.decodeIfPresent([OverseerrSpokenLanguage].self, forKey: .spokenLanguages)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
        tagline = try? container.decodeIfPresent(String.self, forKey: .tagline)
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        voteAverage = try? container.decodeIfPresent(Double.self, forKey: .voteAverage)
        voteCount = try? container.decodeIfPresent(Int.self, forKey: .voteCount)
        credits = try? container.decodeIfPresent(OverseerrCredits.self, forKey: .credits)
        externalIds = try? container.decodeIfPresent(OverseerrExternalIds.self, forKey: .externalIds)
        mediaInfo = try? container.decodeIfPresent(OverseerrMediaInfo.self, forKey: .mediaInfo)
    }
}

struct OverseerrTVSeason: Identifiable {
    let id: Int
    let airDate: String?
    let episodeCount: Int?
    let name: String?
    let overview: String?
    let posterPath: String?
    let seasonNumber: Int
}

extension OverseerrTVSeason: Codable {
    enum CodingKeys: String, CodingKey {
        case id, airDate, episodeCount, name, overview, posterPath, seasonNumber
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        airDate = try? container.decodeIfPresent(String.self, forKey: .airDate)
        episodeCount = try? container.decodeIfPresent(Int.self, forKey: .episodeCount)
        name = try? container.decodeIfPresent(String.self, forKey: .name)
        overview = try? container.decodeIfPresent(String.self, forKey: .overview)
        posterPath = try? container.decodeIfPresent(String.self, forKey: .posterPath)
        seasonNumber = (try? container.decode(Int.self, forKey: .seasonNumber)) ?? 0
    }
}

struct OverseerrGenre: Identifiable {
    let id: Int
    let name: String
}

extension OverseerrGenre: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? "Inconnu"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name
    }
}

struct OverseerrProductionCompany: Codable, Identifiable {
    let id: Int
    let logoPath: String?
    let name: String
    let originCountry: String?
}

struct OverseerrProductionCountry: Codable {
    let iso31661: String?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case iso31661 = "iso_3166_1"
        case name
    }
}

struct OverseerrSpokenLanguage: Codable {
    let englishName: String?
    let iso6391: String?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case englishName = "english_name"
        case iso6391 = "iso_639_1"
        case name
    }
}

struct OverseerrCredits: Codable {
    let cast: [OverseerrCastMember]?
    let crew: [OverseerrCrewMember]?
}

struct OverseerrCastMember: Codable, Identifiable {
    let id: Int
    let castId: Int?
    let character: String?
    let creditId: String?
    let gender: Int?
    let name: String
    let order: Int?
    let profilePath: String?
    
    var profileURL: URL? {
        guard let profilePath = profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w185\(profilePath)")
    }
}

struct OverseerrCrewMember: Codable, Identifiable {
    let id: Int
    let creditId: String?
    let department: String?
    let gender: Int?
    let job: String?
    let name: String
    let profilePath: String?
}

struct OverseerrCreator: Codable, Identifiable {
    let id: Int
    let creditId: String?
    let name: String
    let gender: Int?
    let profilePath: String?
}

struct OverseerrNetwork: Codable, Identifiable {
    let id: Int
    let logoPath: String?
    let name: String
    let originCountry: String?
}

struct OverseerrContentRatings: Codable {
    let results: [OverseerrContentRating]?
}

struct OverseerrContentRating: Codable {
    let iso31661: String?
    let rating: String?
    
    enum CodingKeys: String, CodingKey {
        case iso31661 = "iso_3166_1"
        case rating
    }
}

struct OverseerrExternalIds: Codable {
    let facebookId: String?
    let freebaseId: String?
    let freebaseMid: String?
    let imdbId: String?
    let instagramId: String?
    let tvdbId: Int?
    let tvrageId: Int?
    let twitterId: String?
    
    enum CodingKeys: String, CodingKey {
        case facebookId = "facebook_id"
        case freebaseId = "freebase_id"
        case freebaseMid = "freebase_mid"
        case imdbId = "imdb_id"
        case instagramId = "instagram_id"
        case tvdbId = "tvdb_id"
        case tvrageId = "tvrage_id"
        case twitterId = "twitter_id"
    }
}

struct OverseerrVideo: Codable, Identifiable {
    let id: String?
    let iso6391: String?
    let iso31661: String?
    let key: String?
    let name: String?
    let site: String?
    let size: Int?
    let type: String?
    
    // Fournir un id stable pour Identifiable
    var stableId: String { id ?? key ?? UUID().uuidString }
    
    var youtubeURL: URL? {
        guard let key = key, site == "YouTube" else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
}

struct OverseerrWatchProvider: Codable, Identifiable {
    let id: Int?
    let displayPriority: Int?
    let logoPath: String?
    let providerName: String?
}

struct OverseerrStatus: Codable {
    let version: String
    let commitTag: String?
    let updateAvailable: Bool?
    let commitsBehind: Int?
}

struct OverseerrRequestBody: Codable {
    let mediaType: String
    let mediaId: Int
    let is4k: Bool?
    let serverId: Int?
    let profileId: Int?
    let rootFolder: String?
    let languageProfileId: Int?
    let seasons: [Int]?
}

// MARK: - Settings

struct OverseerrRadarrServer: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let hostname: String?
    let port: Int?
    let useSsl: Bool?
    let baseUrl: String?
    let activeProfileId: Int?
    let activeProfileName: String?
    let activeDirectory: String?
    let is4k: Bool?
    let minimumAvailability: String?
    let isDefault: Bool?
    let externalUrl: String?
    let syncEnabled: Bool?
    let preventSearch: Bool?
}

struct OverseerrSonarrServer: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let hostname: String?
    let port: Int?
    let useSsl: Bool?
    let baseUrl: String?
    let activeProfileId: Int?
    let activeProfileName: String?
    let activeDirectory: String?
    let activeLanguageProfileId: Int?
    let activeAnimeProfileId: Int?
    let activeAnimeLanguageProfileId: Int?
    let activeAnimeDirectory: String?
    let is4k: Bool?
    let isDefault: Bool?
    let externalUrl: String?
    let syncEnabled: Bool?
    let preventSearch: Bool?
}

struct OverseerrQualityProfile: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
}

struct OverseerrRootFolderOption: Codable, Identifiable, Hashable {
    let id: Int
    let path: String
}

struct OverseerrServiceSettings: Codable {
    let id: Int?
    let name: String?
    let profiles: [OverseerrQualityProfile]?
    let rootFolders: [OverseerrRootFolderOption]?
}

// MARK: - Enriched Request with Media Details

struct RequestWithMedia: Identifiable {
    let request: OverseerrRequest
    let title: String
    let posterPath: String?
    let year: String
    let overview: String?
    
    var id: Int { request.id }
    
    var fullPosterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    var downloadStatus: DownloadStatus {
        guard let media = request.media else { return .unknown }
        
        switch media.status {
        case 5: return .available
        case 4: return .partiallyAvailable
        case 3: return .downloading
        case 2: return .pending
        default: return .unknown
        }
    }
    
    var downloadStatusDescription: String {
        switch downloadStatus {
        case .available: return "Téléchargé"
        case .partiallyAvailable: return "Partiellement disponible"
        case .downloading: return "En téléchargement"
        case .pending: return "En attente"
        case .unknown: return "Inconnu"
        }
    }
    
    var downloadStatusColor: String {
        switch downloadStatus {
        case .available: return "green"
        case .partiallyAvailable: return "orange"
        case .downloading: return "blue"
        case .pending: return "yellow"
        case .unknown: return "gray"
        }
    }
    
    enum DownloadStatus {
        case available
        case partiallyAvailable
        case downloading
        case pending
        case unknown
    }
}
