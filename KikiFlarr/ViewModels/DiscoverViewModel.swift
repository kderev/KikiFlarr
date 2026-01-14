import Foundation
import SwiftUI

@MainActor
class DiscoverViewModel: ObservableObject {
    @Published var trendingMovies: [OverseerrSearchResult] = []
    @Published var trendingTV: [OverseerrSearchResult] = []
    @Published var recentRequests: [RequestWithMedia] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private weak var instanceManager: InstanceManager?
    private var loadTask: Task<Void, Never>?
    
    init(instanceManager: InstanceManager? = nil) {
        self.instanceManager = instanceManager
    }
    
    func setInstanceManager(_ manager: InstanceManager) {
        self.instanceManager = manager
    }
    
    func loadAll() async {
        loadTask?.cancel()
        
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            errorMessage = "Aucune instance Overseerr configurée"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        loadTask = Task {
            async let moviesTask = loadMovies(service: service)
            async let tvTask = loadTV(service: service)
            async let requestsTask = loadRequests(service: service)
            
            let (movies, tv, requests) = await (moviesTask, tvTask, requestsTask)
            
            guard !Task.isCancelled else { return }
            
            if let movies = movies {
                trendingMovies = Array(movies.results.prefix(20))
            }
            
            if let tv = tv {
                trendingTV = Array(tv.results.prefix(20))
            }
            
            recentRequests = requests
            
            if trendingMovies.isEmpty && trendingTV.isEmpty && errorMessage == nil {
                errorMessage = "Impossible de charger les données"
            } else {
                errorMessage = nil
            }
            
            isLoading = false
        }
        
        await loadTask?.value
    }
    
    private func loadMovies(service: OverseerrService) async -> OverseerrSearchResults? {
        do {
            return try await service.discoverMovies()
        } catch let error as NetworkError {
            if errorMessage == nil {
                errorMessage = error.localizedDescription
            }
            return nil
        } catch {
            return nil
        }
    }
    
    private func loadTV(service: OverseerrService) async -> OverseerrSearchResults? {
        do {
            return try await service.discoverTV()
        } catch {
            return nil
        }
    }
    
    private func loadRequests(service: OverseerrService) async -> [RequestWithMedia] {
        do {
            return try await service.getRequestsWithMedia(take: 10)
        } catch {
            return []
        }
    }
}
