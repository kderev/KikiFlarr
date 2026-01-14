import Foundation

class WatchedStorageService {
    static let shared = WatchedStorageService()
    
    private let watchedMoviesKey = "watchedMovies"
    private let watchedSeriesKey = "watchedSeries"
    private let watchedEpisodesKey = "watchedEpisodes"
    private let unlockedBadgesKey = "unlockedBadges"
    private let statsKey = "watchedStats"
    
    /// Queue de synchronisation pour les accès thread-safe
    private let queue = DispatchQueue(label: "com.kikiflarr.watchedstorage", qos: .userInitiated)
    
    private init() {}
    
    // MARK: - Films vus
    
    func loadWatchedMovies() -> [WatchedMovie] {
        guard let data = UserDefaults.standard.data(forKey: watchedMoviesKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([WatchedMovie].self, from: data)
        } catch {
            print("Erreur lors du chargement des films vus: \(error)")
            return []
        }
    }
    
    func saveWatchedMovies(_ movies: [WatchedMovie]) {
        do {
            let data = try JSONEncoder().encode(movies)
            UserDefaults.standard.set(data, forKey: watchedMoviesKey)
        } catch {
            print("Erreur lors de la sauvegarde des films vus: \(error)")
        }
    }
    
    func addWatchedMovie(_ movie: WatchedMovie) -> [WatchedMovie] {
        var movies = loadWatchedMovies()
        
        // Vérifier si le film n'est pas déjà dans la liste
        if !movies.contains(where: { $0.tmdbId == movie.tmdbId }) {
            movies.insert(movie, at: 0)
            saveWatchedMovies(movies)
        }
        
        return movies
    }
    
    func removeWatchedMovie(_ movie: WatchedMovie) -> [WatchedMovie] {
        var movies = loadWatchedMovies()
        movies.removeAll { $0.id == movie.id }
        saveWatchedMovies(movies)
        return movies
    }
    
    func updateWatchedMovie(_ movie: WatchedMovie) -> [WatchedMovie] {
        var movies = loadWatchedMovies()
        if let index = movies.firstIndex(where: { $0.id == movie.id }) {
            movies[index] = movie
            saveWatchedMovies(movies)
        }
        return movies
    }
    
    func isMovieWatched(tmdbId: Int) -> Bool {
        let movies = loadWatchedMovies()
        return movies.contains { $0.tmdbId == tmdbId }
    }
    
    // MARK: - Séries vues
    
    func loadWatchedSeries() -> [WatchedSeries] {
        guard let data = UserDefaults.standard.data(forKey: watchedSeriesKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([WatchedSeries].self, from: data)
        } catch {
            print("Erreur lors du chargement des séries vues: \(error)")
            return []
        }
    }
    
    func saveWatchedSeries(_ series: [WatchedSeries]) {
        do {
            let data = try JSONEncoder().encode(series)
            UserDefaults.standard.set(data, forKey: watchedSeriesKey)
        } catch {
            print("Erreur lors de la sauvegarde des séries vues: \(error)")
        }
    }
    
    func addWatchedSeries(_ series: WatchedSeries) -> [WatchedSeries] {
        var allSeries = loadWatchedSeries()
        
        if !allSeries.contains(where: { $0.tvdbId == series.tvdbId }) {
            allSeries.insert(series, at: 0)
            saveWatchedSeries(allSeries)
        }
        
        return allSeries
    }
    
    func removeWatchedSeries(_ series: WatchedSeries) -> [WatchedSeries] {
        var allSeries = loadWatchedSeries()
        allSeries.removeAll { $0.id == series.id }
        saveWatchedSeries(allSeries)
        return allSeries
    }
    
    func updateWatchedSeries(_ series: WatchedSeries) -> [WatchedSeries] {
        var allSeries = loadWatchedSeries()
        if let index = allSeries.firstIndex(where: { $0.id == series.id }) {
            allSeries[index] = series
            saveWatchedSeries(allSeries)
        }
        return allSeries
    }
    
    func isSeriesWatched(tvdbId: Int) -> Bool {
        let series = loadWatchedSeries()
        return series.contains { $0.tvdbId == tvdbId }
    }
    
    // MARK: - Épisodes vus
    
    func loadWatchedEpisodes() -> [WatchedEpisode] {
        guard let data = UserDefaults.standard.data(forKey: watchedEpisodesKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([WatchedEpisode].self, from: data)
        } catch {
            print("Erreur lors du chargement des épisodes vus: \(error)")
            return []
        }
    }
    
    func saveWatchedEpisodes(_ episodes: [WatchedEpisode]) {
        do {
            let data = try JSONEncoder().encode(episodes)
            UserDefaults.standard.set(data, forKey: watchedEpisodesKey)
        } catch {
            print("Erreur lors de la sauvegarde des épisodes vus: \(error)")
        }
    }
    
    func addWatchedEpisode(_ episode: WatchedEpisode) -> [WatchedEpisode] {
        var episodes = loadWatchedEpisodes()
        
        // Vérifier si l'épisode n'est pas déjà dans la liste
        if !episodes.contains(where: { $0.tmdbId == episode.tmdbId }) {
            episodes.insert(episode, at: 0)
            saveWatchedEpisodes(episodes)
        }
        
        return episodes
    }
    
    func removeWatchedEpisode(_ episode: WatchedEpisode) -> [WatchedEpisode] {
        var episodes = loadWatchedEpisodes()
        episodes.removeAll { $0.id == episode.id }
        saveWatchedEpisodes(episodes)
        return episodes
    }
    
    func updateWatchedEpisode(_ episode: WatchedEpisode) -> [WatchedEpisode] {
        var episodes = loadWatchedEpisodes()
        if let index = episodes.firstIndex(where: { $0.id == episode.id }) {
            episodes[index] = episode
            saveWatchedEpisodes(episodes)
        }
        return episodes
    }
    
    func isEpisodeWatched(tmdbId: Int) -> Bool {
        let episodes = loadWatchedEpisodes()
        return episodes.contains { $0.tmdbId == tmdbId }
    }
    
    func watchedEpisodes(forSeriesTmdbId seriesId: Int) -> [WatchedEpisode] {
        let episodes = loadWatchedEpisodes()
        return episodes.filter { $0.seriesTmdbId == seriesId }
    }
    
    // MARK: - Badges
    
    func loadUnlockedBadges() -> [Badge] {
        guard let data = UserDefaults.standard.data(forKey: unlockedBadgesKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([Badge].self, from: data)
        } catch {
            print("Erreur lors du chargement des badges: \(error)")
            return []
        }
    }
    
    func saveUnlockedBadges(_ badges: [Badge]) {
        do {
            let data = try JSONEncoder().encode(badges)
            UserDefaults.standard.set(data, forKey: unlockedBadgesKey)
        } catch {
            print("Erreur lors de la sauvegarde des badges: \(error)")
        }
    }
    
    func unlockBadge(_ badge: Badge) -> [Badge] {
        var badges = loadUnlockedBadges()
        
        // Vérifier si le badge n'est pas déjà débloqué
        if !badges.contains(where: { $0.id == badge.id }) {
            badges.append(badge.unlocked())
            saveUnlockedBadges(badges)
        }
        
        return badges
    }
    
    func isBadgeUnlocked(_ badgeId: String) -> Bool {
        let badges = loadUnlockedBadges()
        return badges.contains { $0.id == badgeId }
    }
    
    // MARK: - Stats
    
    func loadStats() -> WatchedStats {
        guard let data = UserDefaults.standard.data(forKey: statsKey) else {
            return WatchedStats()
        }
        
        do {
            return try JSONDecoder().decode(WatchedStats.self, from: data)
        } catch {
            print("Erreur lors du chargement des stats: \(error)")
            return WatchedStats()
        }
    }
    
    func saveStats(_ stats: WatchedStats) {
        do {
            let data = try JSONEncoder().encode(stats)
            UserDefaults.standard.set(data, forKey: statsKey)
        } catch {
            print("Erreur lors de la sauvegarde des stats: \(error)")
        }
    }
    
    // MARK: - Reset
    
    func resetAllData() {
        UserDefaults.standard.removeObject(forKey: watchedMoviesKey)
        UserDefaults.standard.removeObject(forKey: watchedSeriesKey)
        UserDefaults.standard.removeObject(forKey: watchedEpisodesKey)
        UserDefaults.standard.removeObject(forKey: unlockedBadgesKey)
        UserDefaults.standard.removeObject(forKey: statsKey)
    }
}
