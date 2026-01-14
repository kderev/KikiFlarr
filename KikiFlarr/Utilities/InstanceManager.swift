import Foundation
import SwiftUI

@MainActor
class InstanceManager: ObservableObject {
    @Published var instances: [ServiceInstance] = []
    @Published var groups: [InstanceGroup] = []
    @Published var tmdbApiKey: String = ""
    
    private let userDefaultsKey = "mediaHub.instances"
    private let groupsUserDefaultsKey = "mediaHub.groups"
    private let tmdbApiKeyKey = "mediaHub.tmdbApiKey"
    private let keychain = KeychainManager.shared
    
    var hasTMDBConfigured: Bool {
        !tmdbApiKey.isEmpty
    }
    
    init() {
        loadGroups()
        loadInstances()
        loadTMDBApiKey()
    }
    
    // MARK: - Persistence
    
    private func loadInstances() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([ServiceInstance].self, from: data) else {
            instances = []
            return
        }
        instances = decoded
    }
    
    private func saveInstances() {
        guard let encoded = try? JSONEncoder().encode(instances) else { return }
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }
    
    // MARK: - Groups Persistence
    
    private func loadGroups() {
        guard let data = UserDefaults.standard.data(forKey: groupsUserDefaultsKey),
              let decoded = try? JSONDecoder().decode([InstanceGroup].self, from: data) else {
            groups = []
            return
        }
        groups = decoded.sorted { $0.order < $1.order }
    }
    
    private func saveGroups() {
        guard let encoded = try? JSONEncoder().encode(groups) else { return }
        UserDefaults.standard.set(encoded, forKey: groupsUserDefaultsKey)
    }
    
    // MARK: - Group CRUD Operations
    
    func addGroup(_ group: InstanceGroup) {
        var newGroup = group
        newGroup.order = groups.count
        groups.append(newGroup)
        saveGroups()
    }
    
    func updateGroup(_ group: InstanceGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            saveGroups()
        }
    }
    
    func deleteGroup(_ group: InstanceGroup) {
        for i in instances.indices where instances[i].groupId == group.id {
            instances[i].groupId = nil
        }
        saveInstances()
        
        groups.removeAll { $0.id == group.id }
        saveGroups()
    }
    
    func moveGroup(from source: IndexSet, to destination: Int) {
        groups.move(fromOffsets: source, toOffset: destination)
        for (index, _) in groups.enumerated() {
            groups[index].order = index
        }
        saveGroups()
    }
    
    func group(for instance: ServiceInstance) -> InstanceGroup? {
        guard let groupId = instance.groupId else { return nil }
        return groups.first { $0.id == groupId }
    }
    
    func instances(in group: InstanceGroup) -> [ServiceInstance] {
        instances.filter { $0.groupId == group.id }
    }
    
    var ungroupedInstances: [ServiceInstance] {
        instances.filter { $0.groupId == nil }
    }
    
    // MARK: - TMDB API Key
    
    private func loadTMDBApiKey() {
        tmdbApiKey = keychain.getTMDBApiKey() ?? ""
    }
    
    func saveTMDBApiKey(_ apiKey: String) {
        tmdbApiKey = apiKey
        if apiKey.isEmpty {
            keychain.deleteTMDBApiKey()
        } else {
            try? keychain.saveTMDBApiKey(apiKey)
        }
    }
    
    func tmdbService() -> TMDBService? {
        guard hasTMDBConfigured else { return nil }
        return TMDBService(apiKey: tmdbApiKey)
    }
    
    func testTMDBConnection() async -> ConnectionTestResult {
        guard let service = tmdbService() else {
            return ConnectionTestResult(success: false, message: "Clé API TMDB manquante", responseTime: nil)
        }
        
        do {
            return try await service.testConnection()
        } catch {
            return ConnectionTestResult(success: false, message: error.localizedDescription, responseTime: nil)
        }
    }
    
    // MARK: - CRUD Operations
    
    func addInstance(_ instance: ServiceInstance, apiKey: String? = nil, username: String? = nil, password: String? = nil) {
        instances.append(instance)
        saveInstances()
        
        if let apiKey = apiKey {
            try? keychain.saveAPIKey(apiKey, for: instance.id)
        }
        
        if let username = username, let password = password {
            try? keychain.saveCredentials(username: username, password: password, for: instance.id)
        }
    }
    
    func updateInstance(_ instance: ServiceInstance, apiKey: String? = nil, username: String? = nil, password: String? = nil) {
        if let index = instances.firstIndex(where: { $0.id == instance.id }) {
            instances[index] = instance
            saveInstances()
            
            if let apiKey = apiKey {
                try? keychain.saveAPIKey(apiKey, for: instance.id)
            }
            
            if let username = username, let password = password {
                try? keychain.saveCredentials(username: username, password: password, for: instance.id)
            }
        }
    }
    
    func deleteInstance(_ instance: ServiceInstance) {
        instances.removeAll { $0.id == instance.id }
        saveInstances()
        keychain.deleteAll(for: instance.id)
    }
    
    func deleteInstance(at offsets: IndexSet) {
        for index in offsets {
            let instance = instances[index]
            keychain.deleteAll(for: instance.id)
        }
        instances.remove(atOffsets: offsets)
        saveInstances()
    }
    
    // MARK: - Filtering
    
    func instances(of type: ServiceType) -> [ServiceInstance] {
        instances.filter { $0.serviceType == type && $0.isEnabled }
    }
    
    var radarrInstances: [ServiceInstance] {
        instances(of: .radarr)
    }
    
    var sonarrInstances: [ServiceInstance] {
        instances(of: .sonarr)
    }
    
    var qbittorrentInstances: [ServiceInstance] {
        instances(of: .qbittorrent)
    }
    
    var overseerrInstances: [ServiceInstance] {
        instances(of: .overseerr)
    }
    
    var primaryOverseerr: ServiceInstance? {
        overseerrInstances.first
    }
    
    // MARK: - Service Creation
    
    func radarrService(for instance: ServiceInstance) -> RadarrService? {
        guard instance.serviceType == .radarr,
              let apiKey = keychain.getAPIKey(for: instance.id) else {
            return nil
        }
        return RadarrService(baseURL: instance.baseURL, apiKey: apiKey)
    }
    
    func sonarrService(for instance: ServiceInstance) -> SonarrService? {
        guard instance.serviceType == .sonarr,
              let apiKey = keychain.getAPIKey(for: instance.id) else {
            return nil
        }
        return SonarrService(baseURL: instance.baseURL, apiKey: apiKey)
    }
    
    func qbittorrentService(for instance: ServiceInstance) -> QBittorrentService? {
        guard instance.serviceType == .qbittorrent,
              let credentials = keychain.getCredentials(for: instance.id) else {
            return nil
        }
        return QBittorrentService(
            baseURL: instance.baseURL,
            username: credentials.username,
            password: credentials.password
        )
    }
    
    func overseerrService(for instance: ServiceInstance) -> OverseerrService? {
        guard instance.serviceType == .overseerr,
              let apiKey = keychain.getAPIKey(for: instance.id) else {
            return nil
        }
        return OverseerrService(baseURL: instance.baseURL, apiKey: apiKey)
    }
    
    // MARK: - Connection Testing
    
    func testConnection(for instance: ServiceInstance) async -> ConnectionTestResult {
        switch instance.serviceType {
        case .radarr:
            guard let service = radarrService(for: instance) else {
                return ConnectionTestResult(success: false, message: "Clé API manquante", responseTime: nil)
            }
            return await (try? service.testConnection()) ?? ConnectionTestResult(success: false, message: "Erreur", responseTime: nil)
            
        case .sonarr:
            guard let service = sonarrService(for: instance) else {
                return ConnectionTestResult(success: false, message: "Clé API manquante", responseTime: nil)
            }
            return await (try? service.testConnection()) ?? ConnectionTestResult(success: false, message: "Erreur", responseTime: nil)
            
        case .qbittorrent:
            guard let service = qbittorrentService(for: instance) else {
                return ConnectionTestResult(success: false, message: "Identifiants manquants", responseTime: nil)
            }
            return await (try? service.testConnection()) ?? ConnectionTestResult(success: false, message: "Erreur", responseTime: nil)
            
        case .overseerr:
            guard let service = overseerrService(for: instance) else {
                return ConnectionTestResult(success: false, message: "Clé API manquante", responseTime: nil)
            }
            return await (try? service.testConnection()) ?? ConnectionTestResult(success: false, message: "Erreur", responseTime: nil)
        }
    }
}
