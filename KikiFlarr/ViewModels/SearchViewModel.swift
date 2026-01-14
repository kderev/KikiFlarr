import Foundation
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery = "" {
        didSet { debounceSearch() }
    }
    @Published var searchResults: [OverseerrSearchResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    private var searchTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private weak var instanceManager: InstanceManager?
    
    private let debounceDelay: UInt64 = 300_000_000 // 300ms
    
    init(instanceManager: InstanceManager? = nil) {
        self.instanceManager = instanceManager
    }
    
    func setInstanceManager(_ manager: InstanceManager) {
        self.instanceManager = manager
    }
    
    private func debounceSearch() {
        debounceTask?.cancel()
        
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            hasSearched = false
            return
        }
        
        debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: self?.debounceDelay ?? 300_000_000)
                await self?.performSearch()
            } catch {
                // Cancelled
            }
        }
    }
    
    func search() {
        debounceTask?.cancel()
        searchTask?.cancel()
        
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            hasSearched = false
            return
        }
        
        searchTask = Task { [weak self] in
            await self?.performSearch()
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        hasSearched = false
        errorMessage = nil
        debounceTask?.cancel()
        searchTask?.cancel()
    }
    
    private func performSearch() async {
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            errorMessage = "Aucune instance Overseerr configurée"
            return
        }
        
        let query = searchQuery
        
        isLoading = true
        errorMessage = nil
        hasSearched = true
        
        do {
            let results = try await service.search(query: query)
            
            guard !Task.isCancelled, searchQuery == query else { return }
            
            searchResults = results.results.filter { result in
                result.mediaType == .movie || result.mediaType == .tv
            }
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
            searchResults = []
        }
        
        isLoading = false
    }
    
    func loadTrending() async {
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let results = try await service.trendingMovies()
            searchResults = results.results
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
