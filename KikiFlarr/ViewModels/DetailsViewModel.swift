import Foundation
import SwiftUI

@MainActor
class DetailsViewModel: ObservableObject {
    @Published var movieDetails: OverseerrMovieDetails?
    @Published var tvDetails: OverseerrTVDetails?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var radarrProfiles: [RadarrQualityProfile] = []
    @Published var radarrRootFolders: [RadarrRootFolder] = []
    @Published var sonarrProfiles: [SonarrQualityProfile] = []
    @Published var sonarrRootFolders: [SonarrRootFolder] = []
    
    @Published var selectedRadarrInstance: ServiceInstance?
    @Published var selectedSonarrInstance: ServiceInstance?
    @Published var selectedQualityProfileId: Int?
    @Published var selectedRootFolderId: Int?
    
    @Published var isAdding = false
    @Published var addSuccess = false
    @Published var addErrorMessage: String?
    
    @Published var selectedSeasons: Set<Int> = []
    
    @Published var isRequestingOverseerr = false
    @Published var overseerrRequestSuccess = false
    
    // Overseerr options
    @Published var overseerrRadarrServers: [OverseerrRadarrServer] = []
    @Published var overseerrSonarrServers: [OverseerrSonarrServer] = []
    @Published var selectedOverseerrServer: Int?
    @Published var overseerrProfiles: [OverseerrQualityProfile] = []
    @Published var overseerrRootFolders: [OverseerrRootFolderOption] = []
    @Published var selectedOverseerrProfileId: Int?
    @Published var selectedOverseerrRootFolder: String?
    @Published var is4K = false
    
    private weak var instanceManager: InstanceManager?
    let searchResult: OverseerrSearchResult
    
    init(searchResult: OverseerrSearchResult, instanceManager: InstanceManager? = nil) {
        self.searchResult = searchResult
        self.instanceManager = instanceManager
    }
    
    func setInstanceManager(_ manager: InstanceManager) {
        self.instanceManager = manager
    }
    
    var isMovie: Bool {
        searchResult.resolvedMediaType == .movie
    }
    
    var isTVShow: Bool {
        searchResult.resolvedMediaType == .tv
    }
    
    var isAlreadyAvailable: Bool {
        searchResult.mediaInfo?.isAvailable ?? false
    }
    
    var isRequested: Bool {
        searchResult.mediaInfo?.isRequested ?? false
    }
    
    // MARK: - Load Details
    
    func loadDetails() async {
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            // Pas d'erreur affichée - on utilise simplement les données de searchResult
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if isMovie {
                movieDetails = try await service.getMovieDetails(tmdbId: searchResult.id)
            } else {
                tvDetails = try await service.getTVDetails(tmdbId: searchResult.id)
                if let seasons = tvDetails?.seasons {
                    selectedSeasons = Set(seasons.filter { $0.seasonNumber > 0 }.map { $0.seasonNumber })
                }
            }
            
            await loadArrOptions()
            await loadOverseerrOptions()
        } catch {
            // On ne montre l'erreur que si c'est une erreur réseau critique
            // Les erreurs de décodage sont silencieuses car on a les données de base
            if case NetworkError.decodingError(_) = error {
                // Silencieux - on utilise les données du searchResult
                print("Erreur de décodage ignorée: \(error.localizedDescription)")
            } else if case NetworkError.notFound = error {
                // Film pas trouvé dans la base Overseerr - pas grave
                print("Media non trouvé dans Overseerr")
            } else {
                errorMessage = error.localizedDescription
            }
            
            // Charger quand même les options Radarr/Sonarr
            await loadArrOptions()
            await loadOverseerrOptions()
        }
        
        isLoading = false
    }
    
    func loadOverseerrOptions() async {
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            return
        }
        
        do {
            if isMovie {
                let servers = try await service.getRadarrServers()
                overseerrRadarrServers = servers
                if let defaultServer = servers.first(where: { $0.isDefault == true }) ?? servers.first {
                    selectedOverseerrServer = defaultServer.id
                    await loadOverseerrServerProfiles(serverId: defaultServer.id, isMovie: true)
                }
            } else {
                let servers = try await service.getSonarrServers()
                overseerrSonarrServers = servers
                if let defaultServer = servers.first(where: { $0.isDefault == true }) ?? servers.first {
                    selectedOverseerrServer = defaultServer.id
                    await loadOverseerrServerProfiles(serverId: defaultServer.id, isMovie: false)
                }
            }
        } catch {
            // Silently fail - options are optional
        }
    }
    
    func loadOverseerrServerProfiles(serverId: Int, isMovie: Bool) async {
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            return
        }
        
        do {
            let settings: OverseerrServiceSettings
            if isMovie {
                settings = try await service.getRadarrProfiles(serverId: serverId)
            } else {
                settings = try await service.getSonarrProfiles(serverId: serverId)
            }
            
            overseerrProfiles = settings.profiles ?? []
            overseerrRootFolders = settings.rootFolders ?? []
            
            if selectedOverseerrProfileId == nil {
                selectedOverseerrProfileId = overseerrProfiles.first?.id
            }
            if selectedOverseerrRootFolder == nil {
                selectedOverseerrRootFolder = overseerrRootFolders.first?.path
            }
        } catch {
            // Silently fail
        }
    }
    
    private func loadArrOptions() async {
        guard let instanceManager = instanceManager else { return }
        
        if isMovie {
            if selectedRadarrInstance == nil {
                selectedRadarrInstance = instanceManager.radarrInstances.first
            }
            await loadRadarrOptions()
        } else {
            if selectedSonarrInstance == nil {
                selectedSonarrInstance = instanceManager.sonarrInstances.first
            }
            await loadSonarrOptions()
        }
    }
    
    func loadRadarrOptions() async {
        guard let instanceManager = instanceManager,
              let radarrInstance = selectedRadarrInstance,
              let service = instanceManager.radarrService(for: radarrInstance) else {
            return
        }
        
        do {
            async let profilesTask = service.getQualityProfiles()
            async let foldersTask = service.getRootFolders()
            
            let (profiles, folders) = try await (profilesTask, foldersTask)
            
            radarrProfiles = profiles
            radarrRootFolders = folders
            
            if selectedQualityProfileId == nil {
                selectedQualityProfileId = profiles.first?.id
            }
            if selectedRootFolderId == nil {
                selectedRootFolderId = folders.first?.id
            }
        } catch {
            addErrorMessage = "Erreur lors du chargement des options Radarr"
        }
    }
    
    func loadSonarrOptions() async {
        guard let instanceManager = instanceManager,
              let sonarrInstance = selectedSonarrInstance,
              let service = instanceManager.sonarrService(for: sonarrInstance) else {
            return
        }
        
        do {
            async let profilesTask = service.getQualityProfiles()
            async let foldersTask = service.getRootFolders()
            
            let (profiles, folders) = try await (profilesTask, foldersTask)
            
            sonarrProfiles = profiles
            sonarrRootFolders = folders
            
            if selectedQualityProfileId == nil {
                selectedQualityProfileId = profiles.first?.id
            }
            if selectedRootFolderId == nil {
                selectedRootFolderId = folders.first?.id
            }
        } catch {
            addErrorMessage = "Erreur lors du chargement des options Sonarr"
        }
    }
    
    // MARK: - Add to Arr
    
    func addToRadarr() async {
        guard let instanceManager = instanceManager,
              let radarrInstance = selectedRadarrInstance,
              let service = instanceManager.radarrService(for: radarrInstance),
              let profileId = selectedQualityProfileId,
              let rootFolder = radarrRootFolders.first(where: { $0.id == selectedRootFolderId }) else {
            addErrorMessage = "Configuration incomplète"
            return
        }
        
        isAdding = true
        addErrorMessage = nil
        addSuccess = false
        
        let title = movieDetails?.title ?? searchResult.displayTitle
        let year = Int(movieDetails?.displayYear ?? searchResult.displayYear) ?? 0
        
        let request = RadarrAddMovieRequest(
            title: title,
            qualityProfileId: profileId,
            tmdbId: searchResult.id,
            year: year,
            rootFolderPath: rootFolder.path,
            monitored: true,
            minimumAvailability: "announced",
            addOptions: RadarrAddMovieRequest.RadarrAddOptions(searchForMovie: true)
        )
        
        do {
            _ = try await service.addMovie(request)
            addSuccess = true
        } catch {
            addErrorMessage = error.localizedDescription
        }
        
        isAdding = false
    }
    
    func addToSonarr() async {
        guard let instanceManager = instanceManager,
              let sonarrInstance = selectedSonarrInstance,
              let service = instanceManager.sonarrService(for: sonarrInstance),
              let profileId = selectedQualityProfileId,
              let rootFolder = sonarrRootFolders.first(where: { $0.id == selectedRootFolderId }),
              let tvDetails = tvDetails,
              let tvdbId = tvDetails.externalIds?.tvdbId else {
            addErrorMessage = "Configuration incomplète ou TVDB ID manquant"
            return
        }
        
        isAdding = true
        addErrorMessage = nil
        addSuccess = false
        
        let title = tvDetails.name ?? searchResult.displayTitle
        let titleSlug = title.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
        
        let seasons = (tvDetails.seasons ?? []).map { season in
            SonarrAddSeriesRequest.SonarrAddSeason(
                seasonNumber: season.seasonNumber,
                monitored: selectedSeasons.contains(season.seasonNumber)
            )
        }
        
        let images = (tvDetails.seasons ?? []).compactMap { season -> SonarrImage? in
            guard let posterPath = season.posterPath else { return nil }
            return SonarrImage(coverType: "poster", url: nil, remoteUrl: "https://image.tmdb.org/t/p/w500\(posterPath)")
        }
        
        let request = SonarrAddSeriesRequest(
            title: title,
            qualityProfileId: profileId,
            languageProfileId: 1,
            tvdbId: tvdbId,
            titleSlug: titleSlug,
            images: images,
            seasons: seasons,
            rootFolderPath: rootFolder.path,
            monitored: true,
            seasonFolder: true,
            seriesType: "standard",
            addOptions: SonarrAddSeriesRequest.SonarrAddOptions(
                ignoreEpisodesWithFiles: false,
                ignoreEpisodesWithoutFiles: false,
                searchForMissingEpisodes: true
            )
        )
        
        do {
            _ = try await service.addSeries(request)
            addSuccess = true
        } catch {
            addErrorMessage = error.localizedDescription
        }
        
        isAdding = false
    }
    
    func toggleSeason(_ seasonNumber: Int) {
        if selectedSeasons.contains(seasonNumber) {
            selectedSeasons.remove(seasonNumber)
        } else {
            selectedSeasons.insert(seasonNumber)
        }
    }
    
    func selectAllSeasons() {
        guard let seasons = tvDetails?.seasons else { return }
        selectedSeasons = Set(seasons.filter { $0.seasonNumber > 0 }.map { $0.seasonNumber })
    }
    
    func deselectAllSeasons() {
        selectedSeasons.removeAll()
    }
    
    // MARK: - Overseerr Request
    
    func requestViaOverseerr() async {
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            addErrorMessage = "Aucune instance Overseerr configurée"
            return
        }
        
        isRequestingOverseerr = true
        addErrorMessage = nil
        overseerrRequestSuccess = false
        
        do {
            if isMovie {
                _ = try await service.createRequestWithOptions(
                    mediaType: .movie,
                    mediaId: searchResult.id,
                    is4k: is4K,
                    serverId: selectedOverseerrServer,
                    profileId: selectedOverseerrProfileId,
                    rootFolder: selectedOverseerrRootFolder
                )
            } else {
                let seasons = Array(selectedSeasons)
                _ = try await service.createRequestWithOptions(
                    mediaType: .tv,
                    mediaId: searchResult.id,
                    is4k: is4K,
                    serverId: selectedOverseerrServer,
                    profileId: selectedOverseerrProfileId,
                    rootFolder: selectedOverseerrRootFolder,
                    seasons: seasons.isEmpty ? nil : seasons
                )
            }
            overseerrRequestSuccess = true
        } catch {
            addErrorMessage = error.localizedDescription
        }
        
        isRequestingOverseerr = false
    }
    
    var canRequestOverseerr: Bool {
        guard let instanceManager = instanceManager else { return false }
        return instanceManager.primaryOverseerr != nil
    }
}
