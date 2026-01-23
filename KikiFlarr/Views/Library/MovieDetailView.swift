import SwiftUI

struct MovieDetailView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @Environment(\.dismiss) private var dismiss
    let movie: RadarrMovie
    let instance: ServiceInstance
    
    @State private var isSearching = false
    @State private var showDeleteConfirmation = false
    @State private var showInteractiveSearch = false
    @State private var showMarkAsWatched = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with backdrop
                headerSection
                
                // Content
                VStack(alignment: .leading, spacing: 20) {
                    // Quick info
                    quickInfoSection
                    
                    // Actions
                    actionsSection
                    
                    // Synopsis
                    if let overview = movie.overview, !overview.isEmpty {
                        synopsisSection(overview: overview)
                    }
                    
                    // Technical info
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
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(1)
            }
        }
        .sheet(isPresented: $showInteractiveSearch) {
            InteractiveSearchView(movieId: movie.id, movieTitle: movie.title, instance: instance)
        }
        .sheet(isPresented: $showMarkAsWatched) {
            MarkAsWatchedSheet(movie: movie)
        }
        .alert("Confirmer la suppression", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                Task {
                    await deleteMovie()
                }
            }
        } message: {
            Text("Voulez-vous supprimer \"\(movie.title)\" de Radarr ?")
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
                if let fanartURL = movie.fanartURL {
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
                    AsyncImage(url: movie.posterURL) { phase in
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
                        Text(movie.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Text("\(movie.year)")
                            
                            if let runtime = movie.runtime, runtime > 0 {
                                Text("•")
                                Text(Formatters.formatDuration(runtime))
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        // Ratings
                        ratingsView
                        
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
                Image(systemName: "film")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            )
    }
    
    @ViewBuilder
    private var ratingsView: some View {
        if let ratings = movie.ratings {
            HStack(spacing: 12) {
                if let imdb = ratings.imdb, let imdbValue = imdb.value, imdbValue > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", imdbValue))
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
                
                if let tmdb = ratings.tmdb, let tmdbValue = tmdb.value, tmdbValue > 0 {
                    HStack(spacing: 4) {
                        Text("TMDB")
                            .fontWeight(.bold)
                        Text(String(format: "%.1f", tmdbValue))
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
            }
        }
    }
    
    private var statusBadge: some View {
        Group {
            if movie.hasFile == true {
                Label("Disponible", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Label("Manquant", systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Quick Info
    
    private var quickInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Instance
            HStack(spacing: 8) {
                Image(systemName: "server.rack")
                    .foregroundColor(.orange)
                    .font(.subheadline)
                Text(instance.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            // Genres
            if let genres = movie.genres, !genres.isEmpty {
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
            
            // Studio & Certification
            HStack(spacing: 16) {
                if let studio = movie.studio, !studio.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.caption)
                        Text(studio)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                if let certification = movie.certification, !certification.isEmpty {
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
                        await automaticSearch()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSearching {
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
            
            // Secondary actions
            HStack(spacing: 12) {
                if let youtubeId = movie.youTubeTrailerId, !youtubeId.isEmpty {
                    Link(destination: URL(string: "https://www.youtube.com/watch?v=\(youtubeId)")!) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Trailer")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Supprimer")
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
            
            // Bouton Marquer comme vu
            Button {
                if watchedViewModel.isWatched(movie) {
                    // Déjà vu - on pourrait permettre de le retirer
                } else {
                    showMarkAsWatched = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: watchedViewModel.isWatched(movie) ? "checkmark.circle.fill" : "eye")
                    Text(watchedViewModel.isWatched(movie) ? "Déjà vu" : "Marquer comme vu")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(watchedViewModel.isWatched(movie) ? Color.green : Color.green.opacity(0.15))
                .foregroundColor(watchedViewModel.isWatched(movie) ? .white : .green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(watchedViewModel.isWatched(movie))
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
    
    // MARK: - Technical
    
    private var technicalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informations")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                if let movieFile = movie.movieFile {
                    if let size = movieFile.size {
                        infoRow(icon: "internaldrive", label: "Taille", value: Formatters.formatBytes(size))
                    }
                    
                    if let path = movieFile.relativePath {
                        infoRow(icon: "doc", label: "Fichier", value: path)
                    }
                    
                    if let quality = movieFile.quality?.quality?.name {
                        infoRow(icon: "sparkles.tv", label: "Qualité", value: quality)
                    }
                    
                    if let videoCodec = movieFile.mediaInfo?.videoCodec {
                        infoRow(icon: "video", label: "Codec vidéo", value: videoCodec)
                    }
                    
                    if let audioCodec = movieFile.mediaInfo?.audioCodec {
                        infoRow(icon: "speaker.wave.2", label: "Codec audio", value: audioCodec)
                    }
                }
                
                if let path = movie.path {
                    infoRow(icon: "folder", label: "Dossier", value: path)
                }
                
                if let imdbId = movie.imdbId {
                    Link(destination: URL(string: "https://www.imdb.com/title/\(imdbId)")!) {
                        HStack {
                            Image(systemName: "link")
                                .frame(width: 20)
                            Text("Voir sur IMDb")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
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
    
    private func automaticSearch() async {
        guard let service = instanceManager.radarrService(for: instance) else {
            errorMessage = "Impossible de se connecter à Radarr"
            return
        }
        
        isSearching = true
        
        do {
            try await service.searchMovie(movieId: movie.id)
            successMessage = "Recherche lancée pour \"\(movie.title)\""
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    private func deleteMovie() async {
        guard let service = instanceManager.radarrService(for: instance) else {
            errorMessage = "Impossible de se connecter à Radarr"
            return
        }
        
        do {
            try await service.deleteMovie(id: movie.id, deleteFiles: false)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Interactive Search View

struct InteractiveSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var instanceManager: InstanceManager
    
    let movieId: Int
    let movieTitle: String
    let instance: ServiceInstance
    
    @State private var releases: [RadarrRelease] = []
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
                        Text("Aucune release trouvée pour ce film")
                    }
                } else {
                    releasesList
                }
            }
            .navigationTitle("Releases")
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
        guard let service = instanceManager.radarrService(for: instance) else {
            errorMessage = "Impossible de se connecter à Radarr"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            releases = try await service.getReleases(movieId: movieId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func downloadRelease(_ release: RadarrRelease) async {
        guard let service = instanceManager.radarrService(for: instance) else {
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

// MARK: - Mark As Watched Sheet

struct MarkAsWatchedSheet: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNotesFocused: Bool
    
    let movie: RadarrMovie
    
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var watchedDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                // Aperçu du film
                Section {
                    HStack(spacing: 12) {
                        AsyncImage(url: movie.posterURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(_), .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "film")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                        }
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(movie.title)
                                .font(.headline)
                                .lineLimit(2)
                            
                            Text("\(movie.year)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let runtime = movie.runtime, runtime > 0 {
                                Text(Formatters.formatDuration(runtime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Date de visionnage
                Section("Date de visionnage") {
                    WatchedDatePickerCard(watchedDate: $watchedDate)
                }
                
                // Note
                Section("Ma note (optionnel)") {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                if rating == star {
                                    rating = 0
                                } else {
                                    rating = star
                                }
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title)
                                    .foregroundColor(.yellow)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                        
                        if rating > 0 {
                            Text("\(rating)/5")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Notes personnelles
                Section("Notes (optionnel)") {
                    TextField("Mes impressions sur le film...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isNotesFocused)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onSubmit { isNotesFocused = false }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Marquer comme vu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmer") {
                        markAsWatched()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func markAsWatched() {
        let baseMovie = WatchedMovie.from(movie: movie)
        
        // Recréer avec les détails personnalisés
        let watchedMovie = WatchedMovie(
            id: baseMovie.id,
            tmdbId: baseMovie.tmdbId,
            radarrId: baseMovie.radarrId,
            title: baseMovie.title,
            year: baseMovie.year,
            posterURL: baseMovie.posterURL,
            fanartURL: baseMovie.fanartURL,
            genres: baseMovie.genres,
            runtime: baseMovie.runtime,
            watchedDate: watchedDate,
            rating: rating > 0 ? rating : nil,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Utiliser le ViewModel pour mettre à jour les stats et vérifier les badges
        watchedViewModel.addToWatched(watchedMovie)
        
        dismiss()
    }
}
