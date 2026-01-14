import Foundation
import Security

enum KeychainError: LocalizedError {
    case duplicateItem
    case itemNotFound
    case unexpectedStatus(OSStatus)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "L'élément existe déjà dans le Keychain"
        case .itemNotFound:
            return "Élément non trouvé dans le Keychain"
        case .unexpectedStatus(let status):
            return "Erreur Keychain inattendue: \(status)"
        case .invalidData:
            return "Données invalides"
        }
    }
}

final class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.mediahub.app"
    
    private init() {}
    
    func save(key: String, value: String, instanceId: UUID) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let account = "\(instanceId.uuidString)-\(key)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try update(key: key, value: value, instanceId: instanceId)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func update(key: String, value: String, instanceId: UUID) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let account = "\(instanceId.uuidString)-\(key)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status == errSecItemNotFound {
            try save(key: key, value: value, instanceId: instanceId)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func retrieve(key: String, instanceId: UUID) throws -> String {
        let account = "\(instanceId.uuidString)-\(key)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return value
    }
    
    func delete(key: String, instanceId: UUID) throws {
        let account = "\(instanceId.uuidString)-\(key)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func deleteAll(for instanceId: UUID) {
        let prefixes = ["apiKey", "username", "password"]
        for prefix in prefixes {
            try? delete(key: prefix, instanceId: instanceId)
        }
    }
}

extension KeychainManager {
    func saveAPIKey(_ apiKey: String, for instanceId: UUID) throws {
        try save(key: "apiKey", value: apiKey, instanceId: instanceId)
    }
    
    func getAPIKey(for instanceId: UUID) -> String? {
        try? retrieve(key: "apiKey", instanceId: instanceId)
    }
    
    func saveCredentials(username: String, password: String, for instanceId: UUID) throws {
        try save(key: "username", value: username, instanceId: instanceId)
        try save(key: "password", value: password, instanceId: instanceId)
    }
    
    func getCredentials(for instanceId: UUID) -> (username: String, password: String)? {
        guard let username = try? retrieve(key: "username", instanceId: instanceId),
              let password = try? retrieve(key: "password", instanceId: instanceId) else {
            return nil
        }
        return (username, password)
    }
    
    // MARK: - TMDB API Key (Global)
    
    private var tmdbAccountKey: String { "tmdb-global-apikey" }
    
    func saveTMDBApiKey(_ apiKey: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tmdbAccountKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: tmdbAccountKey
            ]
            let attributes: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
            if updateStatus != errSecSuccess {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func getTMDBApiKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tmdbAccountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func deleteTMDBApiKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tmdbAccountKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}
