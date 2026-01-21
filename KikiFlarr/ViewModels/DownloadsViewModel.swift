import Foundation
import SwiftUI

@MainActor
class DownloadsViewModel: ObservableObject {
    @Published var state: LoadableState<[TorrentWithInstance]> = .idle
    @Published var selectedFilter: TorrentFilter = .all

    @Published private(set) var totalDownloadSpeed: Int64 = 0
    @Published private(set) var totalUploadSpeed: Int64 = 0
    @Published private(set) var downloadingCount: Int = 0
    @Published private(set) var seedingCount: Int = 0
    @Published private(set) var pausedCount: Int = 0

    private weak var instanceManager: InstanceManager?
    private var refreshTask: Task<Void, Never>?

    // Tracking des états précédents pour détecter les téléchargements terminés
    private var previousTorrentStates: [String: String] = [:]
    
    struct TorrentWithInstance: Identifiable, Equatable {
        let torrent: QBittorrentTorrent
        let instance: ServiceInstance
        
        var id: String { "\(instance.id)-\(torrent.hash)" }
        
        static func == (lhs: TorrentWithInstance, rhs: TorrentWithInstance) -> Bool {
            lhs.torrent.hash == rhs.torrent.hash &&
            lhs.torrent.progress == rhs.torrent.progress &&
            lhs.torrent.state == rhs.torrent.state
        }
    }
    
    init(instanceManager: InstanceManager? = nil) {
        self.instanceManager = instanceManager
    }
    
    func setInstanceManager(_ manager: InstanceManager) {
        self.instanceManager = manager
    }
    
    func loadTorrents() async {
        guard let instanceManager = instanceManager else {
            state = .failed(AppError(
                title: "Configuration manquante",
                message: "Gestionnaire d'instances non initialisé",
                recoverySuggestion: "Veuillez redémarrer l'application"
            ))
            return
        }

        // Afficher le loading seulement si on n'a pas encore de données
        if state.data == nil {
            state = .loading
        }

        var allTorrents: [TorrentWithInstance] = []

        await withTaskGroup(of: [TorrentWithInstance].self) { group in
            for instance in instanceManager.qbittorrentInstances {
                guard let service = instanceManager.qbittorrentService(for: instance) else { continue }

                group.addTask {
                    do {
                        let instanceTorrents = try await service.getTorrents(filter: self.selectedFilter)
                        return instanceTorrents.map { TorrentWithInstance(torrent: $0, instance: instance) }
                    } catch {
                        return []
                    }
                }
            }

            for await result in group {
                allTorrents.append(contentsOf: result)
            }
        }

        let sortedTorrents = allTorrents.sorted { ($0.torrent.addedOn ?? 0) > ($1.torrent.addedOn ?? 0) }

        // Vérifier les téléchargements terminés et envoyer des notifications
        await checkForCompletedDownloads(sortedTorrents)

        if sortedTorrents.isEmpty {
            state = .empty
        } else {
            state = .loaded(sortedTorrents)
        }

        updateStatistics()
    }
    
    private func updateStatistics() {
        guard let torrents = state.data else {
            totalDownloadSpeed = 0
            totalUploadSpeed = 0
            downloadingCount = 0
            seedingCount = 0
            pausedCount = 0
            return
        }

        var dlSpeed: Int64 = 0
        var ulSpeed: Int64 = 0
        var downloading = 0
        var seeding = 0
        var paused = 0

        for item in torrents {
            dlSpeed += item.torrent.dlspeed
            ulSpeed += item.torrent.upspeed

            if item.torrent.isDownloading { downloading += 1 }
            if item.torrent.isUploading { seeding += 1 }
            if item.torrent.isPaused { paused += 1 }
        }

        totalDownloadSpeed = dlSpeed
        totalUploadSpeed = ulSpeed
        downloadingCount = downloading
        seedingCount = seeding
        pausedCount = paused
    }
    
    func startAutoRefresh(interval: TimeInterval = 5) {
        stopAutoRefresh()
        
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                await self.loadTorrents()
                
                guard !Task.isCancelled else { break }
                
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch {
                    break
                }
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    func pauseTorrent(_ torrentWithInstance: TorrentWithInstance) async {
        guard let instanceManager = instanceManager,
              let service = instanceManager.qbittorrentService(for: torrentWithInstance.instance) else { return }

        do {
            try await service.pauseTorrents(hashes: [torrentWithInstance.torrent.hash])
            await loadTorrents()
        } catch {
            // L'erreur sera gérée lors du prochain loadTorrents
            print("Error pausing torrent: \(error.localizedDescription)")
        }
    }
    
    func resumeTorrent(_ torrentWithInstance: TorrentWithInstance) async {
        guard let instanceManager = instanceManager,
              let service = instanceManager.qbittorrentService(for: torrentWithInstance.instance) else { return }

        do {
            try await service.resumeTorrents(hashes: [torrentWithInstance.torrent.hash])
            await loadTorrents()
        } catch {
            // L'erreur sera gérée lors du prochain loadTorrents
            print("Error resuming torrent: \(error.localizedDescription)")
        }
    }
    
    func deleteTorrent(_ torrentWithInstance: TorrentWithInstance, deleteFiles: Bool = false) async {
        guard let instanceManager = instanceManager,
              let service = instanceManager.qbittorrentService(for: torrentWithInstance.instance) else { return }

        do {
            try await service.deleteTorrents(hashes: [torrentWithInstance.torrent.hash], deleteFiles: deleteFiles)
            await loadTorrents()
        } catch {
            // L'erreur sera gérée lors du prochain loadTorrents
            print("Error deleting torrent: \(error.localizedDescription)")
        }
    }

    // MARK: - Notifications de téléchargement terminé

    private func checkForCompletedDownloads(_ torrents: [TorrentWithInstance]) async {
        // États qui indiquent un téléchargement en cours
        let downloadingStates = Set(["downloading", "forcedDL", "metaDL", "stalledDL", "queuedDL", "checkingDL", "allocating"])
        // États qui indiquent un téléchargement terminé (en seed)
        let completedStates = Set(["uploading", "forcedUP", "stalledUP", "queuedUP", "checkingUP", "pausedUP", "stoppedUP"])

        for torrentWithInstance in torrents {
            let torrent = torrentWithInstance.torrent
            let key = "\(torrentWithInstance.instance.id)-\(torrent.hash)"
            let currentState = torrent.state
            let previousState = previousTorrentStates[key]

            // Vérifier si le torrent vient de passer de downloading à completed
            if let prevState = previousState,
               downloadingStates.contains(prevState),
               completedStates.contains(currentState) {
                // Le téléchargement vient de se terminer
                await NotificationService.shared.notifyDownloadCompleted(
                    torrentName: torrent.name,
                    torrentHash: torrent.hash,
                    instanceId: torrentWithInstance.instance.id.uuidString,
                    instanceName: torrentWithInstance.instance.name
                )
            }

            // Mettre à jour l'état précédent
            previousTorrentStates[key] = currentState
        }

        // Nettoyer les entrées pour les torrents supprimés (limiter la mémoire)
        let currentKeys = Set(torrents.map { "\($0.instance.id)-\($0.torrent.hash)" })
        previousTorrentStates = previousTorrentStates.filter { currentKeys.contains($0.key) }
    }
}
