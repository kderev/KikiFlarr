import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @EnvironmentObject var instanceManager: InstanceManager
    @State private var selectedTab: CollectionTab = .movies
    @State private var showStats = false
    @State private var showTMDBSearch = false
    
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
                        WatchedMoviesListView()
                    case .episodes:
                        WatchedEpisodesListView()
                    case .badges:
                        BadgesGridView()
                    }
                }
            }
            .navigationTitle("Ma Collection")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if instanceManager.hasTMDBConfigured && selectedTab == .movies {
                        Button {
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
                TMDBSearchView()
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
                Text("Appuyez sur + pour rechercher et ajouter des films")
            } else {
                Text("Marquez des films comme vus depuis votre bibliothèque ou configurez TMDB dans les paramètres pour rechercher des films")
            }
        }
    }
    
    private var moviesList: some View {
        List {
            // Stats rapides
            Section {
                VStack(spacing: 12) {
                    // Première ligne : Films, Épisodes, Total
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
                    
                    // Deuxième ligne : Durée totale et Streak
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
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            }
            
            // Liste des films
            Section("Films récents") {
                ForEach(filteredMovies) { movie in
                    WatchedMovieRow(movie: movie)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                watchedViewModel.removeFromWatched(movie)
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Rechercher un film")
    }
}

// MARK: - Liste des épisodes vus

struct WatchedEpisodesListView: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @State private var searchText = ""

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
            Text("Marquez des épisodes comme vus depuis votre bibliothèque de séries")
        }
    }

    private var episodesList: some View {
        List {
            // Stats rapides
            Section {
                VStack(spacing: 12) {
                    // Première ligne : Films, Épisodes, Total
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

                    // Deuxième ligne : Durée totale et Streak
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
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            }

            // Liste des épisodes
            Section("Épisodes récents") {
                ForEach(filteredEpisodes) { episode in
                    WatchedEpisodeRow(episode: episode)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                watchedViewModel.removeFromWatched(episode)
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Rechercher un épisode ou une série")
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

// MARK: - Vue des statistiques

struct StatsView: View {
    @EnvironmentObject var watchedViewModel: WatchedViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
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
