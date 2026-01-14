import SwiftUI

struct SeriesDetailView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @Environment(\.dismiss) private var dismiss
    let series: SonarrSeries
    let instance: ServiceInstance
    
    @State private var isSearching = false
    @State private var searchingSeason: Int?
    @State private var showDeleteConfirmation = false
    @State private var showInteractiveSearch = false
    @State private var interactiveSearchSeason: Int?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                
                VStack(alignment: .leading, spacing: 20) {
                    quickInfoSection
                    actionsSection
                    
                    if let overview = series.overview, !overview.isEmpty {
                        synopsisSection(overview: overview)
                    }
                    
                    if let seasons = series.seasons, !seasons.isEmpty {
                        seasonsSection(seasons: seasons)
                    }
                    
                    technicalSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(series.title)
                    .font(.headline)
                    .lineLimit(1)
            }
        }
        .sheet(isPresented: $showInteractiveSearch) {
            SeriesInteractiveSearchView(
                seriesId: series.id,
                seriesTitle: series.title,
                seasonNumber: interactiveSearchSeason,
                instance: instance
            )
        }
        .alert("Confirmer la suppression", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                Task {
                    await deleteSeries()
                }
            }
        } message: {
            Text("Voulez-vous supprimer \"\(series.title)\" de Sonarr ?")
        }
        .alert("Succès", isPresented: .init(
            get: { successMessage != nil },
            set: { if !$0 { successMessage = nil } }
        )) {
            Button("OK") { successMessage = nil }
        } message: {
            Text(successMessage ?? "")
        }
        .alert("Erreur", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Backdrop
                if let fanartURL = series.fanartURL {
                    AsyncImage(url: fanartURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 280)
                                .clipped()
                        case .failure(_):
                            backdropPlaceholder
                        case .empty:
                            backdropPlaceholder
                                .overlay(ProgressView())
                        @unknown default:
                            backdropPlaceholder
                        }
                    }
                } else {
                    backdropPlaceholder
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, Color(.systemBackground).opacity(0.5), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Poster + Title overlay
                HStack(alignment: .bottom, spacing: 16) {
                    // Poster
                    AsyncImage(url: series.posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            posterPlaceholder
                        case .empty:
                            posterPlaceholder
                                .overlay(ProgressView())
                        @unknown default:
                            posterPlaceholder
                        }
                    }
                    .frame(width: 110, height: 165)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Title & basic info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(series.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Text("\(series.year)")
                            
                            if let network = series.network, !network.isEmpty {
                                Text("•")
                                Text(network)
                                    .lineLimit(1)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        // Rating
                        if let ratings = series.ratings, let value = ratings.value, value > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", value))
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                        }
                        
                        // Progress
                        if let stats = series.statistics {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(stats.episodeFileCount ?? 0)/\(stats.episodeCount ?? 0) épisodes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ProgressView(value: stats.percentOfEpisodes ?? 0, total: 100)
                                    .tint((stats.percentOfEpisodes ?? 0) >= 100 ? .green : .blue)
                            }
                        }
                        
                        // Status badge
                        statusBadge
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(width: geometry.size.width)
        }
        .frame(height: 280)
    }
    
    private var backdropPlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 280)
    }
    
    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "tv")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            )
    }
    
    private var statusBadge: some View {
        Text(series.status ?? "")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch series.status?.lowercased() {
        case "continuing": return .green
        case "ended": return .gray
        case "upcoming": return .blue
        default: return .secondary
        }
    }
    
    // MARK: - Quick Info
    
    private var quickInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Instance
            HStack(spacing: 8) {
                Image(systemName: "server.rack")
                    .foregroundColor(.blue)
                    .font(.subheadline)
                Text(instance.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            // Genres
            if let genres = series.genres, !genres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(genres, id: \.self) { genre in
                            Text(genre)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Runtime & Certification
            HStack(spacing: 16) {
                if let runtime = series.runtime, runtime > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(runtime) min/épisode")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                if let certification = series.certification, !certification.isEmpty {
                    Text(certification)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Primary action buttons
            HStack(spacing: 12) {
                Button {
                    Task {
                        await searchSeries()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSearching && searchingSeason == nil {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text("Recherche auto")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSearching)
                
                Button {
                    interactiveSearchSeason = nil
                    showInteractiveSearch = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Interactive")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Delete button
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Supprimer de Sonarr")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.12))
                .foregroundColor(.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Synopsis
    
    private func synopsisSection(overview: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Synopsis")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(overview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Seasons
    
    private func seasonsSection(seasons: [SonarrSeason]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saisons")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(seasons.sorted { $0.seasonNumber < $1.seasonNumber }) { season in
                seasonRow(season: season)
            }
        }
    }
    
    private func seasonRow(season: SonarrSeason) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(season.seasonNumber == 0 ? "Spéciaux" : "Saison \(season.seasonNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let stats = season.statistics {
                    HStack(spacing: 10) {
                        Text("\(stats.episodeFileCount ?? 0)/\(stats.episodeCount ?? 0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: stats.percentOfEpisodes ?? 0, total: 100)
                            .frame(width: 80)
                            .tint((stats.percentOfEpisodes ?? 0) >= 100 ? .green : .blue)
                    }
                }
            }
            
            Spacer()
            
            // Auto search button
            Button {
                Task {
                    await searchSeason(season.seasonNumber)
                }
            } label: {
                Group {
                    if isSearching && searchingSeason == season.seasonNumber {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
            .disabled(isSearching)
            
            // Interactive search button
            Button {
                interactiveSearchSeason = season.seasonNumber
                showInteractiveSearch = true
            } label: {
                Image(systemName: "list.bullet.rectangle")
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.bordered)
            .tint(.purple)
        }
        .padding(14)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Technical
    
    private var technicalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informations")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                if let stats = series.statistics, let size = stats.sizeOnDisk, size > 0 {
                    infoRow(icon: "internaldrive", label: "Taille", value: Formatters.formatBytes(size))
                }
                
                if let path = series.path {
                    infoRow(icon: "folder", label: "Dossier", value: path)
                }
                
                // External links
                HStack(spacing: 20) {
                    if let imdbId = series.imdbId {
                        Link(destination: URL(string: "https://www.imdb.com/title/\(imdbId)")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                Text("IMDb")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    if let tvdbId = series.tvdbId {
                        Link(destination: URL(string: "https://thetvdb.com/?id=\(tvdbId)&tab=series")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                Text("TVDB")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Actions
    
    private func searchSeries() async {
        guard let service = instanceManager.sonarrService(for: instance) else {
            errorMessage = "Impossible de se connecter à Sonarr"
            return
        }
        
        isSearching = true
        searchingSeason = nil
        
        do {
            try await service.searchSeries(seriesId: series.id)
            successMessage = "Recherche lancée pour \"\(series.title)\""
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    private func searchSeason(_ seasonNumber: Int) async {
        guard let service = instanceManager.sonarrService(for: instance) else {
            errorMessage = "Impossible de se connecter à Sonarr"
            return
        }
        
        isSearching = true
        searchingSeason = seasonNumber
        
        do {
            try await service.searchSeason(seriesId: series.id, seasonNumber: seasonNumber)
            successMessage = "Recherche lancée pour la saison \(seasonNumber)"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
        searchingSeason = nil
    }
    
    private func deleteSeries() async {
        guard let service = instanceManager.sonarrService(for: instance) else {
            errorMessage = "Impossible de se connecter à Sonarr"
            return
        }
        
        do {
            try await service.deleteSeries(id: series.id, deleteFiles: false)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Interactive Search View

struct SeriesInteractiveSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var instanceManager: InstanceManager
    
    let seriesId: Int
    let seriesTitle: String
    let seasonNumber: Int?
    let instance: ServiceInstance
    
    @State private var releases: [SonarrRelease] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var downloadingGuid: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Recherche des releases...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    ContentUnavailableView {
                        Label("Erreur", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Réessayer") {
                            Task {
                                await loadReleases()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if releases.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun résultat", systemImage: "magnifyingglass")
                    } description: {
                        Text("Aucune release trouvée")
                    }
                } else {
                    releasesList
                }
            }
            .navigationTitle(seasonNumber != nil ? "Saison \(seasonNumber!)" : "Releases")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await loadReleases()
                }
            }
        }
    }
    
    private var releasesList: some View {
        List(releases) { release in
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(release.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        if let size = release.size {
                            Label(Formatters.formatBytes(size), systemImage: "doc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let seeders = release.seeders {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up")
                                Text("\(seeders)")
                            }
                            .font(.caption)
                            .foregroundColor(seeders > 10 ? .green : (seeders > 0 ? .orange : .red))
                        }
                        
                        if let leechers = release.leechers {
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.down")
                                Text("\(leechers)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        if let quality = release.quality?.quality?.name {
                            Text(quality)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let indexer = release.indexer {
                        Text(indexer)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Bouton Grab visible
                Button {
                    Task {
                        await downloadRelease(release)
                    }
                } label: {
                    Image(systemName: downloadingGuid == release.guid ? "arrow.down.circle" : "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(downloadingGuid == release.guid ? .gray : .green)
                }
                .buttonStyle(.plain)
                .disabled(downloadingGuid != nil)
            }
            .padding(.vertical, 6)
        }
        .listStyle(.insetGrouped)
    }
    
    private func loadReleases() async {
        guard let service = instanceManager.sonarrService(for: instance) else {
            errorMessage = "Impossible de se connecter à Sonarr"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            releases = try await service.getReleases(seriesId: seriesId, seasonNumber: seasonNumber)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func downloadRelease(_ release: SonarrRelease) async {
        guard let service = instanceManager.sonarrService(for: instance) else {
            return
        }
        
        downloadingGuid = release.guid
        
        do {
            try await service.downloadRelease(guid: release.guid, indexerId: release.safeIndexerId)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            downloadingGuid = nil
        }
    }
}
