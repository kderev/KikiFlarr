import Foundation

actor ResponseCache {
    static let shared = ResponseCache()
    
    private protocol CacheEntryProtocol {
        var isExpired: Bool { get }
    }

    private struct CacheEntry<T>: CacheEntryProtocol {
        let data: T
        let timestamp: Date
        let ttl: TimeInterval
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }
    
    private var cache: [String: CacheEntryProtocol] = [:]
    
    private init() {
        Task {
            await startCleanupTimer()
        }
    }
    
    func get<T>(_ key: String) -> T? {
        guard let entry = cache[key] as? CacheEntry<T> else { return nil }
        
        if entry.isExpired {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.data
    }
    
    func set<T>(_ key: String, value: T, ttl: TimeInterval = 60) {
        let entry = CacheEntry(data: value, timestamp: Date(), ttl: ttl)
        cache[key] = entry
    }
    
    func remove(_ key: String) {
        cache.removeValue(forKey: key)
    }
    
    func removeAll() {
        cache.removeAll()
    }
    
    func removeExpired() {
        for key in cache.keys {
            if let entry = cache[key], entry.isExpired {
                cache.removeValue(forKey: key)
            }
        }
    }
    
    private func startCleanupTimer() async {
        while true {
            try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
            removeExpired()
        }
    }
}

extension ResponseCache {
    static func moviesCacheKey(instanceID: UUID) -> String {
        "movies-\(instanceID.uuidString)"
    }
    
    static func seriesCacheKey(instanceID: UUID) -> String {
        "series-\(instanceID.uuidString)"
    }
    
    static func discoverMoviesCacheKey() -> String {
        "discover-movies"
    }
    
    static func discoverTVCacheKey() -> String {
        "discover-tv"
    }
    
    static func searchCacheKey(query: String) -> String {
        "search-\(query.lowercased())"
    }
}
