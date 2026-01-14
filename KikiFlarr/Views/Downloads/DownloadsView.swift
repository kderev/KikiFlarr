import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = DownloadsViewModel()
    @State private var showDeleteConfirmation = false
    @State private var torrentToDelete: DownloadsViewModel.TorrentWithInstance?
    
    var body: some View {
        NavigationStack {
            Group {
                if instanceManager.qbittorrentInstances.isEmpty {
                    noInstancesView
                } else if viewModel.isLoading && viewModel.torrents.isEmpty {
                    ProgressView("Chargement...")
                } else if viewModel.torrents.isEmpty {
                    emptyView
                } else {
                    torrentsList
                }
            }
            .navigationTitle("Téléchargements")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filtre", selection: $viewModel.selectedFilter) {
                            Text("Tous").tag(TorrentFilter.all)
                            Text("En cours").tag(TorrentFilter.downloading)
                            Text("En seed").tag(TorrentFilter.seeding)
                            Text("Terminés").tag(TorrentFilter.completed)
                            Text("En pause").tag(TorrentFilter.paused)
                            Text("Erreur").tag(TorrentFilter.errored)
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onAppear {
                viewModel.setInstanceManager(instanceManager)
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
            .onChange(of: viewModel.selectedFilter) { _, _ in
                Task {
                    await viewModel.loadTorrents()
                }
            }
            .refreshable {
                await viewModel.loadTorrents()
            }
            .confirmationDialog(
                "Supprimer le torrent",
                isPresented: $showDeleteConfirmation,
                presenting: torrentToDelete
            ) { torrent in
                Button("Supprimer le torrent uniquement", role: .destructive) {
                    Task {
                        await viewModel.deleteTorrent(torrent, deleteFiles: false)
                    }
                }
                Button("Supprimer avec les fichiers", role: .destructive) {
                    Task {
                        await viewModel.deleteTorrent(torrent, deleteFiles: true)
                    }
                }
                Button("Annuler", role: .cancel) {}
            } message: { torrent in
                Text(torrent.torrent.name)
            }
        }
    }
    
    private var noInstancesView: some View {
        ContentUnavailableView {
            Label("Aucune instance qBittorrent", systemImage: "externaldrive.badge.xmark")
        } description: {
            Text("Ajoutez une instance qBittorrent dans les paramètres pour voir vos téléchargements")
        }
    }
    
    private var emptyView: some View {
        ContentUnavailableView {
            Label("Aucun téléchargement", systemImage: "tray")
        } description: {
            Text("Les téléchargements en cours apparaîtront ici")
        }
    }
    
    private var torrentsList: some View {
        VStack(spacing: 0) {
            statsHeader
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.torrents) { torrentWithInstance in
                        TorrentCard(
                            torrent: torrentWithInstance.torrent,
                            instanceName: torrentWithInstance.instance.name,
                            onPause: {
                                Task {
                                    await viewModel.pauseTorrent(torrentWithInstance)
                                }
                            },
                            onResume: {
                                Task {
                                    await viewModel.resumeTorrent(torrentWithInstance)
                                }
                            },
                            onDelete: {
                                torrentToDelete = torrentWithInstance
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var statsHeader: some View {
        HStack(spacing: 20) {
            statItem(
                icon: "arrow.down.circle.fill",
                value: Formatters.formatSpeed(viewModel.totalDownloadSpeed),
                color: .blue
            )
            
            statItem(
                icon: "arrow.up.circle.fill",
                value: Formatters.formatSpeed(viewModel.totalUploadSpeed),
                color: .green
            )
            
            Spacer()
            
            HStack(spacing: 12) {
                miniStat(count: viewModel.downloadingCount, label: "DL", color: .blue)
                miniStat(count: viewModel.seedingCount, label: "UL", color: .green)
                miniStat(count: viewModel.pausedCount, label: "Pause", color: .gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func statItem(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private func miniStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DownloadsView()
        .environmentObject(InstanceManager())
}
