import Foundation
import SwiftUI

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var radarrMovies: [MovieWithInstance] = []
    @Published var sonarrSeries: [SeriesWithInstance] = []
    @Published var isLoadingMovies = false
    @Published var isLoadingSeries = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var selectedTab: LibraryTab = .movies
    
    @Published private(set) var moviesCount: Int = 0
    @Published private(set) var seriesCount: Int = 0
    
    enum LibraryTab {
        case movies
        case series
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
        guard let instanceManager = instanceManager else { return }
        
        let isInitialLoad = radarrMovies.isEmpty
        if isInitialLoad {
            isLoadingMovies = true
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
        
        if !allMovies.isEmpty || isInitialLoad {
            radarrMovies = allMovies.sorted { ($0.movie.added ?? "") > ($1.movie.added ?? "") }
            moviesCount = radarrMovies.count
        }
        isLoadingMovies = false
    }
    
    func loadSeries() async {
        guard let instanceManager = instanceManager else { return }
        
        let isInitialLoad = sonarrSeries.isEmpty
        if isInitialLoad {
            isLoadingSeries = true
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
        
        if !allSeries.isEmpty || isInitialLoad {
            sonarrSeries = allSeries.sorted { ($0.series.added ?? "") > ($1.series.added ?? "") }
            seriesCount = sonarrSeries.count
        }
        isLoadingSeries = false
    }
    
    var availableMoviesCount: Int {
        radarrMovies.filter { $0.movie.hasFile == true }.count
    }
    
    var availableSeriesCount: Int {
        sonarrSeries.filter { ($0.series.statistics?.percentOfEpisodes ?? 0) >= 100 }.count
    }
}
