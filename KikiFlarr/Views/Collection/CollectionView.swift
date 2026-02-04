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
            LazyVStack(alignment: .leading, spacing: 20) {
                CollectionHeroBanner(
                    title: "Ajout rapide",
                    subtitle: "Marquez un film ou une série vue en quelques secondes.",
                    tint: .blue
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

                CollectionSectionHeader(title: "Aperçu")
                CollectionStatsGrid(stats: watchedViewModel.stats)

                CollectionSectionHeader(title: "Films récents")
                LazyVStack(spacing: 12) {
                    ForEach(filteredMovies) { movie in
                        CollectionMovieCard(movie: movie)
                            .contextMenu {
                                Button(role: .destructive) {
                                    watchedViewModel.removeFromWatched(movie)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .searchable(text: $searchText, prompt: "Rechercher un film")
    }
}

// MARK: - Liste des épisodes vus

struct WatchedEpisodesListView: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @EnvironmentObject var instanceManager: InstanceManager
    @State private var searchText = ""
    @State private var continueWatching: [NextEpisodeSuggestion] = []
    @State private var isLoadingContinueWatching = false
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
            LazyVStack(alignment: .leading, spacing: 20) {
                CollectionHeroBanner(
                    title: "Ajout rapide",
                    subtitle: "Ajoutez une série vue et sélectionnez les épisodes en un geste.",
                    tint: .teal
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

                if isLoadingContinueWatching {
                    CollectionSectionHeader(title: "Continuer le visionnage")
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if !continueWatching.isEmpty {
                    CollectionSectionHeader(title: "Continuer le visionnage")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(continueWatching) { suggestion in
                                ContinueWatchingCard(suggestion: suggestion) {
                                    markNextEpisodeAsWatched(suggestion)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }

                CollectionSectionHeader(title: "Aperçu")
                CollectionStatsGrid(stats: watchedViewModel.stats)

                CollectionSectionHeader(title: "Épisodes récents")
                LazyVStack(spacing: 12) {
                    ForEach(filteredEpisodes) { episode in
                        CollectionEpisodeCard(episode: episode)
                            .contextMenu {
                                Button(role: .destructive) {
                                    watchedViewModel.removeFromWatched(episode)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .searchable(text: $searchText, prompt: "Rechercher un épisode ou une série")
        .task(id: watchedViewModel.watchedEpisodes) {
            await loadContinueWatching()
        }
    }

    private func loadContinueWatching() async {
        guard instanceManager.hasTMDBConfigured,
              let service = instanceManager.tmdbService() else {
            continueWatching = []
            return
        }

        isLoadingContinueWatching = true
        defer { isLoadingContinueWatching = false }

        let grouped = Dictionary(grouping: watchedViewModel.watchedEpisodes) { $0.seriesTmdbId }
        let latestEpisodes = grouped.compactMap { $0.value.max(by: { $0.watchedDate < $1.watchedDate }) }
        let sortedLatest = latestEpisodes.sorted { $0.watchedDate > $1.watchedDate }

        var suggestions: [NextEpisodeSuggestion] = []

        for lastEpisode in sortedLatest.prefix(6) {
            if let nextEpisode = await fetchNextEpisode(for: lastEpisode, service: service) {
                suggestions.append(
                    NextEpisodeSuggestion(
                        seriesTmdbId: lastEpisode.seriesTmdbId,
                        seriesTitle: lastEpisode.seriesTitle,
                        seriesPosterURL: lastEpisode.seriesPosterURL,
                        lastEpisode: lastEpisode,
                        nextEpisode: nextEpisode
                    )
                )
            }
        }

        continueWatching = suggestions
    }

    private func fetchNextEpisode(for lastEpisode: WatchedEpisode, service: TMDBService) async -> TMDBEpisode? {
        do {
            let currentSeason = try await service.getSeasonDetails(
                tvId: lastEpisode.seriesTmdbId,
                seasonNumber: lastEpisode.seasonNumber
            )

            if let nextEpisode = currentSeason.episodes?.first(where: { $0.episodeNumber == lastEpisode.episodeNumber + 1 }) {
                return nextEpisode
            }

            let nextSeasonNumber = lastEpisode.seasonNumber + 1
            let nextSeason = try await service.getSeasonDetails(
                tvId: lastEpisode.seriesTmdbId,
                seasonNumber: nextSeasonNumber
            )
            return nextSeason.episodes?.min(by: { $0.episodeNumber < $1.episodeNumber })
        } catch {
            return nil
        }
    }

    private func markNextEpisodeAsWatched(_ suggestion: NextEpisodeSuggestion) {
        let nextEpisode = suggestion.nextEpisode
        let watchedEpisode = WatchedEpisode(
            tmdbId: nextEpisode.id,
            seriesTmdbId: suggestion.seriesTmdbId,
            seriesTitle: suggestion.seriesTitle,
            seriesPosterURL: suggestion.seriesPosterURL,
            seriesTotalEpisodes: suggestion.lastEpisode.seriesTotalEpisodes,
            episodeTitle: nextEpisode.name,
            seasonNumber: nextEpisode.seasonNumber,
            episodeNumber: nextEpisode.episodeNumber,
            runtime: nextEpisode.runtime,
            stillURL: nextEpisode.stillURL?.absoluteString,
            overview: nextEpisode.overview,
            watchedDate: Date(),
            rating: nil,
            notes: nil
        )

        watchedViewModel.addToWatched(watchedEpisode)
        Task {
            await loadContinueWatching()
        }
    }
}

// MARK: - Ligne d'épisode vu

struct WatchedEpisodeRow: View {
    let episode: WatchedEpisode

    var body: some View {
        HStack(spacing: 12) {
            // Poster de la série
            AsyncImage(url: URL(string: episode.seriesPosterURL ?? "")) { phase in
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
            .frame(width: 50, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.seriesTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("S\(episode.seasonNumber)E\(episode.episodeNumber) - \(episode.episodeTitle)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(episode.watchedDate, style: .date)
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                // Note personnelle
                if let rating = episode.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }

            Spacer()

            // Badge "Vu"
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Ligne de film vu

struct WatchedMovieRow: View {
    let movie: WatchedMovie
    
    var body: some View {
        HStack(spacing: 12) {
            // Poster
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
            .frame(width: 50, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text("\(movie.year)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(movie.watchedDate, style: .date)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Note personnelle
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
            
            Spacer()
            
            // Badge "Vu"
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
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

struct CollectionHeroBanner<Content: View>: View {
    let title: String
    let subtitle: String
    let tint: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundColor(tint)
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
                colors: [tint.opacity(0.25), Color(.secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(tint.opacity(0.2), lineWidth: 1)
        )
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
                    colors: [tint.opacity(0.18), tint.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

struct CollectionSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }
}

struct CollectionStatsGrid: View {
    let stats: WatchedStats

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            CollectionMetricCard(
                title: "Films",
                value: "\(stats.totalMovies)",
                systemImage: "film.fill",
                tint: .blue
            )
            CollectionMetricCard(
                title: "Épisodes",
                value: "\(stats.totalEpisodes)",
                systemImage: "tv.fill",
                tint: .teal
            )
            CollectionMetricCard(
                title: "Durée totale",
                value: stats.formattedCombinedRuntime,
                systemImage: "clock.fill",
                tint: .purple
            )
            CollectionMetricCard(
                title: "Streak",
                value: "\(stats.currentStreak)",
                systemImage: "flame.fill",
                tint: .orange
            )
        }
    }
}

struct CollectionMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(tint)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [tint.opacity(0.2), Color(.secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CollectionMovieCard: View {
    let movie: WatchedMovie

    var body: some View {
        HStack(spacing: 12) {
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
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(movie.watchedDate, style: .date)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CollectionEpisodeCard: View {
    let episode: WatchedEpisode

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: episode.seriesPosterURL ?? "")) { phase in
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
            .frame(width: 70, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(episode.seriesTitle)
                    .font(.headline)
                    .lineLimit(1)
                Text(episode.fullTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(episode.watchedDate, style: .date)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ContinueWatchingCard: View {
    let suggestion: NextEpisodeSuggestion
    let onAdd: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: suggestion.nextEpisode.stillURL) { phase in
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
            .frame(width: 280, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            LinearGradient(
                colors: [Color.black.opacity(0.1), Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 6) {
                Text(suggestion.seriesTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("À regarder : \(suggestion.nextEpisodeCode)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                Text(suggestion.nextEpisode.name)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                Button(action: onAdd) {
                    Text("Marquer comme vu")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
            }
            .padding()
        }
        .frame(width: 280, height: 170)
    }
}

struct NextEpisodeSuggestion: Identifiable {
    let id = UUID()
    let seriesTmdbId: Int
    let seriesTitle: String
    let seriesPosterURL: String?
    let lastEpisode: WatchedEpisode
    let nextEpisode: TMDBEpisode

    var nextEpisodeCode: String {
        String(format: "S%02dE%02d", nextEpisode.seasonNumber, nextEpisode.episodeNumber)
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
