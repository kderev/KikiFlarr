import Foundation
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery = "" {
        didSet { debounceSearch() }
    }
    @Published var state: LoadableState<[OverseerrSearchResult]> = .idle
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
            state = .idle
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
            state = .idle
            hasSearched = false
            return
        }

        searchTask = Task { [weak self] in
            await self?.performSearch()
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        state = .idle
        hasSearched = false
        debounceTask?.cancel()
        searchTask?.cancel()
    }
    
    private func performSearch() async {
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            state = .failed(AppError(
                title: "Configuration manquante",
                message: "Aucune instance Overseerr configurée",
                recoverySuggestion: "Veuillez configurer une instance Overseerr dans les paramètres"
            ))
            return
        }

        let query = searchQuery

        print("🔍 Recherche pour: '\(query)'")

        state = .loading
        hasSearched = true

        do {
            let results = try await service.search(query: query)
            print("✅ Résultats de recherche reçus: \(results.results.count) éléments")

            guard !Task.isCancelled, searchQuery == query else { return }

            let filteredResults = results.results.filter { result in
                result.mediaType == .movie || result.mediaType == .tv
            }

            if filteredResults.isEmpty {
                state = .empty
            } else {
                state = .loaded(filteredResults)
            }
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(AppError.from(error))
        }
    }
    
    func loadTrending() async {
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            state = .failed(AppError(
                title: "Configuration manquante",
                message: "Aucune instance Overseerr configurée",
                recoverySuggestion: "Veuillez configurer une instance Overseerr dans les paramètres"
            ))
            return
        }

        state = .loading

        do {
            let results = try await service.trendingMovies()
            if results.results.isEmpty {
                state = .empty
            } else {
                state = .loaded(results.results)
            }
        } catch {
            state = .failed(AppError.from(error))
        }
    }
}
