import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isAddingInstance = false
    @Published var editingInstance: ServiceInstance?
    
    @Published var instanceName = ""
    @Published var instanceURL = ""
    @Published var instanceType: ServiceType = .radarr
    @Published var apiKey = ""
    @Published var username = ""
    @Published var password = ""
    @Published var selectedGroupId: UUID?
    
    @Published var isAddingGroup = false
    @Published var editingGroup: InstanceGroup?
    @Published var groupName = ""
    @Published var groupIcon = "server.rack"
    @Published var groupColor = "blue"
    
    @Published var isTesting = false
    @Published var testResult: ConnectionTestResult?
    
    @Published var validationError: String?
    @Published var isLoadingCredentials = false
    
    private weak var instanceManager: InstanceManager?
    
    init(instanceManager: InstanceManager? = nil) {
        self.instanceManager = instanceManager
    }
    
    func setInstanceManager(_ manager: InstanceManager) {
        self.instanceManager = manager
    }
    
    var isQBittorrent: Bool {
        instanceType == .qbittorrent
    }
    
    var isEditing: Bool {
        editingInstance != nil
    }
    
    var formTitle: String {
        isEditing ? "Modifier l'instance" : "Ajouter une instance"
    }
    
    // Optimisation: simplification de la validation pour éviter les recalculs coûteux
    var isFormValid: Bool {
        let nameValid = !instanceName.isEmpty
        let urlValid = !instanceURL.isEmpty && (instanceURL.hasPrefix("http://") || instanceURL.hasPrefix("https://"))
        
        guard nameValid && urlValid else { return false }
        
        if isQBittorrent {
            return !username.isEmpty && !password.isEmpty
        } else {
            return !apiKey.isEmpty
        }
    }
    
    func resetForm() {
        instanceName = ""
        instanceURL = ""
        instanceType = .radarr
        apiKey = ""
        username = ""
        password = ""
        selectedGroupId = nil
        testResult = nil
        validationError = nil
        editingInstance = nil
        isLoadingCredentials = false
    }
    
    func resetGroupForm() {
        groupName = ""
        groupIcon = "server.rack"
        groupColor = "blue"
        editingGroup = nil
    }
    
    func prepareForEditingGroup(_ group: InstanceGroup) {
        editingGroup = group
        groupName = group.name
        groupIcon = group.icon
        groupColor = group.colorName
    }
    
    var isEditingGroup: Bool {
        editingGroup != nil
    }
    
    var groupFormTitle: String {
        isEditingGroup ? "Modifier le groupe" : "Nouveau groupe"
    }
    
    var isGroupFormValid: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func saveGroup() {
        guard isGroupFormValid, let instanceManager = instanceManager else { return }
        
        if let existing = editingGroup {
            let updated = InstanceGroup(
                id: existing.id,
                name: groupName,
                icon: groupIcon,
                colorName: groupColor,
                order: existing.order
            )
            instanceManager.updateGroup(updated)
        } else {
            let newGroup = InstanceGroup(
                name: groupName,
                icon: groupIcon,
                colorName: groupColor
            )
            instanceManager.addGroup(newGroup)
        }
        
        resetGroupForm()
        isAddingGroup = false
    }
    
    func prepareForEditing(_ instance: ServiceInstance) {
        editingInstance = instance
        instanceName = instance.name
        instanceURL = instance.baseURL
        instanceType = instance.serviceType
        selectedGroupId = instance.groupId
        testResult = nil
        validationError = nil
        
        // Charger les credentials de manière asynchrone pour ne pas bloquer l'UI
        isLoadingCredentials = true
        
        Task.detached(priority: .userInitiated) { [weak self] in
            let keychain = KeychainManager.shared
            let instanceId = instance.id
            let serviceType = instance.serviceType
            
            if serviceType == .qbittorrent {
                let credentials = keychain.getCredentials(for: instanceId)
                await MainActor.run {
                    self?.username = credentials?.username ?? ""
                    self?.password = credentials?.password ?? ""
                    self?.isLoadingCredentials = false
                }
            } else {
                let key = keychain.getAPIKey(for: instanceId)
                await MainActor.run {
                    self?.apiKey = key ?? ""
                    self?.isLoadingCredentials = false
                }
            }
        }
    }
    
    func validateForm() -> Bool {
        validationError = nil
        
        if instanceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Le nom de l'instance est requis"
            return false
        }
        
        if instanceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "L'URL est requise"
            return false
        }
        
        if !instanceURL.hasPrefix("http://") && !instanceURL.hasPrefix("https://") {
            validationError = "L'URL doit commencer par http:// ou https://"
            return false
        }
        
        if isQBittorrent {
            if username.isEmpty {
                validationError = "Le nom d'utilisateur est requis"
                return false
            }
            if password.isEmpty {
                validationError = "Le mot de passe est requis"
                return false
            }
        } else {
            if apiKey.isEmpty {
                validationError = "La clé API est requise"
                return false
            }
        }
        
        return true
    }
    
    func testConnection() async {
        guard validateForm() else { return }
        
        isTesting = true
        testResult = nil
        
        let result: ConnectionTestResult
        
        switch instanceType {
        case .radarr:
            let service = RadarrService(baseURL: instanceURL, apiKey: apiKey)
            result = await (try? service.testConnection()) ?? ConnectionTestResult(success: false, message: "Erreur de connexion", responseTime: nil)
            
        case .sonarr:
            let service = SonarrService(baseURL: instanceURL, apiKey: apiKey)
            result = await (try? service.testConnection()) ?? ConnectionTestResult(success: false, message: "Erreur de connexion", responseTime: nil)
            
        case .qbittorrent:
            let service = QBittorrentService(baseURL: instanceURL, username: username, password: password)
            result = await (try? service.testConnection()) ?? ConnectionTestResult(success: false, message: "Erreur de connexion", responseTime: nil)
            
        case .overseerr:
            let service = OverseerrService(baseURL: instanceURL, apiKey: apiKey)
            result = await (try? service.testConnection()) ?? ConnectionTestResult(success: false, message: "Erreur de connexion", responseTime: nil)
        }
        
        testResult = result
        isTesting = false
    }
    
    func saveInstance() {
        guard validateForm(), let instanceManager = instanceManager else { return }
        
        if let existing = editingInstance {
            let updated = ServiceInstance(
                id: existing.id,
                name: instanceName,
                baseURL: instanceURL,
                serviceType: instanceType,
                isEnabled: existing.isEnabled,
                groupId: selectedGroupId
            )
            
            if isQBittorrent {
                instanceManager.updateInstance(updated, username: username, password: password)
            } else {
                instanceManager.updateInstance(updated, apiKey: apiKey)
            }
        } else {
            let newInstance = ServiceInstance(
                name: instanceName,
                baseURL: instanceURL,
                serviceType: instanceType,
                groupId: selectedGroupId
            )
            
            if isQBittorrent {
                instanceManager.addInstance(newInstance, username: username, password: password)
            } else {
                instanceManager.addInstance(newInstance, apiKey: apiKey)
            }
        }
        
        resetForm()
        isAddingInstance = false
    }
    
    func deleteInstance(_ instance: ServiceInstance) {
        instanceManager?.deleteInstance(instance)
    }
}
