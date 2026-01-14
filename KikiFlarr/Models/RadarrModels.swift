import Foundation

struct RadarrMovie: Codable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String?
    let sortTitle: String?
    let sizeOnDisk: Int64?
    let status: String?
    let overview: String?
    let inCinemas: String?
    let physicalRelease: String?
    let digitalRelease: String?
    let images: [RadarrImage]?
    let website: String?
    let year: Int
    let hasFile: Bool?
    let youTubeTrailerId: String?
    let studio: String?
    let path: String?
    let qualityProfileId: Int?
    let monitored: Bool?
    let minimumAvailability: String?
    let isAvailable: Bool?
    let folderName: String?
    let runtime: Int?
    let cleanTitle: String?
    let imdbId: String?
    let tmdbId: Int?
    let titleSlug: String?
    let certification: String?
    let genres: [String]?
    let tags: [Int]?
    let added: String?
    let ratings: RadarrRatings?
    let movieFile: RadarrMovieFile?
    
    var posterURL: URL? {
        guard let posterImage = images?.first(where: { $0.coverType == "poster" }) else {
            return nil
        }
        return URL(string: posterImage.remoteUrl ?? posterImage.url ?? "")
    }
    
    var fanartURL: URL? {
        guard let fanartImage = images?.first(where: { $0.coverType == "fanart" }) else {
            return nil
        }
        return URL(string: fanartImage.remoteUrl ?? fanartImage.url ?? "")
    }
}

struct RadarrImage: Codable {
    let coverType: String
    let url: String?
    let remoteUrl: String?
}

struct RadarrRatings: Codable {
    let imdb: RadarrRating?
    let tmdb: RadarrRating?
    let metacritic: RadarrRating?
    let rottenTomatoes: RadarrRating?
}

struct RadarrRating: Codable {
    let votes: Int?
    let value: Double?
    let type: String?
}

struct RadarrMovieFile: Codable {
    let id: Int
    let relativePath: String?
    let path: String?
    let size: Int64?
    let dateAdded: String?
    let quality: RadarrQualityWrapper?
    let mediaInfo: RadarrMediaInfo?
}

struct RadarrMediaInfo: Codable {
    let audioBitrate: Int?
    let audioChannels: Double?
    let audioCodec: String?
    let audioLanguages: String?
    let audioStreamCount: Int?
    let videoBitDepth: Int?
    let videoBitrate: Int?
    let videoCodec: String?
    let videoDynamicRangeType: String?
    let videoFps: Double?
    let resolution: String?
    let runTime: String?
    let scanType: String?
    let subtitles: String?
}

struct RadarrQualityProfile: Codable, Identifiable {
    let id: Int
    let name: String
    let upgradeAllowed: Bool?
    let cutoff: Int?
}

struct RadarrRootFolder: Codable, Identifiable {
    let id: Int
    let path: String
    let accessible: Bool?
    let freeSpace: Int64?
}

struct RadarrSystemStatus: Codable {
    let version: String
    let buildTime: String?
    let isDebug: Bool?
    let isProduction: Bool?
    let isAdmin: Bool?
    let isUserInteractive: Bool?
    let startupPath: String?
    let appData: String?
    let osName: String?
    let isDocker: Bool?
}

struct RadarrAddMovieRequest: Codable {
    let title: String
    let qualityProfileId: Int
    let tmdbId: Int
    let year: Int
    let rootFolderPath: String
    let monitored: Bool
    let minimumAvailability: String
    let addOptions: RadarrAddOptions
    
    struct RadarrAddOptions: Codable {
        let searchForMovie: Bool
    }
}

struct RadarrLookupResult: Codable, Identifiable {
    let id: Int?
    let title: String
    let originalTitle: String?
    let sortTitle: String?
    let status: String?
    let overview: String?
    let inCinemas: String?
    let physicalRelease: String?
    let digitalRelease: String?
    let images: [RadarrImage]?
    let website: String?
    let year: Int
    let hasFile: Bool?
    let youTubeTrailerId: String?
    let studio: String?
    let runtime: Int?
    let imdbId: String?
    let tmdbId: Int
    let titleSlug: String?
    let certification: String?
    let genres: [String]?
    let ratings: RadarrRatings?
    
    // Utiliser tmdbId comme identifiant stable car id peut être nil
    var stableId: Int { id ?? tmdbId }
    
    var posterURL: URL? {
        guard let posterImage = images?.first(where: { $0.coverType == "poster" }) else {
            return nil
        }
        return URL(string: posterImage.remoteUrl ?? posterImage.url ?? "")
    }
}

struct RadarrQueue: Codable {
    let page: Int?
    let pageSize: Int?
    let sortKey: String?
    let sortDirection: String?
    let totalRecords: Int?
    let records: [RadarrQueueRecord]
}

struct RadarrQueueRecord: Codable, Identifiable {
    let id: Int
    let movieId: Int?
    let title: String?
    let status: String?
    let trackedDownloadStatus: String?
    let trackedDownloadState: String?
    let statusMessages: [RadarrStatusMessage]?
    let downloadId: String?
    let protocol_: String?
    let downloadClient: String?
    let indexer: String?
    let outputPath: String?
    let size: Double?
    let sizeleft: Double?
    let timeleft: String?
    
    enum CodingKeys: String, CodingKey {
        case id, movieId, title, status, trackedDownloadStatus, trackedDownloadState
        case statusMessages, downloadId, downloadClient, indexer, outputPath
        case size, sizeleft, timeleft
        case protocol_ = "protocol"
    }
    
    var progress: Double {
        guard let size = size, let sizeleft = sizeleft, size > 0 else { return 0 }
        return ((size - sizeleft) / size) * 100
    }
}

struct RadarrStatusMessage: Codable {
    let title: String?
    let messages: [String]?
}

// MARK: - Releases (Interactive Search)

struct RadarrRelease: Codable, Identifiable {
    let guid: String
    let quality: RadarrQualityWrapper?
    let customFormats: [RadarrCustomFormat]?
    let customFormatScore: Int?
    let qualityWeight: Int?
    let age: Int?
    let ageHours: Double?
    let ageMinutes: Double?
    let size: Int64?
    let indexerId: Int?
    let indexer: String?
    let releaseGroup: String?
    let releaseHash: String?
    let title: String?
    let sceneSource: Bool?
    let movieTitles: [String]?
    let languages: [RadarrLanguage]?
    let approved: Bool?
    let temporarilyRejected: Bool?
    let rejected: Bool?
    let rejections: [RadarrRejection]?
    let publishDate: String?
    let commentUrl: String?
    let downloadUrl: String?
    let infoUrl: String?
    let downloadAllowed: Bool?
    let releaseWeight: Int?
    let seeders: Int?
    let leechers: Int?
    let protocol_: String?
    let indexerFlags: [RadarrIndexerFlag]?
    let edition: String?
    let movieId: Int?
    let downloadClientId: Int?
    let downloadClient: String?
    let shouldOverride: Bool?
    let releaseType: String?

    var id: String { guid }
    
    var displayTitle: String {
        title ?? "Unknown Release"
    }
    
    var safeIndexerId: Int {
        indexerId ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case guid, quality, customFormats, customFormatScore, qualityWeight
        case age, ageHours, ageMinutes, size, indexerId, indexer
        case releaseGroup, releaseHash, title, sceneSource, movieTitles
        case languages, approved, temporarilyRejected, rejected, rejections
        case publishDate, commentUrl, downloadUrl, infoUrl, downloadAllowed
        case releaseWeight, seeders, leechers, indexerFlags, edition
        case movieId, downloadClientId, downloadClient, shouldOverride, releaseType
        case protocol_ = "protocol"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guid = try container.decode(String.self, forKey: .guid)
        quality = try container.decodeIfPresent(RadarrQualityWrapper.self, forKey: .quality)
        customFormats = try container.decodeIfPresent([RadarrCustomFormat].self, forKey: .customFormats)
        customFormatScore = try container.decodeIfPresent(Int.self, forKey: .customFormatScore)
        qualityWeight = try container.decodeIfPresent(Int.self, forKey: .qualityWeight)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        ageHours = try container.decodeIfPresent(Double.self, forKey: .ageHours)
        ageMinutes = try container.decodeIfPresent(Double.self, forKey: .ageMinutes)
        size = try container.decodeIfPresent(Int64.self, forKey: .size)
        indexerId = try container.decodeIfPresent(Int.self, forKey: .indexerId)
        indexer = try container.decodeIfPresent(String.self, forKey: .indexer)
        releaseGroup = try container.decodeIfPresent(String.self, forKey: .releaseGroup)
        releaseHash = try container.decodeIfPresent(String.self, forKey: .releaseHash)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        sceneSource = try container.decodeIfPresent(Bool.self, forKey: .sceneSource)
        movieTitles = try container.decodeIfPresent([String].self, forKey: .movieTitles)
        languages = try container.decodeIfPresent([RadarrLanguage].self, forKey: .languages)
        approved = try container.decodeIfPresent(Bool.self, forKey: .approved)
        temporarilyRejected = try container.decodeIfPresent(Bool.self, forKey: .temporarilyRejected)
        rejected = try container.decodeIfPresent(Bool.self, forKey: .rejected)
        rejections = try container.decodeIfPresent([RadarrRejection].self, forKey: .rejections)
        publishDate = try container.decodeIfPresent(String.self, forKey: .publishDate)
        commentUrl = try container.decodeIfPresent(String.self, forKey: .commentUrl)
        downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
        infoUrl = try container.decodeIfPresent(String.self, forKey: .infoUrl)
        downloadAllowed = try container.decodeIfPresent(Bool.self, forKey: .downloadAllowed)
        releaseWeight = try container.decodeIfPresent(Int.self, forKey: .releaseWeight)
        seeders = try container.decodeIfPresent(Int.self, forKey: .seeders)
        leechers = try container.decodeIfPresent(Int.self, forKey: .leechers)
        protocol_ = try container.decodeIfPresent(String.self, forKey: .protocol_)
        edition = try container.decodeIfPresent(String.self, forKey: .edition)
        movieId = try container.decodeIfPresent(Int.self, forKey: .movieId)
        downloadClientId = try container.decodeIfPresent(Int.self, forKey: .downloadClientId)
        downloadClient = try container.decodeIfPresent(String.self, forKey: .downloadClient)
        shouldOverride = try container.decodeIfPresent(Bool.self, forKey: .shouldOverride)
        releaseType = try container.decodeIfPresent(String.self, forKey: .releaseType)
        
        // Handle indexerFlags which can be either [RadarrIndexerFlag] or Int or missing
        if let flagsArray = try? container.decodeIfPresent([RadarrIndexerFlag].self, forKey: .indexerFlags) {
            indexerFlags = flagsArray
        } else if let flagsInt = try? container.decodeIfPresent(Int.self, forKey: .indexerFlags) {
            // Convert Int to array with a single synthetic flag if needed
            indexerFlags = flagsInt > 0 ? [RadarrIndexerFlag(id: flagsInt, name: "Flag \(flagsInt)")] : nil
        } else {
            indexerFlags = nil
        }
    }
}

struct RadarrQualityWrapper: Codable {
    let quality: RadarrQualityInfo?
    let revision: RadarrRevision?
}

struct RadarrQualityInfo: Codable {
    let id: Int?
    let name: String?
    let source: String?
    let resolution: Int?
    let modifier: String?
}

struct RadarrRevision: Codable {
    let version: Int?
    let real: Int?
    let isRepack: Bool?
}

struct RadarrCustomFormat: Codable {
    let id: Int?
    let name: String?
}

struct RadarrLanguage: Codable {
    let id: Int?
    let name: String?
}

struct RadarrRejection: Codable {
    let reason: String?
    let type: String?
    
    init(from decoder: Decoder) throws {
        // Handle both string format and object format
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            reason = try container.decodeIfPresent(String.self, forKey: .reason)
            type = try container.decodeIfPresent(String.self, forKey: .type)
        } else if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            reason = stringValue
            type = nil
        } else {
            reason = nil
            type = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case reason, type
    }
}

struct RadarrIndexerFlag: Codable {
    let id: Int?
    let name: String?
}
