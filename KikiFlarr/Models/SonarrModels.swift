import Foundation

struct SonarrSeries: Codable, Identifiable {
    let id: Int
    let title: String
    let alternateTitles: [SonarrAlternateTitle]?
    let sortTitle: String?
    let status: String?
    let ended: Bool?
    let overview: String?
    let previousAiring: String?
    let network: String?
    let airTime: String?
    let images: [SonarrImage]?
    let seasons: [SonarrSeason]?
    let year: Int
    let path: String?
    var qualityProfileId: Int?
    let languageProfileId: Int?
    let seasonFolder: Bool?
    let monitored: Bool?
    let useSceneNumbering: Bool?
    let runtime: Int?
    let tvdbId: Int?
    let tvRageId: Int?
    let tvMazeId: Int?
    let firstAired: String?
    let seriesType: String?
    let cleanTitle: String?
    let imdbId: String?
    let titleSlug: String?
    let certification: String?
    let genres: [String]?
    let tags: [Int]?
    let added: String?
    let ratings: SonarrRatings?
    let statistics: SonarrStatistics?
    
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

struct SonarrAlternateTitle: Codable {
    let title: String
    let seasonNumber: Int?
}

struct SonarrImage: Codable {
    let coverType: String
    let url: String?
    let remoteUrl: String?
}

struct SonarrSeason: Codable, Identifiable {
    let seasonNumber: Int
    let monitored: Bool?
    let statistics: SonarrSeasonStatistics?
    
    var id: Int { seasonNumber }
}

struct SonarrSeasonStatistics: Codable {
    let previousAiring: String?
    let episodeFileCount: Int?
    let episodeCount: Int?
    let totalEpisodeCount: Int?
    let sizeOnDisk: Int64?
    let percentOfEpisodes: Double?
}

struct SonarrRatings: Codable {
    let votes: Int?
    let value: Double?
}

struct SonarrStatistics: Codable {
    let seasonCount: Int?
    let episodeFileCount: Int?
    let episodeCount: Int?
    let totalEpisodeCount: Int?
    let sizeOnDisk: Int64?
    let percentOfEpisodes: Double?
}

struct SonarrQualityProfile: Codable, Identifiable {
    let id: Int
    let name: String
    let upgradeAllowed: Bool?
    let cutoff: Int?
}

struct SonarrRootFolder: Codable, Identifiable {
    let id: Int
    let path: String
    let accessible: Bool?
    let freeSpace: Int64?
}

struct SonarrSystemStatus: Codable {
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

struct SonarrAddSeriesRequest: Codable {
    let title: String
    let qualityProfileId: Int
    let languageProfileId: Int?
    let tvdbId: Int
    let titleSlug: String
    let images: [SonarrImage]
    let seasons: [SonarrAddSeason]
    let rootFolderPath: String
    let monitored: Bool
    let seasonFolder: Bool
    let seriesType: String
    let addOptions: SonarrAddOptions
    
    struct SonarrAddOptions: Codable {
        let ignoreEpisodesWithFiles: Bool
        let ignoreEpisodesWithoutFiles: Bool
        let searchForMissingEpisodes: Bool
    }
    
    struct SonarrAddSeason: Codable {
        let seasonNumber: Int
        let monitored: Bool
    }
}

struct SonarrLookupResult: Codable, Identifiable {
    let id: Int?
    let title: String
    let alternateTitles: [SonarrAlternateTitle]?
    let sortTitle: String?
    let status: String?
    let ended: Bool?
    let overview: String?
    let network: String?
    let airTime: String?
    let images: [SonarrImage]?
    let seasons: [SonarrSeason]?
    let year: Int
    let runtime: Int?
    let tvdbId: Int
    let tvRageId: Int?
    let tvMazeId: Int?
    let firstAired: String?
    let seriesType: String?
    let cleanTitle: String?
    let imdbId: String?
    let titleSlug: String?
    let certification: String?
    let genres: [String]?
    let ratings: SonarrRatings?
    let statistics: SonarrStatistics?
    
    // Utiliser tvdbId comme identifiant stable car id peut être nil
    var stableId: Int { id ?? tvdbId }
    
    var posterURL: URL? {
        guard let posterImage = images?.first(where: { $0.coverType == "poster" }) else {
            return nil
        }
        return URL(string: posterImage.remoteUrl ?? posterImage.url ?? "")
    }
}

struct SonarrQueue: Codable {
    let page: Int?
    let pageSize: Int?
    let sortKey: String?
    let sortDirection: String?
    let totalRecords: Int?
    let records: [SonarrQueueRecord]
}

struct SonarrQueueRecord: Codable, Identifiable {
    let id: Int
    let seriesId: Int?
    let episodeId: Int?
    let seasonNumber: Int?
    let title: String?
    let status: String?
    let trackedDownloadStatus: String?
    let trackedDownloadState: String?
    let statusMessages: [SonarrStatusMessage]?
    let downloadId: String?
    let protocol_: String?
    let downloadClient: String?
    let indexer: String?
    let outputPath: String?
    let size: Double?
    let sizeleft: Double?
    let timeleft: String?
    
    enum CodingKeys: String, CodingKey {
        case id, seriesId, episodeId, seasonNumber, title, status
        case trackedDownloadStatus, trackedDownloadState, statusMessages
        case downloadId, downloadClient, indexer, outputPath
        case size, sizeleft, timeleft
        case protocol_ = "protocol"
    }
    
    var progress: Double {
        guard let size = size, let sizeleft = sizeleft, size > 0 else { return 0 }
        return ((size - sizeleft) / size) * 100
    }
}

struct SonarrCalendarEpisode: Codable, Identifiable {
    let id: Int
    let seriesId: Int?
    let episodeFileId: Int?
    let seasonNumber: Int?
    let episodeNumber: Int?
    let title: String?
    let airDate: String?
    let airDateUtc: String?
    var hasFile: Bool?
    var monitored: Bool?
    let series: SonarrSeries?
    let episodeFile: SonarrEpisodeFile?
}

struct SonarrEpisodeFile: Codable, Identifiable {
    let id: Int
    let quality: SonarrQualityWrapper?
    let size: Int64?
}

struct SonarrStatusMessage: Codable {
    let title: String?
    let messages: [String]?
}

// MARK: - Releases (Interactive Search)

struct SonarrRelease: Codable, Identifiable {
    let guid: String
    let quality: SonarrQualityWrapper?
    let customFormats: [SonarrCustomFormat]?
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
    let fullSeason: Bool?
    let sceneSource: Bool?
    let seasonNumber: Int?
    let languages: [SonarrLanguage]?
    let languageWeight: Int?
    let approved: Bool?
    let temporarilyRejected: Bool?
    let rejected: Bool?
    let rejections: [SonarrRejection]?
    let publishDate: String?
    let commentUrl: String?
    let downloadUrl: String?
    let infoUrl: String?
    let downloadAllowed: Bool?
    let releaseWeight: Int?
    let seeders: Int?
    let leechers: Int?
    let protocol_: String?
    let indexerFlags: [SonarrIndexerFlag]?
    let seriesTitle: String?
    let episodeNumbers: [Int]?
    let absoluteEpisodeNumbers: [Int]?
    let mappedSeasonNumber: Int?
    let mappedEpisodeNumbers: [Int]?
    let mappedAbsoluteEpisodeNumbers: [Int]?
    let special: Bool?
    let seriesId: Int?
    let episodeId: Int?
    let downloadClientId: Int?
    let downloadClient: String?
    let shouldOverride: Bool?

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
        case releaseGroup, releaseHash, title, fullSeason, sceneSource
        case seasonNumber, languages, languageWeight, approved
        case temporarilyRejected, rejected, rejections, publishDate
        case commentUrl, downloadUrl, infoUrl, downloadAllowed
        case releaseWeight, seeders, leechers, indexerFlags
        case seriesTitle, episodeNumbers, absoluteEpisodeNumbers
        case mappedSeasonNumber, mappedEpisodeNumbers
        case mappedAbsoluteEpisodeNumbers, special
        case seriesId, episodeId, downloadClientId, downloadClient, shouldOverride
        case protocol_ = "protocol"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guid = try container.decode(String.self, forKey: .guid)
        quality = try container.decodeIfPresent(SonarrQualityWrapper.self, forKey: .quality)
        customFormats = try container.decodeIfPresent([SonarrCustomFormat].self, forKey: .customFormats)
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
        fullSeason = try container.decodeIfPresent(Bool.self, forKey: .fullSeason)
        sceneSource = try container.decodeIfPresent(Bool.self, forKey: .sceneSource)
        seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber)
        languages = try container.decodeIfPresent([SonarrLanguage].self, forKey: .languages)
        languageWeight = try container.decodeIfPresent(Int.self, forKey: .languageWeight)
        approved = try container.decodeIfPresent(Bool.self, forKey: .approved)
        temporarilyRejected = try container.decodeIfPresent(Bool.self, forKey: .temporarilyRejected)
        rejected = try container.decodeIfPresent(Bool.self, forKey: .rejected)
        rejections = try container.decodeIfPresent([SonarrRejection].self, forKey: .rejections)
        publishDate = try container.decodeIfPresent(String.self, forKey: .publishDate)
        commentUrl = try container.decodeIfPresent(String.self, forKey: .commentUrl)
        downloadUrl = try container.decodeIfPresent(String.self, forKey: .downloadUrl)
        infoUrl = try container.decodeIfPresent(String.self, forKey: .infoUrl)
        downloadAllowed = try container.decodeIfPresent(Bool.self, forKey: .downloadAllowed)
        releaseWeight = try container.decodeIfPresent(Int.self, forKey: .releaseWeight)
        seeders = try container.decodeIfPresent(Int.self, forKey: .seeders)
        leechers = try container.decodeIfPresent(Int.self, forKey: .leechers)
        protocol_ = try container.decodeIfPresent(String.self, forKey: .protocol_)
        seriesTitle = try container.decodeIfPresent(String.self, forKey: .seriesTitle)
        episodeNumbers = try container.decodeIfPresent([Int].self, forKey: .episodeNumbers)
        absoluteEpisodeNumbers = try container.decodeIfPresent([Int].self, forKey: .absoluteEpisodeNumbers)
        mappedSeasonNumber = try container.decodeIfPresent(Int.self, forKey: .mappedSeasonNumber)
        mappedEpisodeNumbers = try container.decodeIfPresent([Int].self, forKey: .mappedEpisodeNumbers)
        mappedAbsoluteEpisodeNumbers = try container.decodeIfPresent([Int].self, forKey: .mappedAbsoluteEpisodeNumbers)
        special = try container.decodeIfPresent(Bool.self, forKey: .special)
        seriesId = try container.decodeIfPresent(Int.self, forKey: .seriesId)
        episodeId = try container.decodeIfPresent(Int.self, forKey: .episodeId)
        downloadClientId = try container.decodeIfPresent(Int.self, forKey: .downloadClientId)
        downloadClient = try container.decodeIfPresent(String.self, forKey: .downloadClient)
        shouldOverride = try container.decodeIfPresent(Bool.self, forKey: .shouldOverride)
        
        // Handle indexerFlags which can be either [SonarrIndexerFlag] or Int or missing
        if let flagsArray = try? container.decodeIfPresent([SonarrIndexerFlag].self, forKey: .indexerFlags) {
            indexerFlags = flagsArray
        } else if let flagsInt = try? container.decodeIfPresent(Int.self, forKey: .indexerFlags) {
            indexerFlags = flagsInt > 0 ? [SonarrIndexerFlag(id: flagsInt, name: "Flag \(flagsInt)")] : nil
        } else {
            indexerFlags = nil
        }
    }
}

struct SonarrQualityWrapper: Codable {
    let quality: SonarrQualityInfo?
    let revision: SonarrRevision?
}

struct SonarrQualityInfo: Codable {
    let id: Int?
    let name: String?
    let source: String?
    let resolution: Int?
}

struct SonarrRevision: Codable {
    let version: Int?
    let real: Int?
    let isRepack: Bool?
}

struct SonarrCustomFormat: Codable {
    let id: Int?
    let name: String?
}

struct SonarrLanguage: Codable {
    let id: Int?
    let name: String?
}

struct SonarrRejection: Codable {
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

struct SonarrIndexerFlag: Codable {
    let id: Int?
    let name: String?
}
