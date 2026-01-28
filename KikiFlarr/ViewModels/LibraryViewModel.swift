import Foundation
import SwiftUI

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var moviesState: LoadableState<[MovieWithInstance]> = .idle
    @Published var seriesState: LoadableState<[SeriesWithInstance]> = .idle
    @Published var isRefreshing = false
    @Published var selectedTab: LibraryTab = .movies

    var moviesCount: Int {
        moviesState.data?.count ?? 0
    }

    var seriesCount: Int {
        seriesState.data?.count ?? 0
    }
    
    enum LibraryTab {
        case movies
        case series
        case calendar
    }
    
    struct MovieWithInstance: Identifiable, Equatable {
        let movie: RadarrMovie
        let instance: ServiceInstance
        
        var id: String { "\(instance.id)-\(movie.id)" }
        
        static func == (lhs: MovieWithInstance, rhs: MovieWithInstance) -> Bool {
            lhs.movie.id == rhs.movie.id && lhs.movie.hasFile == rhs.movie.hasFile
        }
    }
    
    struct SeriesWithInstance: Identifiable, Equatable {
        let series: SonarrSeries
        let instance: ServiceInstance
        
        var id: String { "\(instance.id)-\(series.id)" }
        
        static func == (lhs: SeriesWithInstance, rhs: SeriesWithInstance) -> Bool {
            lhs.series.id == rhs.series.id &&
            lhs.series.statistics?.episodeFileCount == rhs.series.statistics?.episodeFileCount
        }
    }
    
    private weak var instanceManager: InstanceManager?
    
    init(instanceManager: InstanceManager? = nil) {
        self.instanceManager = instanceManager
    }
    
    func setInstanceManager(_ manager: InstanceManager) {
        self.instanceManager = manager
    }
    
    func loadAll() async {
        async let moviesTask: () = loadMovies()
        async let seriesTask: () = loadSeries()
        _ = await (moviesTask, seriesTask)
    }
    
    func refresh() async {
        isRefreshing = true
        
        await ResponseCache.shared.removeAll()
        await loadAll()
        
        isRefreshing = false
    }
    
    func loadMovies() async {
        guard let instanceManager = instanceManager else {
            moviesState = .failed(AppError(
                title: "Configuration manquante",
                message: "Gestionnaire d'instances non initialisé",
                recoverySuggestion: "Veuillez redémarrer l'application"
            ))
            return
        }

        // Afficher le loading seulement si on n'a pas encore de données
        if moviesState.data == nil {
            moviesState = .loading
        }

        var allMovies: [MovieWithInstance] = []

        await withTaskGroup(of: [MovieWithInstance].self) { group in
            for instance in instanceManager.radarrInstances {
                guard let service = instanceManager.radarrService(for: instance) else { continue }

                group.addTask {
                    do {
                        let movies = try await service.getMovies()
                        return movies.map { MovieWithInstance(movie: $0, instance: instance) }
                    } catch {
                        return []
                    }
                }
            }

            for await result in group {
                allMovies.append(contentsOf: result)
            }
        }

        let sortedMovies = allMovies.sorted { ($0.movie.added ?? "") > ($1.movie.added ?? "") }

        if sortedMovies.isEmpty {
            moviesState = .empty
        } else {
            moviesState = .loaded(sortedMovies)
        }
    }
    
    func loadSeries() async {
        guard let instanceManager = instanceManager else {
            seriesState = .failed(AppError(
                title: "Configuration manquante",
                message: "Gestionnaire d'instances non initialisé",
                recoverySuggestion: "Veuillez redémarrer l'application"
            ))
            return
        }

        // Afficher le loading seulement si on n'a pas encore de données
        if seriesState.data == nil {
            seriesState = .loading
        }

        var allSeries: [SeriesWithInstance] = []

        await withTaskGroup(of: [SeriesWithInstance].self) { group in
            for instance in instanceManager.sonarrInstances {
                guard let service = instanceManager.sonarrService(for: instance) else { continue }

                group.addTask {
                    do {
                        let series = try await service.getSeries()
                        return series.map { SeriesWithInstance(series: $0, instance: instance) }
                    } catch {
                        return []
                    }
                }
            }

            for await result in group {
                allSeries.append(contentsOf: result)
            }
        }

        let sortedSeries = allSeries.sorted { ($0.series.added ?? "") > ($1.series.added ?? "") }

        if sortedSeries.isEmpty {
            seriesState = .empty
        } else {
            seriesState = .loaded(sortedSeries)
        }
    }
    
    var availableMoviesCount: Int {
        moviesState.data?.filter { $0.movie.hasFile == true }.count ?? 0
    }

    var availableSeriesCount: Int {
        seriesState.data?.filter { ($0.series.statistics?.percentOfEpisodes ?? 0) >= 100 }.count ?? 0
    }
}
