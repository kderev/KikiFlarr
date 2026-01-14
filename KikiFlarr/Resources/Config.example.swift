import Foundation

// ============================================================================
// CONFIGURATION EXEMPLE - KikiFlarr
// ============================================================================
//
// Ce fichier montre comment configurer vos instances pour le développement.
// NE COMMITEZ JAMAIS ce fichier avec vos vraies clés API !
//
// Pour utiliser ce fichier :
// 1. Copiez-le en "Config.swift"
// 2. Remplacez les valeurs par vos vraies URLs et clés API
// 3. Ajoutez "Config.swift" à votre .gitignore
//
// ============================================================================

struct DevelopmentConfig {
    
    // MARK: - Overseerr
    // Overseerr est utilisé pour la recherche de films/séries
    // Récupérez votre clé API dans : Settings > General > API Key
    
    static let overseerr = (
        name: "Overseerr Local",
        baseURL: "http://192.168.1.100:5055",
        apiKey: "votre-cle-api-overseerr"
    )
    
    // MARK: - Radarr (Films)
    // Radarr gère vos films
    // Récupérez votre clé API dans : Settings > General > API Key
    
    static let radarrLocal = (
        name: "Radarr Maison",
        baseURL: "http://192.168.1.100:7878",
        apiKey: "votre-cle-api-radarr-local"
    )
    
    static let radarrSeedbox = (
        name: "Radarr Seedbox",
        baseURL: "https://radarr.votre-seedbox.com",
        apiKey: "votre-cle-api-radarr-seedbox"
    )
    
    // MARK: - Sonarr (Séries)
    // Sonarr gère vos séries TV
    // Récupérez votre clé API dans : Settings > General > API Key
    
    static let sonarrLocal = (
        name: "Sonarr Maison",
        baseURL: "http://192.168.1.100:8989",
        apiKey: "votre-cle-api-sonarr-local"
    )
    
    static let sonarrSeedbox = (
        name: "Sonarr Seedbox",
        baseURL: "https://sonarr.votre-seedbox.com",
        apiKey: "votre-cle-api-sonarr-seedbox"
    )
    
    // MARK: - qBittorrent
    // qBittorrent pour le suivi des téléchargements
    // Activez l'interface Web dans : Tools > Options > Web UI
    
    static let qbittorrentLocal = (
        name: "qBittorrent Maison",
        baseURL: "http://192.168.1.100:8080",
        username: "admin",
        password: "adminadmin"
    )
    
    static let qbittorrentSeedbox = (
        name: "qBittorrent Seedbox",
        baseURL: "https://qbit.votre-seedbox.com",
        username: "votre-username",
        password: "votre-password"
    )
}

// ============================================================================
// EXEMPLE D'UTILISATION POUR LE DEBUG
// ============================================================================
//
// Pour pré-configurer des instances en mode développement, vous pouvez
// utiliser cette fonction dans votre AppDelegate ou au lancement :
//
// func setupDebugInstances() {
//     let manager = InstanceManager()
//     
//     // Ajouter Overseerr
//     let overseerr = ServiceInstance(
//         name: DevelopmentConfig.overseerr.name,
//         baseURL: DevelopmentConfig.overseerr.baseURL,
//         serviceType: .overseerr
//     )
//     manager.addInstance(overseerr, apiKey: DevelopmentConfig.overseerr.apiKey)
//     
//     // Ajouter Radarr
//     let radarr = ServiceInstance(
//         name: DevelopmentConfig.radarrLocal.name,
//         baseURL: DevelopmentConfig.radarrLocal.baseURL,
//         serviceType: .radarr
//     )
//     manager.addInstance(radarr, apiKey: DevelopmentConfig.radarrLocal.apiKey)
//     
//     // etc...
// }
//
// ============================================================================

// MARK: - URLs par défaut des services

enum DefaultPorts {
    static let overseerr = 5055
    static let radarr = 7878
    static let sonarr = 8989
    static let qbittorrent = 8080
}

// MARK: - Endpoints API de référence

enum APIEndpoints {
    
    enum Radarr {
        static let systemStatus = "/api/v3/system/status"
        static let movie = "/api/v3/movie"
        static let movieLookup = "/api/v3/movie/lookup"
        static let qualityProfile = "/api/v3/qualityprofile"
        static let rootFolder = "/api/v3/rootfolder"
        static let queue = "/api/v3/queue"
        static let command = "/api/v3/command"
    }
    
    enum Sonarr {
        static let systemStatus = "/api/v3/system/status"
        static let series = "/api/v3/series"
        static let seriesLookup = "/api/v3/series/lookup"
        static let qualityProfile = "/api/v3/qualityprofile"
        static let rootFolder = "/api/v3/rootfolder"
        static let queue = "/api/v3/queue"
        static let command = "/api/v3/command"
    }
    
    enum QBittorrent {
        static let login = "/api/v2/auth/login"
        static let logout = "/api/v2/auth/logout"
        static let version = "/api/v2/app/version"
        static let torrents = "/api/v2/torrents/info"
        static let pause = "/api/v2/torrents/pause"
        static let resume = "/api/v2/torrents/resume"
        static let delete = "/api/v2/torrents/delete"
        static let maindata = "/api/v2/sync/maindata"
    }
    
    enum Overseerr {
        static let status = "/api/v1/status"
        static let search = "/api/v1/search"
        static let movie = "/api/v1/movie"
        static let tv = "/api/v1/tv"
        static let request = "/api/v1/request"
        static let discover = "/api/v1/discover"
    }
}
