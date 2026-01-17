import Foundation

struct QBittorrentTorrent: Codable, Identifiable {
    let hash: String
    let name: String
    let size: Int64
    let progress: Double
    let dlspeed: Int64
    let upspeed: Int64
    let priority: Int?
    let numSeeds: Int?
    let numComplete: Int?
    let numLeechs: Int?
    let numIncomplete: Int?
    let ratio: Double
    let eta: Int64
    let state: String
    let seqDl: Bool?
    let fLPiecePrio: Bool?
    let category: String?
    let tags: String?
    let superSeeding: Bool?
    let forceStart: Bool?
    let savePath: String?
    let addedOn: Int64?
    let completionOn: Int64?
    let tracker: String?
    let dlLimit: Int64?
    let upLimit: Int64?
    let downloaded: Int64?
    let uploaded: Int64?
    let downloadedSession: Int64?
    let uploadedSession: Int64?
    let amountLeft: Int64?
    let completed: Int64?
    let maxRatio: Double?
    let maxSeedingTime: Int64?
    let autoTmm: Bool?
    let timeActive: Int64?
    let contentPath: String?
    
    var id: String { hash }
    
    enum CodingKeys: String, CodingKey {
        case hash, name, size, progress, dlspeed, upspeed, priority
        case numSeeds
        case numComplete
        case numLeechs
        case numIncomplete
        case ratio, eta, state
        case seqDl
        case fLPiecePrio
        case category, tags
        case superSeeding
        case forceStart
        case savePath
        case addedOn
        case completionOn
        case tracker
        case dlLimit
        case upLimit
        case downloaded, uploaded
        case downloadedSession
        case uploadedSession
        case amountLeft
        case completed
        case maxRatio
        case maxSeedingTime
        case autoTmm
        case timeActive
        case contentPath
    }
    
    var stateDescription: String {
        switch state {
        case "error": return "Erreur"
        case "missingFiles": return "Fichiers manquants"
        case "uploading": return "Envoi"
        case "pausedUP", "stoppedUP": return "En pause (envoi)"
        case "queuedUP": return "En file (envoi)"
        case "stalledUP": return "Bloqué (envoi)"
        case "checkingUP": return "Vérification (envoi)"
        case "forcedUP": return "Envoi forcé"
        case "allocating": return "Allocation"
        case "downloading": return "Téléchargement"
        case "metaDL": return "Métadonnées"
        case "pausedDL", "stoppedDL", "stopped": return "En pause"
        case "queuedDL": return "En file"
        case "stalledDL": return "Bloqué"
        case "checkingDL": return "Vérification"
        case "forcedDL": return "Téléchargement forcé"
        case "checkingResumeData": return "Vérification données"
        case "moving": return "Déplacement"
        default: return state
        }
    }
    
    var stateIcon: String {
        switch state {
        case "error", "missingFiles":
            return "exclamationmark.triangle.fill"
        case "uploading", "forcedUP", "stalledUP":
            return "arrow.up.circle.fill"
        case "pausedUP", "pausedDL", "stoppedUP", "stoppedDL", "stopped":
            return "pause.circle.fill"
        case "queuedUP", "queuedDL":
            return "clock.fill"
        case "downloading", "forcedDL":
            return "arrow.down.circle.fill"
        case "stalledDL":
            return "exclamationmark.circle.fill"
        case "checkingUP", "checkingDL", "checkingResumeData":
            return "checkmark.circle.fill"
        case "metaDL":
            return "doc.circle.fill"
        case "allocating":
            return "externaldrive.fill"
        case "moving":
            return "folder.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    var stateColor: String {
        switch state {
        case "error", "missingFiles":
            return "red"
        case "uploading", "forcedUP":
            return "green"
        case "stalledUP":
            return "orange"
        case "pausedUP", "pausedDL", "stoppedUP", "stoppedDL", "stopped":
            return "gray"
        case "queuedUP", "queuedDL":
            return "blue"
        case "downloading", "forcedDL":
            return "blue"
        case "stalledDL":
            return "orange"
        case "checkingUP", "checkingDL", "checkingResumeData":
            return "purple"
        case "metaDL", "allocating":
            return "cyan"
        case "moving":
            return "indigo"
        default:
            return "gray"
        }
    }
    
    var isDownloading: Bool {
        ["downloading", "forcedDL", "metaDL", "stalledDL", "queuedDL", "checkingDL", "allocating"].contains(state)
    }
    
    var isUploading: Bool {
        ["uploading", "forcedUP", "stalledUP", "queuedUP", "checkingUP"].contains(state)
    }
    
    var isPaused: Bool {
        // qBittorrent v5+ utilise "stopped" au lieu de "paused"
        let pausedStates = ["pausedDL", "pausedUP", "stoppedDL", "stoppedUP", "stopped"]
        return pausedStates.contains(state) || state.lowercased().contains("paused") || state.lowercased().contains("stopped")
    }
    
    var canResume: Bool {
        isPaused || state == "error"
    }
    
    var canPause: Bool {
        !isPaused && state != "error"
    }
    
    var formattedETA: String {
        guard eta > 0 && eta < 8640000 else { return "∞" }
        
        let hours = eta / 3600
        let minutes = (eta % 3600) / 60
        let seconds = eta % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

struct QBittorrentMainData: Codable {
    let rid: Int?
    let fullUpdate: Bool?
    let torrents: [String: QBittorrentTorrent]?
    let torrentsRemoved: [String]?
    let categories: [String: QBittorrentCategory]?
    let categoriesRemoved: [String]?
    let tags: [String]?
    let tagsRemoved: [String]?
    let serverState: QBittorrentServerState?
    
    enum CodingKeys: String, CodingKey {
        case rid
        case fullUpdate
        case torrents
        case torrentsRemoved
        case categories
        case categoriesRemoved
        case tags
        case tagsRemoved
        case serverState
    }
}

struct QBittorrentCategory: Codable {
    let name: String?
    let savePath: String?
}

struct QBittorrentServerState: Codable {
    let allTimeDl: Int64?
    let allTimeUl: Int64?
    let averageTimeQueue: Int64?
    let connectionStatus: String?
    let dhtNodes: Int?
    let dlInfoData: Int64?
    let dlInfoSpeed: Int64?
    let dlRateLimit: Int64?
    let freeSpaceOnDisk: Int64?
    let globalRatio: String?
    let queuedIoJobs: Int?
    let queueing: Bool?
    let readCacheHits: String?
    let readCacheOverload: String?
    let refreshInterval: Int?
    let totalBuffersSize: Int64?
    let totalPeerConnections: Int?
    let totalQueuedSize: Int64?
    let totalWastedSession: Int64?
    let upInfoData: Int64?
    let upInfoSpeed: Int64?
    let upRateLimit: Int64?
    let useAltSpeedLimits: Bool?
    let writeCacheOverload: String?
    
    enum CodingKeys: String, CodingKey {
        case allTimeDl = "alltime_dl"
        case allTimeUl = "alltime_ul"
        case averageTimeQueue
        case connectionStatus
        case dhtNodes
        case dlInfoData
        case dlInfoSpeed
        case dlRateLimit
        case freeSpaceOnDisk
        case globalRatio
        case queuedIoJobs
        case queueing
        case readCacheHits
        case readCacheOverload
        case refreshInterval
        case totalBuffersSize
        case totalPeerConnections
        case totalQueuedSize
        case totalWastedSession
        case upInfoData
        case upInfoSpeed
        case upRateLimit
        case useAltSpeedLimits
        case writeCacheOverload
    }
}

struct QBittorrentVersion: Codable {
    let version: String
}
