import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @EnvironmentObject var instanceManager: InstanceManager
    @State private var selectedTab: CollectionTab = .movies
    @State private var showStats = false
    @State private var showTMDBSearch = false
    @State private var tmdbSearchType: TMDBSearchType = .movies
    
    enum CollectionTab: String, CaseIterable {
        case movies = "Films vus"
        case episodes = "Épisodes vus"
        case badges = "Badges"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Picker pour switcher entre films et badges
                Picker("", selection: $selectedTab) {
                    ForEach(CollectionTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Contenu
                Group {
                    switch selectedTab {
                    case .movies:
                        WatchedMoviesListView(
                            onAddMovie: {
                                tmdbSearchType = .movies
                                showTMDBSearch = true
                            },
                            onAddSeries: {
                                tmdbSearchType = .series
                                showTMDBSearch = true
                            }
                        )
                    case .episodes:
                        WatchedEpisodesListView(
                            onAddMovie: {
                                tmdbSearchType = .movies
                                showTMDBSearch = true
                            },
                            onAddSeries: {
                                tmdbSearchType = .series
                                showTMDBSearch = true
                            }
                        )
                    case .badges:
                        BadgesGridView()
                    }
                }
            }
            .navigationTitle("Ma Collection")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if instanceManager.hasTMDBConfigured && selectedTab != .badges {
                        Button {
                            tmdbSearchType = selectedTab == .episodes ? .series : .movies
                            showTMDBSearch = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showStats = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
            .sheet(isPresented: $showStats) {
                StatsView()
            }
            .sheet(isPresented: $showTMDBSearch) {
                TMDBSearchView(initialSearchType: tmdbSearchType)
            }
        }
        .overlay(alignment: .top) {
            // Animation de badge débloqué
            if watchedViewModel.showBadgeUnlockAnimation,
               let badge = watchedViewModel.recentlyUnlockedBadge {
                BadgeUnlockToast(badge: badge)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: watchedViewModel.showBadgeUnlockAnimation)
    }
}

// MARK: - Liste des films vus

struct WatchedMoviesListView: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @EnvironmentObject var instanceManager: InstanceManager
    @State private var searchText = ""
    let onAddMovie: () -> Void
    let onAddSeries: () -> Void
    
    var filteredMovies: [WatchedMovie] {
        if searchText.isEmpty {
            return watchedViewModel.watchedMovies
        }
        return watchedViewModel.watchedMovies.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        Group {
            if watchedViewModel.watchedMovies.isEmpty {
                emptyState
            } else {
                moviesList
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("Aucun film vu", systemImage: "film")
        } description: {
            if instanceManager.hasTMDBConfigured {
                Text("Ajoutez un film ou une série vue pour démarrer votre collection.")
            } else {
                Text("Marquez des films comme vus depuis votre bibliothèque ou configurez TMDB dans les paramètres pour rechercher des films")
            }
        } actions: {
            if instanceManager.hasTMDBConfigured {
                Button("Ajouter un film") {
                    onAddMovie()
                }
                .buttonStyle(.borderedProminent)
                Button("Ajouter une série") {
                    onAddSeries()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var moviesList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                CollectionHeroCard(
                    title: "Ajout rapide",
                    subtitle: "Comme sur Trakt, marquez vos films et séries vus en quelques secondes."
                ) {
                    if instanceManager.hasTMDBConfigured {
                        CollectionActionCard(
                            title: "Ajouter un film",
                            subtitle: "Recherche TMDB",
                            systemImage: "film.fill",
                            tint: .blue,
                            action: onAddMovie
                        )
                        CollectionActionCard(
                            title: "Ajouter une série",
                            subtitle: "Choisir des épisodes",
                            systemImage: "tv.fill",
                            tint: .teal,
                            action: onAddSeries
                        )
                    } else {
                        CollectionInfoCard(
                            title: "TMDB non configuré",
                            message: "Activez TMDB dans les réglages pour rechercher et ajouter rapidement.",
                            systemImage: "gearshape.fill"
                        )
                    }
                }

                CollectionSectionCard {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            StatBubble(
                                icon: "film.fill",
                                value: "\(watchedViewModel.stats.totalMovies)",
                                label: "Films",
                                color: .blue
                            )
                            
                            StatBubble(
                                icon: "tv.fill",
                                value: "\(watchedViewModel.stats.totalEpisodes)",
                                label: "Épisodes",
                                color: .teal
                            )
                            
                            StatBubble(
                                icon: "play.rectangle.fill",
                                value: "\(watchedViewModel.stats.totalWatched)",
                                label: "Total",
                                color: .indigo
                            )
                        }
                        
                        HStack(spacing: 12) {
                            StatBubble(
                                icon: "clock.fill",
                                value: watchedViewModel.stats.formattedCombinedRuntime,
                                label: "Durée totale",
                                color: .purple
                            )
                            
                            StatBubble(
                                icon: "flame.fill",
                                value: "\(watchedViewModel.stats.currentStreak)",
                                label: "Streak",
                                color: .orange
                            )
                        }
                    }
                }

                CollectionSectionHeader(title: "Films récents", systemImage: "sparkles")
                VStack(spacing: 12) {
                    ForEach(filteredMovies) { movie in
                        WatchedMovieRow(movie: movie) {
                            watchedViewModel.removeFromWatched(movie)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .searchable(text: $searchText, prompt: "Rechercher un film")
    }
}

// MARK: - Liste des épisodes vus

struct NextEpisodeSuggestion: Identifiable {
    let id = UUID()
    let series: TMDBTVShow
    let episode: TMDBEpisode
}

struct WatchedEpisodesListView: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @EnvironmentObject var instanceManager: InstanceManager
    @State private var searchText = ""
    @State private var nextEpisodeSuggestion: NextEpisodeSuggestion?
    @State private var isLoadingSuggestion = false
    @State private var selectedEpisode: TMDBEpisode?
    @State private var selectedSeries: TMDBTVShow?
    let onAddMovie: () -> Void
    let onAddSeries: () -> Void

    var filteredEpisodes: [WatchedEpisode] {
        if searchText.isEmpty {
            return watchedViewModel.watchedEpisodes
        }
        return watchedViewModel.watchedEpisodes.filter {
            $0.seriesTitle.localizedCaseInsensitiveContains(searchText) ||
            $0.episodeTitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if watchedViewModel.watchedEpisodes.isEmpty {
                emptyState
            } else {
                episodesList
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Aucun épisode vu", systemImage: "tv")
        } description: {
            if instanceManager.hasTMDBConfigured {
                Text("Ajoutez une série pour sélectionner les épisodes vus.")
            } else {
                Text("Marquez des épisodes comme vus depuis votre bibliothèque de séries")
            }
        } actions: {
            if instanceManager.hasTMDBConfigured {
                Button("Ajouter une série") {
                    onAddSeries()
                }
                .buttonStyle(.borderedProminent)
                Button("Ajouter un film") {
                    onAddMovie()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var episodesList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                CollectionHeroCard(
                    title: "Ajout rapide",
                    subtitle: "Ajoutez une série vue et sélectionnez les épisodes en un geste."
                ) {
                    if instanceManager.hasTMDBConfigured {
                        CollectionActionCard(
                            title: "Ajouter une série",
                            subtitle: "Choisir des épisodes",
                            systemImage: "tv.fill",
                            tint: .teal,
                            action: onAddSeries
                        )
                        CollectionActionCard(
                            title: "Ajouter un film",
                            subtitle: "Recherche TMDB",
                            systemImage: "film.fill",
                            tint: .blue,
                            action: onAddMovie
                        )
                    } else {
                        CollectionInfoCard(
                            title: "TMDB non configuré",
                            message: "Activez TMDB pour rechercher vos séries et films.",
                            systemImage: "gearshape.fill"
                        )
                    }
                }

                if let suggestion = nextEpisodeSuggestion {
                    NextEpisodeSuggestionCard(suggestion: suggestion) {
                        selectedEpisode = suggestion.episode
                        selectedSeries = suggestion.series
                    }
                } else if isLoadingSuggestion {
                    CollectionSectionCard {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Préparation de votre prochain épisode...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                CollectionSectionCard {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            StatBubble(
                                icon: "film.fill",
                                value: "\(watchedViewModel.stats.totalMovies)",
                                label: "Films",
                                color: .blue
                            )

                            StatBubble(
                                icon: "tv.fill",
                                value: "\(watchedViewModel.stats.totalEpisodes)",
                                label: "Épisodes",
                                color: .teal
                            )

                            StatBubble(
                                icon: "play.rectangle.fill",
                                value: "\(watchedViewModel.stats.totalWatched)",
                                label: "Total",
                                color: .indigo
                            )
                        }

                        HStack(spacing: 12) {
                            StatBubble(
                                icon: "clock.fill",
                                value: watchedViewModel.stats.formattedCombinedRuntime,
                                label: "Durée totale",
                                color: .purple
                            )

                            StatBubble(
                                icon: "flame.fill",
                                value: "\(watchedViewModel.stats.currentStreak)",
                                label: "Streak",
                                color: .orange
                            )
                        }
                    }
                }

                CollectionSectionHeader(title: "Épisodes récents", systemImage: "sparkles")
                VStack(spacing: 12) {
                    ForEach(filteredEpisodes) { episode in
                        WatchedEpisodeRow(episode: episode) {
                            watchedViewModel.removeFromWatched(episode)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .searchable(text: $searchText, prompt: "Rechercher un épisode ou une série")
        .task(id: watchedViewModel.watchedEpisodes.first?.id) {
            await loadNextEpisodeSuggestion()
        }
        .sheet(item: $selectedEpisode) { episode in
            if let series = selectedSeries {
                EpisodeRatingSheet(episode: episode, series: series) { rating, notes, watchedDate in
                    markEpisodeAsWatched(episode: episode, series: series, rating: rating, notes: notes, watchedDate: watchedDate)
                }
            } else {
                EmptyView()
            }
        }
    }

    private func loadNextEpisodeSuggestion() async {
        guard let lastEpisode = watchedViewModel.watchedEpisodes.first,
              instanceManager.hasTMDBConfigured,
              let service = instanceManager.tmdbService() else {
            nextEpisodeSuggestion = nil
            return
        }

        isLoadingSuggestion = true

        do {
            let series = try await service.getTVShowDetails(id: lastEpisode.seriesTmdbId)
            if let nextEpisode = try await fetchNextEpisode(service: service, lastEpisode: lastEpisode) {
                nextEpisodeSuggestion = NextEpisodeSuggestion(series: series, episode: nextEpisode)
            } else {
                nextEpisodeSuggestion = nil
            }
        } catch {
            nextEpisodeSuggestion = nil
        }

        isLoadingSuggestion = false
    }

    private func fetchNextEpisode(service: TMDBService, lastEpisode: WatchedEpisode) async throws -> TMDBEpisode? {
        let seasonDetails = try await service.getSeasonDetails(
            tvId: lastEpisode.seriesTmdbId,
            seasonNumber: lastEpisode.seasonNumber
        )

        if let next = seasonDetails.episodes?.first(where: { $0.episodeNumber == lastEpisode.episodeNumber + 1 }) {
            return next
        }

        let nextSeasonNumber = lastEpisode.seasonNumber + 1
        let nextSeason = try await service.getSeasonDetails(
            tvId: lastEpisode.seriesTmdbId,
            seasonNumber: nextSeasonNumber
        )

        return nextSeason.episodes?.first(where: { $0.episodeNumber == 1 })
    }

    private func markEpisodeAsWatched(
        episode: TMDBEpisode,
        series: TMDBTVShow,
        rating: Int?,
        notes: String?,
        watchedDate: Date
    ) {
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
}

// MARK: - Ligne d'épisode vu

struct WatchedEpisodeRow: View {
    let episode: WatchedEpisode
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: episode.stillURL ?? episode.seriesPosterURL ?? "")) { phase in
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
            .frame(width: 96, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(episode.seriesTitle)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(episode.episodeCode) • \(episode.episodeTitle)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(episode.watchedDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let runtime = episode.formattedRuntime {
                        Text(runtime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                if let onDelete {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Ligne de film vu

struct WatchedMovieRow: View {
    let movie: WatchedMovie
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: movie.posterURL ?? "")) { phase in
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
            .frame(width: 70, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("\(movie.year)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Label(movie.watchedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let rating = movie.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                if let onDelete {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Grille de badges

struct BadgesGridView: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @State private var selectedCategory: BadgeCategory?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progression globale
                progressSection
                
                // Badges par catégorie
                ForEach(BadgeCategory.allCases, id: \.self) { category in
                    badgeCategorySection(category)
                }
            }
            .padding()
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progression")
                    .font(.headline)
                Spacer()
                Text("\(watchedViewModel.unlockedBadges.count)/\(watchedViewModel.allBadges.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: watchedViewModel.badgeProgress)
                .tint(.orange)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Badges récemment débloqués
            if !watchedViewModel.unlockedBadges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(watchedViewModel.unlockedBadges.suffix(5).reversed()) { badge in
                            BadgeMiniCard(badge: badge)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func badgeCategorySection(_ category: BadgeCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(categoryColor(category))
                Text(category.rawValue)
                    .font(.headline)
                
                Spacer()
                
                let unlocked = watchedViewModel.badges(for: category).filter { $0.isUnlocked }.count
                let total = watchedViewModel.badges(for: category).count
                Text("\(unlocked)/\(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(watchedViewModel.badges(for: category)) { badge in
                    BadgeCard(badge: badge)
                }
            }
        }
    }
    
    private func categoryColor(_ category: BadgeCategory) -> Color {
        switch category.color {
        case "gold": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "blue": return .blue
        default: return .gray
        }
    }
}

// MARK: - Carte de badge

struct BadgeCard: View {
    let badge: Badge
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(badge.isUnlocked ? rarityGradient : lockedGradient)
                        .frame(width: 60, height: 60)
                    
                    if badge.isUnlocked {
                        Text(badge.icon)
                            .font(.title)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .shadow(color: badge.isUnlocked ? rarityColor.opacity(badge.rarity.glowIntensity) : .clear, radius: 8)
                
                Text(badge.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(badge.isUnlocked ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            BadgeDetailSheet(badge: badge)
                .presentationDetents([.medium])
        }
    }
    
    private var rarityColor: Color {
        switch badge.rarity.color {
        case "gray": return .gray
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        default: return .gray
        }
    }
    
    private var rarityGradient: LinearGradient {
        LinearGradient(
            colors: [rarityColor, rarityColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var lockedGradient: LinearGradient {
        LinearGradient(
            colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Mini carte de badge

struct BadgeMiniCard: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 4) {
            Text(badge.icon)
                .font(.title2)
            Text(badge.name)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Détail du badge

struct BadgeDetailSheet: View {
    let badge: Badge
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(badge.isUnlocked ? rarityGradient : lockedGradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: badge.isUnlocked ? rarityColor.opacity(0.5) : .clear, radius: 20)
                    
                    if badge.isUnlocked {
                        Text(badge.icon)
                            .font(.system(size: 60))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Infos
                VStack(spacing: 8) {
                    Text(badge.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(badge.rarity.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(rarityColor.opacity(0.2))
                        .foregroundColor(rarityColor)
                        .clipShape(Capsule())
                    
                    Text(badge.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    
                    if let unlockedDate = badge.unlockedDate {
                        HStack {
                            Image(systemName: "calendar.badge.checkmark")
                            Text("Débloqué le \(unlockedDate.formatted(date: .abbreviated, time: .omitted))")
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var rarityColor: Color {
        switch badge.rarity.color {
        case "gray": return .gray
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        default: return .gray
        }
    }
    
    private var rarityGradient: LinearGradient {
        LinearGradient(
            colors: [rarityColor, rarityColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var lockedGradient: LinearGradient {
        LinearGradient(
            colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Cartes d'ajout rapide

struct CollectionHeroCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    content
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(.secondarySystemBackground), Color(.tertiarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct CollectionActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundColor(tint)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 190, alignment: .leading)
            .padding()
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.25), tint.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

struct CollectionInfoCard: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 240, alignment: .leading)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct CollectionSectionCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal)
    }
}

struct CollectionSectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct NextEpisodeSuggestionCard: View {
    let suggestion: NextEpisodeSuggestion
    let onAdd: () -> Void

    var body: some View {
        CollectionSectionCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Continuer la série")
                        .font(.headline)
                    Spacer()
                    Text("Prochain épisode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 16) {
                    AsyncImage(url: suggestion.episode.stillURL ?? suggestion.series.posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_), .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "play.rectangle")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 130, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(suggestion.series.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text("\(suggestion.episode.episodeCode) • \(suggestion.episode.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        if let runtime = suggestion.episode.formattedRuntime {
                            Text(runtime)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer(minLength: 0)
                }

                Button(action: onAdd) {
                    Label("Ajouter cet épisode", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Toast de badge débloqué

struct BadgeUnlockToast: View {
    let badge: Badge
    
    var body: some View {
        HStack(spacing: 12) {
            Text(badge.icon)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Nouveau badge !")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(badge.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Bulle de stat

struct StatBubble: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Wrapped mensuel

struct MonthlyWrappedCard: View {
    let stats: MonthlyWrappedStats
    let monthLabel: String
    var shareURL: URL?
    var showsShareButton = false
    var onSizeChange: ((CGSize) -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wrapped du mois")
                        .font(.headline)
                    Text(monthLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    if showsShareButton, let shareURL {
                        ShareLink(item: shareURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("Partager le wrapped")
                    }
                    Image(systemName: "sparkles")
                        .foregroundColor(.accentColor)
                }
            }

            LazyVGrid(columns: columns, spacing: 12) {
                WrappedStatItem(title: "Films", value: "\(stats.moviesCount)", icon: "film.fill", color: .blue)
                WrappedStatItem(title: "Séries", value: "\(stats.seriesCount)", icon: "tv.fill", color: .teal)
                WrappedStatItem(title: "Épisodes", value: "\(stats.episodesCount)", icon: "play.rectangle.fill", color: .indigo)
                WrappedStatItem(title: "Temps total", value: stats.formattedRuntime, icon: "clock.fill", color: .purple)
            }

            if !stats.topGenres.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top genres")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    FlowLayout(spacing: 8) {
                        ForEach(stats.topGenres, id: \.self) { genre in
                            Text(genre)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            onSizeChange?(proxy.size)
                        }
                        .onChange(of: proxy.size) { newSize in
                            onSizeChange?(newSize)
                        }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

struct WrappedStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth, currentRowWidth > 0 {
                totalHeight += currentRowHeight + spacing
                currentRowWidth = 0
                currentRowHeight = 0
            }

            currentRowWidth += size.width + (currentRowWidth == 0 ? 0 : spacing)
            currentRowHeight = max(currentRowHeight, size.height)
        }

        totalHeight += currentRowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Vue des statistiques

struct StatsView: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWrappedMonth = Date()
    @State private var wrappedShareURL: URL?
    @State private var wrappedCardSize: CGSize = .zero

    private var availableWrappedMonths: [Date] {
        watchedViewModel.availableWrappedMonths()
    }

    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Wrapped mensuel") {
                    if availableWrappedMonths.isEmpty {
                        ContentUnavailableView("Aucun mois disponible", systemImage: "calendar.badge.exclamationmark")
                            .listRowBackground(Color.clear)
                    } else {
                        Picker("Mois", selection: $selectedWrappedMonth) {
                            ForEach(availableWrappedMonths, id: \.self) { month in
                                Text(monthFormatter.string(from: month).capitalized)
                                    .tag(month)
                            }
                        }
                        .pickerStyle(.menu)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                        let stats = watchedViewModel.monthlyWrappedStats(for: selectedWrappedMonth)
                        MonthlyWrappedCard(
                            stats: stats,
                            monthLabel: monthFormatter.string(from: stats.monthStart).capitalized,
                            shareURL: wrappedShareURL,
                            showsShareButton: true,
                            onSizeChange: { newSize in
                                if wrappedCardSize != newSize {
                                    wrappedCardSize = newSize
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .onAppear {
                            updateWrappedShareURL(stats: stats)
                        }
                        .onChange(of: selectedWrappedMonth) { newMonth in
                            let newStats = watchedViewModel.monthlyWrappedStats(for: newMonth)
                            updateWrappedShareURL(stats: newStats)
                        }
                        .onChange(of: wrappedCardSize) { _ in
                            let newStats = watchedViewModel.monthlyWrappedStats(for: selectedWrappedMonth)
                            updateWrappedShareURL(stats: newStats)
                        }
                    }
                }

                Section("Vue d'ensemble") {
                    StatRow(icon: "film.fill", title: "Films vus", value: "\(watchedViewModel.stats.totalMovies)", color: .blue)
                    StatRow(icon: "tv.fill", title: "Épisodes vus", value: "\(watchedViewModel.stats.totalEpisodes)", color: .teal)
                    StatRow(icon: "play.rectangle.fill", title: "Total vus", value: "\(watchedViewModel.stats.totalWatched)", color: .indigo)
                    StatRow(icon: "clock.fill", title: "Temps total", value: watchedViewModel.stats.formattedCombinedRuntime, color: .purple)
                    StatRow(icon: "flame.fill", title: "Streak actuel", value: "\(watchedViewModel.stats.currentStreak) jours", color: .orange)
                    StatRow(icon: "trophy.fill", title: "Meilleur streak", value: "\(watchedViewModel.stats.longestStreak) jours", color: .yellow)
                }
                
                Section("Films cette période") {
                    StatRow(icon: "calendar", title: "Cette semaine", value: "\(watchedViewModel.stats.moviesThisWeek) films", color: .green)
                    StatRow(icon: "calendar.badge.clock", title: "Ce mois", value: "\(watchedViewModel.stats.moviesThisMonth) films", color: .teal)
                }
                
                Section("Épisodes cette période") {
                    StatRow(icon: "calendar", title: "Cette semaine", value: "\(watchedViewModel.stats.episodesThisWeek) épisodes", color: .green)
                    StatRow(icon: "calendar.badge.clock", title: "Ce mois", value: "\(watchedViewModel.stats.episodesThisMonth) épisodes", color: .teal)
                }
                
                Section("Genres") {
                    ForEach(watchedViewModel.stats.genreCounts.sorted(by: { $0.value > $1.value }), id: \.key) { genre, count in
                        HStack {
                            Text(BadgeDefinitions.genreEmojis[genre] ?? "🎬")
                            Text(genre)
                            Spacer()
                            Text("\(count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Badges") {
                    StatRow(
                        icon: "star.circle.fill",
                        title: "Badges débloqués",
                        value: "\(watchedViewModel.unlockedBadges.count)/\(watchedViewModel.allBadges.count)",
                        color: .orange
                    )
                    
                    // Répartition par rareté
                    ForEach(BadgeRarity.allCases, id: \.self) { rarity in
                        let count = watchedViewModel.unlockedBadges.filter { $0.rarity == rarity }.count
                        if count > 0 {
                            HStack {
                                Circle()
                                    .fill(rarityColor(rarity))
                                    .frame(width: 12, height: 12)
                                Text(rarity.rawValue)
                                Spacer()
                                Text("\(count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Statistiques")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let firstMonth = availableWrappedMonths.first {
                selectedWrappedMonth = firstMonth
            }
        }
        .onChange(of: availableWrappedMonths) {
            if let firstMonth = availableWrappedMonths.first,
               !availableWrappedMonths.contains(selectedWrappedMonth) {
                selectedWrappedMonth = firstMonth
            }
        }
    }
    
    private func rarityColor(_ rarity: BadgeRarity) -> Color {
        switch rarity.color {
        case "gray": return .gray
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        default: return .gray
        }
    }

    @MainActor
    private func updateWrappedShareURL(stats: MonthlyWrappedStats) {
        guard wrappedCardSize != .zero else { return }
        let monthLabel = monthFormatter.string(from: stats.monthStart).capitalized
        let shareView = MonthlyWrappedCard(
            stats: stats,
            monthLabel: monthLabel,
            shareURL: nil,
            showsShareButton: false,
            onSizeChange: nil
        )
        .frame(width: wrappedCardSize.width, height: wrappedCardSize.height)

        let renderer = ImageRenderer(content: shareView)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = ProposedViewSize(wrappedCardSize)

        guard let image = renderer.uiImage,
              let data = image.jpegData(compressionQuality: 0.9) else {
            return
        }

        let filename = "wrapped-\(stats.monthStart.timeIntervalSince1970).jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            wrappedShareURL = url
        } catch {
            wrappedShareURL = nil
        }
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    CollectionView()
        .environmentObject(WatchedViewModel())
        .environmentObject(InstanceManager())
}
