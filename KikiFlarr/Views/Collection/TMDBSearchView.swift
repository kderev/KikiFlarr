import SwiftUI

enum TMDBSearchType: String, CaseIterable {
    case movies = "Films"
    case series = "Séries"
}

struct TMDBSearchView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    
    @State private var searchText = ""
    @State private var searchType: TMDBSearchType = .movies
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    // Films
    @State private var movieResults: [TMDBMovie] = []
    @State private var popularMovies: [TMDBMovie] = []
    
    // Séries
    @State private var seriesResults: [TMDBTVShow] = []
    @State private var popularSeries: [TMDBTVShow] = []
    
    @State private var isLoadingPopular = false
    
    // Sheet states - utilisation de item binding pour éviter la page grise
    @State private var selectedMovie: TMDBMovie?
    @State private var selectedSeries: TMDBTVShow?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                Picker("Type", selection: $searchType) {
                    ForEach(TMDBSearchType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Barre de recherche
                searchBar
                
                // Contenu
                Group {
                    if isSearching || isLoadingPopular {
                        ProgressView("Recherche...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = errorMessage {
                        ContentUnavailableView {
                            Label("Erreur", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(error)
                        }
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle(searchType == .movies ? "Ajouter un film vu" : "Ajouter une série vue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedMovie) { movie in
                MovieRatingSheet(movie: movie) { rating, notes, watchedDate in
                    markMovieAsWatched(movie: movie, rating: rating, notes: notes, watchedDate: watchedDate)
                }
            }
            .sheet(item: $selectedSeries) { series in
                SeriesEpisodePickerSheet(series: series)
            }
            .task {
                await loadPopularContent()
            }
            .onChange(of: searchType) { _, _ in
                // Réinitialiser les résultats lors du changement de type
                searchText = ""
                movieResults = []
                seriesResults = []
                Task {
                    await loadPopularContent()
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch searchType {
        case .movies:
            if !movieResults.isEmpty {
                moviesList(movies: movieResults, title: "Résultats")
            } else if searchText.isEmpty && !popularMovies.isEmpty {
                moviesList(movies: popularMovies, title: "Films populaires")
            } else if !searchText.isEmpty {
                ContentUnavailableView {
                    Label("Aucun résultat", systemImage: "magnifyingglass")
                } description: {
                    Text("Aucun film trouvé pour \"\(searchText)\"")
                }
            } else {
                ProgressView()
            }
            
        case .series:
            if !seriesResults.isEmpty {
                seriesList(series: seriesResults, title: "Résultats")
            } else if searchText.isEmpty && !popularSeries.isEmpty {
                seriesList(series: popularSeries, title: "Séries populaires")
            } else if !searchText.isEmpty {
                ContentUnavailableView {
                    Label("Aucun résultat", systemImage: "magnifyingglass")
                } description: {
                    Text("Aucune série trouvée pour \"\(searchText)\"")
                }
            } else {
                ProgressView()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(
                searchType == .movies ? "Rechercher un film..." : "Rechercher une série...",
                text: $searchText
            )
            .textFieldStyle(.plain)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isSearchFocused)
            .submitLabel(.search)
            .onSubmit {
                Task {
                    await search()
                }
            }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    movieResults = []
                    seriesResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                movieResults = []
                seriesResults = []
            }
        }
    }
    
    // MARK: - Movies List
    
    private func moviesList(movies: [TMDBMovie], title: String) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                ForEach(movies) { movie in
                    TMDBMovieRow(
                        movie: movie,
                        isAlreadyWatched: watchedViewModel.isMovieWatched(tmdbId: movie.id)
                    ) {
                        selectedMovie = movie
                    }
                    
                    Divider()
                        .padding(.leading, 80)
                }
            }
            .padding(.top)
        }
    }
    
    // MARK: - Series List
    
    private func seriesList(series: [TMDBTVShow], title: String) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                ForEach(series) { show in
                    TMDBSeriesRow(
                        series: show,
                        isAlreadyWatched: watchedViewModel.isSeriesWatched(tvdbId: show.id)
                    ) {
                        selectedSeries = show
                    }
                    
                    Divider()
                        .padding(.leading, 80)
                }
            }
            .padding(.top)
        }
    }
    
    // MARK: - Search
    
    private func search() async {
        guard !searchText.isEmpty else { return }
        guard let service = instanceManager.tmdbService() else {
            errorMessage = "TMDB non configuré"
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        do {
            switch searchType {
            case .movies:
                let response = try await service.searchMovies(query: searchText)
                movieResults = response.results
            case .series:
                let response = try await service.searchTVShows(query: searchText)
                seriesResults = response.results
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    private func loadPopularContent() async {
        guard let service = instanceManager.tmdbService() else { return }
        
        isLoadingPopular = true
        
        do {
            switch searchType {
            case .movies:
                if popularMovies.isEmpty {
                    let response = try await service.getPopularMovies()
                    popularMovies = response.results
                }
            case .series:
                if popularSeries.isEmpty {
                    let response = try await service.getPopularTVShows()
                    popularSeries = response.results
                }
            }
        } catch {
            // Silently fail for popular content
        }
        
        isLoadingPopular = false
    }
    
    // MARK: - Mark as Watched
    
    private func markMovieAsWatched(movie: TMDBMovie, rating: Int?, notes: String?, watchedDate: Date) {
        Task {
            if let service = instanceManager.tmdbService() {
                do {
                    let detailedMovie = try await service.getMovieDetails(id: movie.id)
                    let watchedMovie = WatchedMovie(
                        tmdbId: detailedMovie.id,
                        radarrId: nil,
                        title: detailedMovie.title,
                        year: detailedMovie.year,
                        posterURL: detailedMovie.posterURL?.absoluteString,
                        fanartURL: detailedMovie.backdropURL?.absoluteString,
                        genres: detailedMovie.genreNames,
                        runtime: detailedMovie.runtime,
                        watchedDate: watchedDate,
                        rating: rating,
                        notes: notes
                    )
                    watchedViewModel.addToWatched(watchedMovie)
                } catch {
                    let watchedMovie = WatchedMovie(
                        tmdbId: movie.id,
                        radarrId: nil,
                        title: movie.title,
                        year: movie.year,
                        posterURL: movie.posterURL?.absoluteString,
                        fanartURL: movie.backdropURL?.absoluteString,
                        genres: TMDBGenreMapper.genreNames(from: movie.genreIds),
                        runtime: movie.runtime,
                        watchedDate: watchedDate,
                        rating: rating,
                        notes: notes
                    )
                    watchedViewModel.addToWatched(watchedMovie)
                }
            }
        }
        selectedMovie = nil
    }
}

// MARK: - Movie Row

struct TMDBMovieRow: View {
    let movie: TMDBMovie
    let isAlreadyWatched: Bool
    let onMarkAsWatched: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Poster
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
            
            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if movie.year > 0 {
                    Text("\(movie.year)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let vote = movie.voteAverage, vote > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", vote))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let overview = movie.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Bouton
            if isAlreadyWatched {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            } else {
                Button {
                    onMarkAsWatched()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Series Row

struct TMDBSeriesRow: View {
    let series: TMDBTVShow
    let isAlreadyWatched: Bool
    let onMarkAsWatched: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Poster
            AsyncImage(url: series.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_), .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "tv")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text(series.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if series.year > 0 {
                        Text("\(series.year)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let seasons = series.numberOfSeasons, seasons > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(seasons) saison\(seasons > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let vote = series.voteAverage, vote > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", vote))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let overview = series.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Bouton
            if isAlreadyWatched {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            } else {
                Button {
                    onMarkAsWatched()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Movie Rating Sheet

struct MovieRatingSheet: View {
    let movie: TMDBMovie
    let onConfirm: (Int?, String?, Date) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNotesFocused: Bool
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var watchedDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        AsyncImage(url: movie.posterURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "film")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(movie.title)
                                .font(.headline)
                            
                            if movie.year > 0 {
                                Text("\(movie.year)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Date de visionnage") {
                    DatePicker("Date", selection: $watchedDate, displayedComponents: [.date])
                }
                
                Section("Votre note (optionnel)") {
                    HStack {
                        Spacer()
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
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Notes (optionnel)") {
                    TextField("Vos commentaires...", text: $notes, axis: .vertical)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirmer") {
                        onConfirm(rating > 0 ? rating : nil, notes.isEmpty ? nil : notes, watchedDate)
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(false)
    }
}

// MARK: - Series Episode Picker Sheet

struct SeriesEpisodePickerSheet: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @Environment(\.dismiss) private var dismiss
    
    let series: TMDBTVShow
    
    @State private var detailedSeries: TMDBTVShow?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement des saisons...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView {
                        Label("Erreur", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Réessayer") {
                            Task { await loadSeriesDetails() }
                        }
                    }
                } else if let series = detailedSeries, let seasons = series.seasons?.filter({ $0.seasonNumber > 0 }) {
                    List {
                        // Header de la série
                        Section {
                            SeriesHeaderView(series: series)
                        }
                        
                        // Liste des saisons
                        Section("Saisons") {
                            ForEach(seasons) { season in
                                NavigationLink {
                                    SeasonEpisodesView(
                                        series: series,
                                        season: season
                                    )
                                } label: {
                                    SeasonRowView(season: season, seriesId: series.id)
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Aucune saison", systemImage: "tv")
                    } description: {
                        Text("Cette série n'a pas de saisons disponibles")
                    }
                }
            }
            .navigationTitle(series.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadSeriesDetails()
            }
        }
    }
    
    private func loadSeriesDetails() async {
        guard let service = instanceManager.tmdbService() else {
            errorMessage = "TMDB non configuré"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            detailedSeries = try await service.getTVShowDetails(id: series.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Series Header View

struct SeriesHeaderView: View {
    let series: TMDBTVShow
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: series.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "tv")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 80, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(series.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if series.year > 0 {
                        Text("\(series.year)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let seasons = series.numberOfSeasons, seasons > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(seasons) saison\(seasons > 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let episodes = series.numberOfEpisodes, episodes > 0 {
                    Text("\(episodes) épisodes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let vote = series.voteAverage, vote > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", vote))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Season Row View

struct SeasonRowView: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    let season: TMDBSeason
    let seriesId: Int
    
    private var watchedCount: Int {
        watchedViewModel.watchedEpisodes.filter {
            $0.seriesTmdbId == seriesId && $0.seasonNumber == season.seasonNumber
        }.count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: season.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "tv")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 50, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(season.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let episodeCount = season.episodeCount, episodeCount > 0 {
                    HStack(spacing: 4) {
                        Text("\(episodeCount) épisodes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if watchedCount > 0 {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("\(watchedCount) vus")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                if season.year > 0 {
                    Text("\(season.year)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Indicateur de progression
            if let episodeCount = season.episodeCount, episodeCount > 0 {
                if watchedCount == episodeCount {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if watchedCount > 0 {
                    Text("\(watchedCount)/\(episodeCount)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Season Episodes View

struct SeasonEpisodesView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    
    let series: TMDBTVShow
    let season: TMDBSeason
    
    @State private var episodes: [TMDBEpisode] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedEpisode: TMDBEpisode?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Chargement des épisodes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Erreur", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Réessayer") {
                        Task { await loadEpisodes() }
                    }
                }
            } else if episodes.isEmpty {
                ContentUnavailableView {
                    Label("Aucun épisode", systemImage: "film")
                } description: {
                    Text("Cette saison n'a pas d'épisodes disponibles")
                }
            } else {
                List {
                    ForEach(episodes) { episode in
                        EpisodeRowView(
                            episode: episode,
                            series: series,
                            isWatched: watchedViewModel.isEpisodeWatched(
                                seriesTmdbId: series.id,
                                seasonNumber: episode.seasonNumber,
                                episodeNumber: episode.episodeNumber
                            ),
                            onMarkAsWatched: {
                                selectedEpisode = episode
                            },
                            onRemoveFromWatched: {
                                removeEpisodeFromWatched(episode: episode)
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle(season.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadEpisodes()
        }
        .sheet(item: $selectedEpisode) { episode in
            EpisodeRatingSheet(
                episode: episode,
                series: series
            ) { rating, notes, watchedDate in
                markEpisodeAsWatched(episode: episode, rating: rating, notes: notes, watchedDate: watchedDate)
            }
        }
    }
    
    private func loadEpisodes() async {
        guard let service = instanceManager.tmdbService() else {
            errorMessage = "TMDB non configuré"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let seasonDetails = try await service.getSeasonDetails(tvId: series.id, seasonNumber: season.seasonNumber)
            episodes = seasonDetails.episodes ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func markEpisodeAsWatched(episode: TMDBEpisode, rating: Int?, notes: String?, watchedDate: Date) {
        let watchedEpisode = WatchedEpisode(
            tmdbId: episode.id,
            seriesTmdbId: series.id,
            seriesTitle: series.name,
            seriesPosterURL: series.posterURL?.absoluteString,
            seriesTotalEpisodes: series.numberOfEpisodes,
            episodeTitle: episode.name,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber,
            runtime: episode.runtime,
            stillURL: episode.stillURL?.absoluteString,
            overview: episode.overview,
            watchedDate: watchedDate,
            rating: rating,
            notes: notes
        )
        
        watchedViewModel.addToWatched(watchedEpisode)
    }
    
    private func removeEpisodeFromWatched(episode: TMDBEpisode) {
        if let watchedEpisode = watchedViewModel.watchedEpisodes.first(where: {
            $0.seriesTmdbId == series.id &&
            $0.seasonNumber == episode.seasonNumber &&
            $0.episodeNumber == episode.episodeNumber
        }) {
            watchedViewModel.removeFromWatched(watchedEpisode)
        }
    }
}

// MARK: - Episode Row View

struct EpisodeRowView: View {
    let episode: TMDBEpisode
    let series: TMDBTVShow
    let isWatched: Bool
    let onMarkAsWatched: () -> Void
    var onRemoveFromWatched: (() -> Void)? = nil
    
    @State private var showRemoveConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Image de l'épisode
            AsyncImage(url: episode.stillURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "play.rectangle")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 100, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 4) {
                // Numéro d'épisode
                Text(episode.episodeCode)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                // Titre
                Text(episode.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    // Durée
                    if let runtime = episode.formattedRuntime {
                        Text(runtime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Note
                    if let vote = episode.voteAverage, vote > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", vote))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Bouton
            if isWatched {
                Button {
                    showRemoveConfirmation = true
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    onMarkAsWatched()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog(
            "Retirer des épisodes vus ?",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Retirer", role: .destructive) {
                onRemoveFromWatched?()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("\(episode.episodeCode) - \(episode.name)")
        }
    }
}

// MARK: - Episode Rating Sheet

struct EpisodeRatingSheet: View {
    let episode: TMDBEpisode
    let series: TMDBTVShow
    let onConfirm: (Int?, String?, Date) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNotesFocused: Bool
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var watchedDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                // Aperçu de l'épisode
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        // Image
                        AsyncImage(url: episode.stillURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "play.rectangle")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Infos
                        VStack(alignment: .leading, spacing: 4) {
                            Text(episode.episodeCode)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text(episode.name)
                                .font(.headline)
                            
                            Text(series.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let runtime = episode.formattedRuntime {
                                Text(runtime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let overview = episode.overview, !overview.isEmpty {
                            Text(overview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                    }
                }
                
                Section("Date de visionnage") {
                    DatePicker("Date", selection: $watchedDate, displayedComponents: [.date])
                }
                
                Section("Votre note (optionnel)") {
                    HStack {
                        Spacer()
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
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Notes (optionnel)") {
                    TextField("Vos commentaires...", text: $notes, axis: .vertical)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirmer") {
                        onConfirm(rating > 0 ? rating : nil, notes.isEmpty ? nil : notes, watchedDate)
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(false)
    }
}

#Preview {
    TMDBSearchView()
        .environmentObject(InstanceManager())
        .environmentObject(WatchedViewModel())
}
