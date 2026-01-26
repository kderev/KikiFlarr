import Foundation

// MARK: - Film vu

struct WatchedMovie: Codable, Identifiable, Equatable {
    let id: UUID
    let tmdbId: Int
    let radarrId: Int?
    let title: String
    let year: Int
    let posterURL: String?
    let fanartURL: String?
    let genres: [String]
    let runtime: Int?
    let watchedDate: Date
    let rating: Int? // Note personnelle 1-5
    let notes: String?
    
    init(
        id: UUID = UUID(),
        tmdbId: Int,
        radarrId: Int? = nil,
        title: String,
        year: Int,
        posterURL: String? = nil,
        fanartURL: String? = nil,
        genres: [String] = [],
        runtime: Int? = nil,
        watchedDate: Date = Date(),
        rating: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.tmdbId = tmdbId
        self.radarrId = radarrId
        self.title = title
        self.year = year
        self.posterURL = posterURL
        self.fanartURL = fanartURL
        self.genres = genres
        self.runtime = runtime
        self.watchedDate = watchedDate
        self.rating = rating
        self.notes = notes
    }
    
    static func from(movie: RadarrMovie) -> WatchedMovie {
        WatchedMovie(
            tmdbId: movie.tmdbId ?? 0,
            radarrId: movie.id,
            title: movie.title,
            year: movie.year,
            posterURL: movie.posterURL?.absoluteString,
            fanartURL: movie.fanartURL?.absoluteString,
            genres: movie.genres ?? [],
            runtime: movie.runtime,
            watchedDate: Date()
        )
    }
}

// MARK: - Série vue

struct WatchedSeries: Codable, Identifiable, Equatable {
    let id: UUID
    let tvdbId: Int
    let sonarrId: Int?
    let title: String
    let year: Int
    let posterURL: String?
    let fanartURL: String?
    let genres: [String]
    let totalEpisodes: Int
    let watchedEpisodes: Int
    let watchedDate: Date
    let rating: Int?
    let notes: String?
    
    init(
        id: UUID = UUID(),
        tvdbId: Int,
        sonarrId: Int? = nil,
        title: String,
        year: Int,
        posterURL: String? = nil,
        fanartURL: String? = nil,
        genres: [String] = [],
        totalEpisodes: Int = 0,
        watchedEpisodes: Int = 0,
        watchedDate: Date = Date(),
        rating: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.tvdbId = tvdbId
        self.sonarrId = sonarrId
        self.title = title
        self.year = year
        self.posterURL = posterURL
        self.fanartURL = fanartURL
        self.genres = genres
        self.totalEpisodes = totalEpisodes
        self.watchedEpisodes = watchedEpisodes
        self.watchedDate = watchedDate
        self.rating = rating
        self.notes = notes
    }
    
    var isCompleted: Bool {
        totalEpisodes > 0 && watchedEpisodes >= totalEpisodes
    }
    
    static func from(series: SonarrSeries) -> WatchedSeries {
        WatchedSeries(
            tvdbId: series.tvdbId ?? 0,
            sonarrId: series.id,
            title: series.title,
            year: series.year,
            posterURL: series.posterURL?.absoluteString,
            fanartURL: series.fanartURL?.absoluteString,
            genres: series.genres ?? [],
            totalEpisodes: series.statistics?.totalEpisodeCount ?? 0,
            watchedEpisodes: series.statistics?.episodeCount ?? 0,
            watchedDate: Date()
        )
    }
}

// MARK: - Épisode vu

struct WatchedEpisode: Codable, Identifiable, Equatable {
    let id: UUID
    let tmdbId: Int // ID de l'épisode TMDB
    let seriesTmdbId: Int // ID de la série TMDB
    let seriesTitle: String
    let seriesPosterURL: String?
    let seriesTotalEpisodes: Int? // Nombre total d'épisodes de la série
    let episodeTitle: String
    let seasonNumber: Int
    let episodeNumber: Int
    let runtime: Int? // en minutes
    let stillURL: String? // Image de l'épisode
    let overview: String?
    let watchedDate: Date
    let rating: Int?
    let notes: String?
    
    init(
        id: UUID = UUID(),
        tmdbId: Int,
        seriesTmdbId: Int,
        seriesTitle: String,
        seriesPosterURL: String? = nil,
        seriesTotalEpisodes: Int? = nil,
        episodeTitle: String,
        seasonNumber: Int,
        episodeNumber: Int,
        runtime: Int? = nil,
        stillURL: String? = nil,
        overview: String? = nil,
        watchedDate: Date = Date(),
        rating: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.tmdbId = tmdbId
        self.seriesTmdbId = seriesTmdbId
        self.seriesTitle = seriesTitle
        self.seriesPosterURL = seriesPosterURL
        self.seriesTotalEpisodes = seriesTotalEpisodes
        self.episodeTitle = episodeTitle
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.runtime = runtime
        self.stillURL = stillURL
        self.overview = overview
        self.watchedDate = watchedDate
        self.rating = rating
        self.notes = notes
    }
    
    var episodeCode: String {
        String(format: "S%02dE%02d", seasonNumber, episodeNumber)
    }
    
    var fullTitle: String {
        "\(episodeCode) - \(episodeTitle)"
    }
    
    var formattedRuntime: String? {
        guard let runtime = runtime, runtime > 0 else { return nil }
        if runtime >= 60 {
            return "\(runtime / 60)h \(runtime % 60)min"
        }
        return "\(runtime) min"
    }
}

// MARK: - Badges

enum BadgeCategory: String, Codable, CaseIterable {
    case collector = "Collectionneur"
    case seriesCollector = "Collectionneur Séries"
    case genre = "Genre"
    case marathon = "Marathon"
    case dedication = "Dévotion"
    case special = "Spécial"
    
    var icon: String {
        switch self {
        case .collector: return "star.circle.fill"
        case .seriesCollector: return "tv.circle.fill"
        case .genre: return "theatermasks.fill"
        case .marathon: return "flame.fill"
        case .dedication: return "heart.fill"
        case .special: return "sparkles"
        }
    }
    
    var color: String {
        switch self {
        case .collector: return "gold"
        case .seriesCollector: return "teal"
        case .genre: return "purple"
        case .marathon: return "orange"
        case .dedication: return "red"
        case .special: return "blue"
        }
    }
}

enum BadgeRarity: String, Codable, CaseIterable {
    case common = "Commun"
    case uncommon = "Peu commun"
    case rare = "Rare"
    case epic = "Épique"
    case legendary = "Légendaire"
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .uncommon: return "green"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
    
    var glowIntensity: Double {
        switch self {
        case .common: return 0
        case .uncommon: return 0.2
        case .rare: return 0.4
        case .epic: return 0.6
        case .legendary: return 0.8
        }
    }
}

struct Badge: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: BadgeCategory
    let rarity: BadgeRarity
    let requirement: Int
    let unlockedDate: Date?
    
    var isUnlocked: Bool {
        unlockedDate != nil
    }
    
    // Créer une version débloquée du badge
    func unlocked(at date: Date = Date()) -> Badge {
        Badge(
            id: id,
            name: name,
            description: description,
            icon: icon,
            category: category,
            rarity: rarity,
            requirement: requirement,
            unlockedDate: date
        )
    }
}

// MARK: - Définitions des badges

struct BadgeDefinitions {
    
    // MARK: - Badges Collectionneur (basés sur le nombre total de films)
    
    static let collectorBadges: [Badge] = [
        Badge(
            id: "first_movie",
            name: "Premier Pas",
            description: "Regarder votre premier film",
            icon: "🎬",
            category: .collector,
            rarity: .common,
            requirement: 1,
            unlockedDate: nil
        ),
        Badge(
            id: "movies_5",
            name: "Novice",
            description: "Regarder 5 films",
            icon: "🌱",
            category: .collector,
            rarity: .common,
            requirement: 5,
            unlockedDate: nil
        ),
        Badge(
            id: "movies_10",
            name: "Amateur",
            description: "Regarder 10 films",
            icon: "🎞️",
            category: .collector,
            rarity: .common,
            requirement: 10,
            unlockedDate: nil
        ),
        Badge(
            id: "movies_25",
            name: "Passionné",
            description: "Regarder 25 films",
            icon: "🍿",
            category: .collector,
            rarity: .uncommon,
            requirement: 25,
            unlockedDate: nil
        ),
        Badge(
            id: "movies_50",
            name: "Cinéphile",
            description: "Regarder 50 films",
            icon: "🎥",
            category: .collector,
            rarity: .uncommon,
            requirement: 50,
            unlockedDate: nil
        ),
        Badge(
            id: "movies_100",
            name: "Expert",
            description: "Regarder 100 films",
            icon: "🏆",
            category: .collector,
            rarity: .rare,
            requirement: 100,
            unlockedDate: nil
        ),
        Badge(
            id: "movies_250",
            name: "Maître",
            description: "Regarder 250 films",
            icon: "👑",
            category: .collector,
            rarity: .epic,
            requirement: 250,
            unlockedDate: nil
        ),
        Badge(
            id: "movies_500",
            name: "Légende",
            description: "Regarder 500 films",
            icon: "⭐",
            category: .collector,
            rarity: .epic,
            requirement: 500,
            unlockedDate: nil
        ),
        Badge(
            id: "movies_1000",
            name: "Dieu du Cinéma",
            description: "Regarder 1000 films",
            icon: "🌟",
            category: .collector,
            rarity: .legendary,
            requirement: 1000,
            unlockedDate: nil
        )
    ]
    
    // MARK: - Badges Genre
    
    static func genreBadges(for genre: String) -> [Badge] {
        let genreEmoji = genreEmojis[genre] ?? "🎭"
        return [
            Badge(
                id: "genre_\(genre.lowercased())_5",
                name: "Fan de \(genre)",
                description: "Regarder 5 films \(genre)",
                icon: genreEmoji,
                category: .genre,
                rarity: .common,
                requirement: 5,
                unlockedDate: nil
            ),
            Badge(
                id: "genre_\(genre.lowercased())_15",
                name: "Amateur de \(genre)",
                description: "Regarder 15 films \(genre)",
                icon: genreEmoji,
                category: .genre,
                rarity: .uncommon,
                requirement: 15,
                unlockedDate: nil
            ),
            Badge(
                id: "genre_\(genre.lowercased())_30",
                name: "Expert \(genre)",
                description: "Regarder 30 films \(genre)",
                icon: genreEmoji,
                category: .genre,
                rarity: .rare,
                requirement: 30,
                unlockedDate: nil
            ),
            Badge(
                id: "genre_\(genre.lowercased())_50",
                name: "Maître \(genre)",
                description: "Regarder 50 films \(genre)",
                icon: genreEmoji,
                category: .genre,
                rarity: .epic,
                requirement: 50,
                unlockedDate: nil
            )
        ]
    }
    
    static let genreEmojis: [String: String] = [
        "Action": "💥",
        "Adventure": "🗺️",
        "Animation": "🎨",
        "Comedy": "😂",
        "Crime": "🔪",
        "Documentary": "📹",
        "Drama": "🎭",
        "Family": "👨‍👩‍👧‍👦",
        "Fantasy": "🧙‍♂️",
        "History": "📜",
        "Horror": "👻",
        "Music": "🎵",
        "Mystery": "🔍",
        "Romance": "💕",
        "Science Fiction": "🚀",
        "Sci-Fi": "🚀",
        "TV Movie": "📺",
        "Thriller": "😱",
        "War": "⚔️",
        "Western": "🤠"
    ]
    
    // MARK: - Badges Marathon (films regardés en peu de temps)
    
    static let marathonBadges: [Badge] = [
        Badge(
            id: "marathon_day_2",
            name: "Double Feature",
            description: "Regarder 2 films en un jour",
            icon: "🎪",
            category: .marathon,
            rarity: .common,
            requirement: 2,
            unlockedDate: nil
        ),
        Badge(
            id: "marathon_day_3",
            name: "Triple Menace",
            description: "Regarder 3 films en un jour",
            icon: "🔥",
            category: .marathon,
            rarity: .uncommon,
            requirement: 3,
            unlockedDate: nil
        ),
        Badge(
            id: "marathon_day_5",
            name: "Machine à Pop-corn",
            description: "Regarder 5 films en un jour",
            icon: "🏃‍♂️",
            category: .marathon,
            rarity: .rare,
            requirement: 5,
            unlockedDate: nil
        ),
        Badge(
            id: "marathon_week_10",
            name: "Semaine Intense",
            description: "Regarder 10 films en une semaine",
            icon: "📅",
            category: .marathon,
            rarity: .uncommon,
            requirement: 10,
            unlockedDate: nil
        ),
        Badge(
            id: "marathon_week_20",
            name: "Obsédé du Cinéma",
            description: "Regarder 20 films en une semaine",
            icon: "🤯",
            category: .marathon,
            rarity: .epic,
            requirement: 20,
            unlockedDate: nil
        )
    ]
    
    // MARK: - Badges Dévotion (streak)
    
    static let dedicationBadges: [Badge] = [
        Badge(
            id: "streak_3",
            name: "Début de série",
            description: "Regarder des films 3 jours de suite",
            icon: "🔗",
            category: .dedication,
            rarity: .common,
            requirement: 3,
            unlockedDate: nil
        ),
        Badge(
            id: "streak_7",
            name: "Semaine parfaite",
            description: "Regarder des films 7 jours de suite",
            icon: "📆",
            category: .dedication,
            rarity: .uncommon,
            requirement: 7,
            unlockedDate: nil
        ),
        Badge(
            id: "streak_14",
            name: "Deux semaines",
            description: "Regarder des films 14 jours de suite",
            icon: "💪",
            category: .dedication,
            rarity: .rare,
            requirement: 14,
            unlockedDate: nil
        ),
        Badge(
            id: "streak_30",
            name: "Mois complet",
            description: "Regarder des films 30 jours de suite",
            icon: "🌙",
            category: .dedication,
            rarity: .epic,
            requirement: 30,
            unlockedDate: nil
        ),
        Badge(
            id: "streak_100",
            name: "Centurion",
            description: "Regarder des films 100 jours de suite",
            icon: "🏛️",
            category: .dedication,
            rarity: .legendary,
            requirement: 100,
            unlockedDate: nil
        )
    ]
    
    // MARK: - Badges Spéciaux
    
    static let specialBadges: [Badge] = [
        Badge(
            id: "night_owl",
            name: "Noctambule",
            description: "Regarder un film après minuit",
            icon: "🦉",
            category: .special,
            rarity: .uncommon,
            requirement: 1,
            unlockedDate: nil
        ),
        Badge(
            id: "early_bird",
            name: "Lève-tôt",
            description: "Regarder un film avant 7h du matin",
            icon: "🐦",
            category: .special,
            rarity: .uncommon,
            requirement: 1,
            unlockedDate: nil
        ),
        Badge(
            id: "weekend_warrior",
            name: "Guerrier du Weekend",
            description: "Regarder 5 films un weekend",
            icon: "⚔️",
            category: .special,
            rarity: .rare,
            requirement: 5,
            unlockedDate: nil
        ),
        Badge(
            id: "variety_lover",
            name: "Éclectique",
            description: "Regarder des films de 10 genres différents",
            icon: "🌈",
            category: .special,
            rarity: .rare,
            requirement: 10,
            unlockedDate: nil
        ),
        Badge(
            id: "genre_master",
            name: "Maître des Genres",
            description: "Regarder des films de tous les genres",
            icon: "🎓",
            category: .special,
            rarity: .legendary,
            requirement: 15,
            unlockedDate: nil
        ),
        Badge(
            id: "long_movie",
            name: "Endurant",
            description: "Regarder un film de plus de 3 heures",
            icon: "⏱️",
            category: .special,
            rarity: .uncommon,
            requirement: 180,
            unlockedDate: nil
        ),
        Badge(
            id: "classic_lover",
            name: "Classique",
            description: "Regarder 10 films d'avant 1980",
            icon: "📽️",
            category: .special,
            rarity: .rare,
            requirement: 10,
            unlockedDate: nil
        ),
        Badge(
            id: "modern_fan",
            name: "Contemporain",
            description: "Regarder 10 films de l'année en cours",
            icon: "🆕",
            category: .special,
            rarity: .rare,
            requirement: 10,
            unlockedDate: nil
        )
    ]
    
    // MARK: - Badges Collectionneur Séries (basés sur le nombre total de séries)
    
    static let seriesCollectorBadges: [Badge] = [
        Badge(
            id: "first_series",
            name: "Première Série",
            description: "Regarder votre première série",
            icon: "📺",
            category: .seriesCollector,
            rarity: .common,
            requirement: 1,
            unlockedDate: nil
        ),
        Badge(
            id: "series_5",
            name: "Spectateur",
            description: "Regarder 5 séries",
            icon: "🎬",
            category: .seriesCollector,
            rarity: .common,
            requirement: 5,
            unlockedDate: nil
        ),
        Badge(
            id: "series_10",
            name: "Sériephile",
            description: "Regarder 10 séries",
            icon: "📡",
            category: .seriesCollector,
            rarity: .common,
            requirement: 10,
            unlockedDate: nil
        ),
        Badge(
            id: "series_25",
            name: "Accro aux Séries",
            description: "Regarder 25 séries",
            icon: "🛋️",
            category: .seriesCollector,
            rarity: .uncommon,
            requirement: 25,
            unlockedDate: nil
        ),
        Badge(
            id: "series_50",
            name: "Marathonien TV",
            description: "Regarder 50 séries",
            icon: "🏃",
            category: .seriesCollector,
            rarity: .uncommon,
            requirement: 50,
            unlockedDate: nil
        ),
        Badge(
            id: "series_100",
            name: "Expert TV",
            description: "Regarder 100 séries",
            icon: "🎖️",
            category: .seriesCollector,
            rarity: .rare,
            requirement: 100,
            unlockedDate: nil
        ),
        Badge(
            id: "series_250",
            name: "Maître des Séries",
            description: "Regarder 250 séries",
            icon: "👑",
            category: .seriesCollector,
            rarity: .epic,
            requirement: 250,
            unlockedDate: nil
        ),
        Badge(
            id: "series_500",
            name: "Légende TV",
            description: "Regarder 500 séries",
            icon: "🌟",
            category: .seriesCollector,
            rarity: .legendary,
            requirement: 500,
            unlockedDate: nil
        )
    ]
    
    // MARK: - Badges Séries Spéciaux
    
    static let seriesSpecialBadges: [Badge] = [
        Badge(
            id: "series_binger",
            name: "Binge Watcher",
            description: "Terminer une série complète",
            icon: "🔥",
            category: .seriesCollector,
            rarity: .uncommon,
            requirement: 1,
            unlockedDate: nil
        ),
        Badge(
            id: "series_binger_5",
            name: "Binger Pro",
            description: "Terminer 5 séries complètes",
            icon: "⚡",
            category: .seriesCollector,
            rarity: .rare,
            requirement: 5,
            unlockedDate: nil
        ),
        Badge(
            id: "series_binger_20",
            name: "Binger Ultime",
            description: "Terminer 20 séries complètes",
            icon: "💫",
            category: .seriesCollector,
            rarity: .epic,
            requirement: 20,
            unlockedDate: nil
        ),
        Badge(
            id: "series_long",
            name: "Longue Haleine",
            description: "Regarder une série de plus de 100 épisodes",
            icon: "📚",
            category: .seriesCollector,
            rarity: .rare,
            requirement: 100,
            unlockedDate: nil
        ),
        Badge(
            id: "series_classic",
            name: "Nostalgique",
            description: "Regarder 5 séries d'avant 2000",
            icon: "📼",
            category: .seriesCollector,
            rarity: .uncommon,
            requirement: 5,
            unlockedDate: nil
        ),
        Badge(
            id: "series_modern",
            name: "Tendance",
            description: "Regarder 10 séries de l'année en cours",
            icon: "✨",
            category: .seriesCollector,
            rarity: .rare,
            requirement: 10,
            unlockedDate: nil
        ),
        Badge(
            id: "series_genre_variety",
            name: "Éclectique TV",
            description: "Regarder des séries de 8 genres différents",
            icon: "🌈",
            category: .seriesCollector,
            rarity: .rare,
            requirement: 8,
            unlockedDate: nil
        )
    ]
    
    // MARK: - Badges Genre Séries
    
    static func seriesGenreBadges(for genre: String) -> [Badge] {
        let genreEmoji = genreEmojis[genre] ?? "📺"
        return [
            Badge(
                id: "series_genre_\(genre.lowercased())_3",
                name: "Fan de \(genre) TV",
                description: "Regarder 3 séries \(genre)",
                icon: genreEmoji,
                category: .seriesCollector,
                rarity: .common,
                requirement: 3,
                unlockedDate: nil
            ),
            Badge(
                id: "series_genre_\(genre.lowercased())_10",
                name: "Expert \(genre) TV",
                description: "Regarder 10 séries \(genre)",
                icon: genreEmoji,
                category: .seriesCollector,
                rarity: .uncommon,
                requirement: 10,
                unlockedDate: nil
            ),
            Badge(
                id: "series_genre_\(genre.lowercased())_25",
                name: "Maître \(genre) TV",
                description: "Regarder 25 séries \(genre)",
                icon: genreEmoji,
                category: .seriesCollector,
                rarity: .rare,
                requirement: 25,
                unlockedDate: nil
            )
        ]
    }
    
    // MARK: - Badges Épisodes (basés sur le nombre d'épisodes vus)
    
    static let episodeCollectorBadges: [Badge] = [
        Badge(
            id: "first_episode",
            name: "Premier Épisode",
            description: "Regarder votre premier épisode",
            icon: "▶️",
            category: .seriesCollector,
            rarity: .common,
            requirement: 1,
            unlockedDate: nil
        ),
        Badge(
            id: "episodes_10",
            name: "Spectateur Régulier",
            description: "Regarder 10 épisodes",
            icon: "📺",
            category: .seriesCollector,
            rarity: .common,
            requirement: 10,
            unlockedDate: nil
        ),
        Badge(
            id: "episodes_50",
            name: "Binge Watcher",
            description: "Regarder 50 épisodes",
            icon: "🎬",
            category: .seriesCollector,
            rarity: .uncommon,
            requirement: 50,
            unlockedDate: nil
        ),
        Badge(
            id: "episodes_100",
            name: "Marathonien TV",
            description: "Regarder 100 épisodes",
            icon: "🏃",
            category: .seriesCollector,
            rarity: .uncommon,
            requirement: 100,
            unlockedDate: nil
        ),
        Badge(
            id: "episodes_250",
            name: "Expert Épisodes",
            description: "Regarder 250 épisodes",
            icon: "🎖️",
            category: .seriesCollector,
            rarity: .rare,
            requirement: 250,
            unlockedDate: nil
        ),
        Badge(
            id: "episodes_500",
            name: "Maître des Épisodes",
            description: "Regarder 500 épisodes",
            icon: "👑",
            category: .seriesCollector,
            rarity: .epic,
            requirement: 500,
            unlockedDate: nil
        ),
        Badge(
            id: "episodes_1000",
            name: "Légende des Séries",
            description: "Regarder 1000 épisodes",
            icon: "🌟",
            category: .seriesCollector,
            rarity: .legendary,
            requirement: 1000,
            unlockedDate: nil
        )
    ]
    
    // MARK: - Badges Total (films + épisodes combinés)
    
    static let totalWatchedBadges: [Badge] = [
        Badge(
            id: "total_50",
            name: "Cinéphile Débutant",
            description: "Regarder 50 contenus (films + épisodes)",
            icon: "🎯",
            category: .collector,
            rarity: .common,
            requirement: 50,
            unlockedDate: nil
        ),
        Badge(
            id: "total_100",
            name: "Amateur Confirmé",
            description: "Regarder 100 contenus (films + épisodes)",
            icon: "🎪",
            category: .collector,
            rarity: .uncommon,
            requirement: 100,
            unlockedDate: nil
        ),
        Badge(
            id: "total_250",
            name: "Passionné",
            description: "Regarder 250 contenus (films + épisodes)",
            icon: "🎭",
            category: .collector,
            rarity: .rare,
            requirement: 250,
            unlockedDate: nil
        ),
        Badge(
            id: "total_500",
            name: "Accro Total",
            description: "Regarder 500 contenus (films + épisodes)",
            icon: "💎",
            category: .collector,
            rarity: .epic,
            requirement: 500,
            unlockedDate: nil
        ),
        Badge(
            id: "total_1000",
            name: "Maître Absolu",
            description: "Regarder 1000 contenus (films + épisodes)",
            icon: "🏆",
            category: .collector,
            rarity: .legendary,
            requirement: 1000,
            unlockedDate: nil
        )
    ]
    
    // MARK: - Tous les badges de base
    
    static var allBaseBadges: [Badge] {
        var badges = collectorBadges + seriesCollectorBadges + seriesSpecialBadges + episodeCollectorBadges + totalWatchedBadges + marathonBadges + dedicationBadges + specialBadges
        
        // Ajouter les badges de genre pour les genres principaux (films)
        let mainGenres = ["Action", "Comedy", "Drama", "Horror", "Science Fiction", "Thriller", "Animation", "Romance"]
        for genre in mainGenres {
            badges.append(contentsOf: genreBadges(for: genre))
        }
        
        // Ajouter les badges de genre pour les séries
        for genre in mainGenres {
            badges.append(contentsOf: seriesGenreBadges(for: genre))
        }
        
        return badges
    }
}

// MARK: - Statistiques utilisateur

struct WatchedStats: Codable {
    var totalMovies: Int = 0
    var totalRuntime: Int = 0 // en minutes
    var genreCounts: [String: Int] = [:]
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastWatchedDate: Date?
    var moviesThisWeek: Int = 0
    var moviesThisMonth: Int = 0
    var uniqueGenres: Set<String> = []
    
    // Statistiques séries
    var totalSeries: Int = 0
    var completedSeries: Int = 0
    var seriesGenreCounts: [String: Int] = [:]
    var uniqueSeriesGenres: Set<String> = []
    var seriesThisWeek: Int = 0
    var seriesThisMonth: Int = 0
    
    // Statistiques épisodes
    var totalEpisodes: Int = 0
    var episodesRuntime: Int = 0 // en minutes
    var episodesThisWeek: Int = 0
    var episodesThisMonth: Int = 0
    
    // Total global (films + épisodes)
    var totalWatched: Int {
        totalMovies + totalEpisodes
    }
    
    var totalCombinedRuntime: Int {
        totalRuntime + episodesRuntime
    }
    
    var formattedTotalRuntime: String {
        let hours = totalRuntime / 60
        let days = hours / 24
        if days > 0 {
            return "\(days) jours, \(hours % 24)h"
        } else {
            return "\(hours)h \(totalRuntime % 60)min"
        }
    }
    
    var formattedEpisodesRuntime: String {
        let hours = episodesRuntime / 60
        let days = hours / 24
        if days > 0 {
            return "\(days)j \(hours % 24)h"
        } else {
            return "\(hours)h \(episodesRuntime % 60)min"
        }
    }
    
    var formattedCombinedRuntime: String {
        let totalMinutes = totalRuntime + episodesRuntime
        let hours = totalMinutes / 60
        let days = hours / 24
        if days > 0 {
            return "\(days) jours, \(hours % 24)h"
        } else {
            return "\(hours)h \(totalMinutes % 60)min"
        }
    }
    
    // MARK: - Décodage rétrocompatible
    
    enum CodingKeys: String, CodingKey {
        case totalMovies, totalRuntime, genreCounts, currentStreak, longestStreak
        case lastWatchedDate, moviesThisWeek, moviesThisMonth, uniqueGenres
        case totalSeries, completedSeries, seriesGenreCounts, uniqueSeriesGenres
        case seriesThisWeek, seriesThisMonth
        case totalEpisodes, episodesRuntime, episodesThisWeek, episodesThisMonth
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Propriétés originales
        totalMovies = try container.decodeIfPresent(Int.self, forKey: .totalMovies) ?? 0
        totalRuntime = try container.decodeIfPresent(Int.self, forKey: .totalRuntime) ?? 0
        genreCounts = try container.decodeIfPresent([String: Int].self, forKey: .genreCounts) ?? [:]
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        lastWatchedDate = try container.decodeIfPresent(Date.self, forKey: .lastWatchedDate)
        moviesThisWeek = try container.decodeIfPresent(Int.self, forKey: .moviesThisWeek) ?? 0
        moviesThisMonth = try container.decodeIfPresent(Int.self, forKey: .moviesThisMonth) ?? 0
        uniqueGenres = try container.decodeIfPresent(Set<String>.self, forKey: .uniqueGenres) ?? []
        
        // Propriétés séries
        totalSeries = try container.decodeIfPresent(Int.self, forKey: .totalSeries) ?? 0
        completedSeries = try container.decodeIfPresent(Int.self, forKey: .completedSeries) ?? 0
        seriesGenreCounts = try container.decodeIfPresent([String: Int].self, forKey: .seriesGenreCounts) ?? [:]
        uniqueSeriesGenres = try container.decodeIfPresent(Set<String>.self, forKey: .uniqueSeriesGenres) ?? []
        seriesThisWeek = try container.decodeIfPresent(Int.self, forKey: .seriesThisWeek) ?? 0
        seriesThisMonth = try container.decodeIfPresent(Int.self, forKey: .seriesThisMonth) ?? 0
        
        // Nouvelles propriétés épisodes (avec valeurs par défaut si absentes)
        totalEpisodes = try container.decodeIfPresent(Int.self, forKey: .totalEpisodes) ?? 0
        episodesRuntime = try container.decodeIfPresent(Int.self, forKey: .episodesRuntime) ?? 0
        episodesThisWeek = try container.decodeIfPresent(Int.self, forKey: .episodesThisWeek) ?? 0
        episodesThisMonth = try container.decodeIfPresent(Int.self, forKey: .episodesThisMonth) ?? 0
    }
}

// MARK: - Wrapped mensuel

struct MonthlyWrappedStats: Identifiable {
    let id: Date
    let monthStart: Date
    let moviesCount: Int
    let seriesCount: Int
    let episodesCount: Int
    let totalRuntimeMinutes: Int
    let topGenres: [String]
    
    var totalWatched: Int {
        moviesCount + episodesCount
    }
    
    var formattedRuntime: String {
        let hours = totalRuntimeMinutes / 60
        let days = hours / 24
        if days > 0 {
            return "\(days) jours, \(hours % 24)h"
        } else {
            return "\(hours)h \(totalRuntimeMinutes % 60)min"
        }
    }
}
