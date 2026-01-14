import Foundation

enum ServiceType: String, Codable, CaseIterable, Identifiable {
    case radarr = "Radarr"
    case sonarr = "Sonarr"
    case qbittorrent = "qBittorrent"
    case overseerr = "Overseerr"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .radarr: return "film"
        case .sonarr: return "tv"
        case .qbittorrent: return "arrow.down.circle"
        case .overseerr: return "magnifyingglass"
        }
    }
    
    var color: String {
        switch self {
        case .radarr: return "orange"
        case .sonarr: return "blue"
        case .qbittorrent: return "green"
        case .overseerr: return "purple"
        }
    }
}

struct ServiceInstance: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var baseURL: String
    var serviceType: ServiceType
    var isEnabled: Bool
    var groupId: UUID?
    
    init(id: UUID = UUID(), name: String, baseURL: String, serviceType: ServiceType, isEnabled: Bool = true, groupId: UUID? = nil) {
        self.id = id
        self.name = name
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.serviceType = serviceType
        self.isEnabled = isEnabled
        self.groupId = groupId
    }
    
    var displayURL: String {
        baseURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
    }
}

struct ConnectionTestResult {
    let success: Bool
    let message: String
    let responseTime: TimeInterval?
}
