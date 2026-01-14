import Foundation
import SwiftUI
import Combine

@MainActor
class WatchedViewModel: ObservableObject {
    @Published var watchedMovies: [WatchedMovie] = []
    @Published var watchedSeries: [WatchedSeries] = []
    @Published var watchedEpisodes: [WatchedEpisode] = []
    @Published var unlockedBadges: [Badge] = []
    @Published var allBadges: [Badge] = []
    @Published var stats: WatchedStats = WatchedStats()
    @Published var recentlyUnlockedBadge: Badge?
    @Published var showBadgeUnlockAnimation = false
    
    private let storage = WatchedStorageService.shared
    
    init() {
        loadData()
        setupAllBadges()
    }
    
    // MARK: - Chargement des données
    
    func loadData() {
        watchedMovies = storage.loadWatchedMovies()
        watchedSeries = storage.loadWatchedSeries()
        watchedEpisodes = storage.loadWatchedEpisodes()
        unlockedBadges = storage.loadUnlockedBadges()
        stats = storage.loadStats()
        updateAllBadgesStatus()
    }
    
    private func setupAllBadges() {
        allBadges = BadgeDefinitions.allBaseBadges
        updateAllBadgesStatus()
    }
    
    private func updateAllBadgesStatus() {
        // Mettre à jour le statut de chaque badge
        allBadges = BadgeDefinitions.allBaseBadges.map { badge in
            if let unlockedBadge = unlockedBadges.first(where: { $0.id == badge.id }) {
                return unlockedBadge
            }
            return badge
        }
    }
    
    // MARK: - Gestion des films vus
    
    func markAsWatched(_ movie: RadarrMovie, rating: Int? = nil, notes: String? = nil) {
        var watchedMovie = WatchedMovie.from(movie: movie)
        
        // Ajouter la note et les commentaires si fournis
        if rating != nil || notes != nil {
            watchedMovie = WatchedMovie(
                id: watchedMovie.id,
                tmdbId: watchedMovie.tmdbId,
                radarrId: watchedMovie.radarrId,
                title: watchedMovie.title,
                year: watchedMovie.year,
                posterURL: watchedMovie.posterURL,
                fanartURL: watchedMovie.fanartURL,
                genres: watchedMovie.genres,
                runtime: watchedMovie.runtime,
                watchedDate: watchedMovie.watchedDate,
                rating: rating,
                notes: notes
            )
        }
        
        watchedMovies = storage.addWatchedMovie(watchedMovie)
        updateStats()
        checkForNewBadges()
    }
    
    func removeFromWatched(_ movie: WatchedMovie) {
        watchedMovies = storage.removeWatchedMovie(movie)
        updateStats()
    }
    
    func updateMovie(_ movie: WatchedMovie) {
        watchedMovies = storage.updateWatchedMovie(movie)
    }
    
    func isWatched(_ movie: RadarrMovie) -> Bool {
        guard let tmdbId = movie.tmdbId else { return false }
        return watchedMovies.contains { $0.tmdbId == tmdbId }
    }
    
    func isWatched(tmdbId: Int) -> Bool {
        return watchedMovies.contains { $0.tmdbId == tmdbId }
    }
    
    func isMovieWatched(tmdbId: Int) -> Bool {
        return watchedMovies.contains { $0.tmdbId == tmdbId }
    }
    
    // Ajouter directement un WatchedMovie (pour TMDB)
    func addToWatched(_ movie: WatchedMovie) {
        // Vérifier si le film n'est pas déjà dans la liste
        guard !watchedMovies.contains(where: { $0.tmdbId == movie.tmdbId }) else { return }
        
        watchedMovies = storage.addWatchedMovie(movie)
        updateStats()
        checkForNewBadges()
    }
    
    // MARK: - Gestion des séries vues
    
    func markSeriesAsWatched(_ series: SonarrSeries, rating: Int? = nil, notes: String? = nil) {
        var watchedSeries = WatchedSeries.from(series: series)
        
        if rating != nil || notes != nil {
            watchedSeries = WatchedSeries(
                id: watchedSeries.id,
                tvdbId: watchedSeries.tvdbId,
                sonarrId: watchedSeries.sonarrId,
                title: watchedSeries.title,
                year: watchedSeries.year,
                posterURL: watchedSeries.posterURL,
                fanartURL: watchedSeries.fanartURL,
                genres: watchedSeries.genres,
                totalEpisodes: watchedSeries.totalEpisodes,
                watchedEpisodes: watchedSeries.watchedEpisodes,
                watchedDate: watchedSeries.watchedDate,
                rating: rating,
                notes: notes
            )
        }
        
        self.watchedSeries = storage.addWatchedSeries(watchedSeries)
        updateStats()
        checkForNewBadges()
    }
    
    func removeFromWatched(_ series: WatchedSeries) {
        watchedSeries = storage.removeWatchedSeries(series)
        updateStats()
    }
    
    func updateSeries(_ series: WatchedSeries) {
        watchedSeries = storage.updateWatchedSeries(series)
    }
    
    func isSeriesWatched(_ series: SonarrSeries) -> Bool {
        guard let tvdbId = series.tvdbId else { return false }
        return watchedSeries.contains { $0.tvdbId == tvdbId }
    }
    
    func isSeriesWatched(tvdbId: Int) -> Bool {
        return watchedSeries.contains { $0.tvdbId == tvdbId }
    }
    
    func addToWatched(_ series: WatchedSeries) {
        guard !watchedSeries.contains(where: { $0.tvdbId == series.tvdbId }) else { return }
        
        watchedSeries = storage.addWatchedSeries(series)
        updateStats()
        checkForNewBadges()
    }
    
    // MARK: - Gestion des épisodes vus
    
    func addToWatched(_ episode: WatchedEpisode) {
        guard !watchedEpisodes.contains(where: { $0.tmdbId == episode.tmdbId }) else { return }
        
        watchedEpisodes = storage.addWatchedEpisode(episode)
        updateStats()
        checkForNewBadges()
    }
    
    func removeFromWatched(_ episode: WatchedEpisode) {
        watchedEpisodes = storage.removeWatchedEpisode(episode)
        updateStats()
    }
    
    func updateEpisode(_ episode: WatchedEpisode) {
        watchedEpisodes = storage.updateWatchedEpisode(episode)
    }
    
    func isEpisodeWatched(tmdbId: Int) -> Bool {
        return watchedEpisodes.contains { $0.tmdbId == tmdbId }
    }
    
    func isEpisodeWatched(seriesTmdbId: Int, seasonNumber: Int, episodeNumber: Int) -> Bool {
        return watchedEpisodes.contains {
            $0.seriesTmdbId == seriesTmdbId &&
            $0.seasonNumber == seasonNumber &&
            $0.episodeNumber == episodeNumber
        }
    }
    
    func watchedEpisodes(forSeriesTmdbId seriesId: Int) -> [WatchedEpisode] {
        return watchedEpisodes.filter { $0.seriesTmdbId == seriesId }
    }
    
    func watchedEpisodesCount(forSeriesTmdbId seriesId: Int) -> Int {
        return watchedEpisodes.filter { $0.seriesTmdbId == seriesId }.count
    }
    
    func recentWatchedEpisodes(limit: Int = 10) -> [WatchedEpisode] {
        Array(watchedEpisodes.prefix(limit))
    }
    
    // MARK: - Statistiques
    
    private func updateStats() {
        var newStats = WatchedStats()
        
        newStats.totalMovies = watchedMovies.count
        newStats.totalRuntime = watchedMovies.compactMap { $0.runtime }.reduce(0, +)
        
        // Compter par genre (films)
        var genreCounts: [String: Int] = [:]
        var uniqueGenres: Set<String> = []
        
        for movie in watchedMovies {
            for genre in movie.genres {
                genreCounts[genre, default: 0] += 1
                uniqueGenres.insert(genre)
            }
        }
        
        newStats.genreCounts = genreCounts
        newStats.uniqueGenres = uniqueGenres
        
        // Statistiques séries
        newStats.totalSeries = watchedSeries.count
        newStats.completedSeries = watchedSeries.filter { $0.isCompleted }.count
        
        // Compter par genre (séries)
        var seriesGenreCounts: [String: Int] = [:]
        var uniqueSeriesGenres: Set<String> = []
        
        for series in watchedSeries {
            for genre in series.genres {
                seriesGenreCounts[genre, default: 0] += 1
                uniqueSeriesGenres.insert(genre)
            }
        }
        
        newStats.seriesGenreCounts = seriesGenreCounts
        newStats.uniqueSeriesGenres = uniqueSeriesGenres
        newStats.seriesThisWeek = seriesWatched(inLast: 7)
        newStats.seriesThisMonth = seriesWatched(inLast: 30)
        
        // Statistiques épisodes
        newStats.totalEpisodes = watchedEpisodes.count
        newStats.episodesRuntime = watchedEpisodes.compactMap { $0.runtime }.reduce(0, +)
        newStats.episodesThisWeek = episodesWatched(inLast: 7)
        newStats.episodesThisMonth = episodesWatched(inLast: 30)
        
        // Calculer le streak (films + épisodes combinés)
        let (current, longest) = calculateStreak()
        newStats.currentStreak = current
        newStats.longestStreak = max(longest, stats.longestStreak)
        
        // Dernière activité (film ou épisode le plus récent)
        let lastMovieDate = watchedMovies.first?.watchedDate
        let lastEpisodeDate = watchedEpisodes.first?.watchedDate
        if let movieDate = lastMovieDate, let episodeDate = lastEpisodeDate {
            newStats.lastWatchedDate = max(movieDate, episodeDate)
        } else {
            newStats.lastWatchedDate = lastMovieDate ?? lastEpisodeDate
        }
        
        newStats.moviesThisWeek = moviesWatched(inLast: 7)
        newStats.moviesThisMonth = moviesWatched(inLast: 30)
        
        stats = newStats
        storage.saveStats(stats)
    }
    
    private func seriesWatched(inLast days: Int) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        return watchedSeries.filter { $0.watchedDate >= startDate }.count
    }
    
    private func episodesWatched(inLast days: Int) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        return watchedEpisodes.filter { $0.watchedDate >= startDate }.count
    }
    
    private func calculateStreak() -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        
        // Combiner les dates des films ET des épisodes pour le streak
        var allWatchedDates: [Date] = []
        allWatchedDates.append(contentsOf: watchedMovies.map { calendar.startOfDay(for: $0.watchedDate) })
        allWatchedDates.append(contentsOf: watchedEpisodes.map { calendar.startOfDay(for: $0.watchedDate) })
        
        guard !allWatchedDates.isEmpty else { return (0, 0) }
        
        let uniqueDates = Array(Set(allWatchedDates)).sorted(by: >)
        
        guard !uniqueDates.isEmpty else { return (0, 0) }
        
        var currentStreak = 1
        var longestStreak = 1
        var tempStreak = 1
        
        // Vérifier si aujourd'hui ou hier est dans la liste
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let hasToday = uniqueDates.contains(today)
        let hasYesterday = uniqueDates.contains(yesterday)
        
        if !hasToday && !hasYesterday {
            currentStreak = 0
        } else {
            // Calculer le streak courant
            var checkDate = hasToday ? today : yesterday
            currentStreak = hasToday ? 1 : 1
            
            while let nextDate = calendar.date(byAdding: .day, value: -1, to: checkDate),
                  uniqueDates.contains(nextDate) {
                currentStreak += 1
                checkDate = nextDate
            }
        }
        
        // Calculer le plus long streak
        for i in 1..<uniqueDates.count {
            let daysDiff = calendar.dateComponents([.day], from: uniqueDates[i], to: uniqueDates[i-1]).day ?? 0
            
            if daysDiff == 1 {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 1
            }
        }
        
        return (currentStreak, max(longestStreak, currentStreak))
    }
    
    private func moviesWatched(inLast days: Int) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        return watchedMovies.filter { $0.watchedDate >= startDate }.count
    }
    
    // MARK: - Vérification des badges
    
    func checkForNewBadges() {
        var newlyUnlocked: [Badge] = []
        
        // Badges collectionneur (films)
        for badge in BadgeDefinitions.collectorBadges {
            if !isBadgeUnlocked(badge.id) && stats.totalMovies >= badge.requirement {
                newlyUnlocked.append(badge)
            }
        }
        
        // Badges collectionneur (séries)
        for badge in BadgeDefinitions.seriesCollectorBadges {
            if !isBadgeUnlocked(badge.id) && stats.totalSeries >= badge.requirement {
                newlyUnlocked.append(badge)
            }
        }
        
        // Badges collectionneur (épisodes)
        for badge in BadgeDefinitions.episodeCollectorBadges {
            if !isBadgeUnlocked(badge.id) && stats.totalEpisodes >= badge.requirement {
                newlyUnlocked.append(badge)
            }
        }
        
        // Badges total (films + épisodes)
        for badge in BadgeDefinitions.totalWatchedBadges {
            if !isBadgeUnlocked(badge.id) && stats.totalWatched >= badge.requirement {
                newlyUnlocked.append(badge)
            }
        }
        
        // Badges genre (films)
        for (genre, count) in stats.genreCounts {
            for badge in BadgeDefinitions.genreBadges(for: genre) {
                if !isBadgeUnlocked(badge.id) && count >= badge.requirement {
                    newlyUnlocked.append(badge)
                }
            }
        }
        
        // Badges genre (séries)
        for (genre, count) in stats.seriesGenreCounts {
            for badge in BadgeDefinitions.seriesGenreBadges(for: genre) {
                if !isBadgeUnlocked(badge.id) && count >= badge.requirement {
                    newlyUnlocked.append(badge)
                }
            }
        }
        
        // Badges marathon (films dans la journée)
        let moviesInDay = moviesWatchedToday()
        for badge in BadgeDefinitions.marathonBadges.filter({ $0.id.contains("day") }) {
            if !isBadgeUnlocked(badge.id) && moviesInDay >= badge.requirement {
                newlyUnlocked.append(badge)
            }
        }
        
        // Badges marathon (films dans la semaine)
        for badge in BadgeDefinitions.marathonBadges.filter({ $0.id.contains("week") }) {
            if !isBadgeUnlocked(badge.id) && stats.moviesThisWeek >= badge.requirement {
                newlyUnlocked.append(badge)
            }
        }
        
        // Badges dévotion (streak)
        for badge in BadgeDefinitions.dedicationBadges {
            if !isBadgeUnlocked(badge.id) && stats.currentStreak >= badge.requirement {
                newlyUnlocked.append(badge)
            }
        }
        
        // Badges spéciaux (films)
        checkSpecialBadges(&newlyUnlocked)
        
        // Badges spéciaux (séries)
        checkSeriesSpecialBadges(&newlyUnlocked)
        
        // Débloquer les nouveaux badges
        for badge in newlyUnlocked {
            unlockedBadges = storage.unlockBadge(badge)
        }
        
        // Afficher l'animation pour le premier badge débloqué
        if let firstNew = newlyUnlocked.first {
            showBadgeUnlock(firstNew)
        }
        
        updateAllBadgesStatus()
    }
    
    private func checkSpecialBadges(_ newlyUnlocked: inout [Badge]) {
        // Noctambule
        if !isBadgeUnlocked("night_owl") {
            let calendar = Calendar.current
            let hasNightMovie = watchedMovies.contains { movie in
                let hour = calendar.component(.hour, from: movie.watchedDate)
                return hour >= 0 && hour < 5
            }
            if hasNightMovie {
                if let badge = BadgeDefinitions.specialBadges.first(where: { $0.id == "night_owl" }) {
                    newlyUnlocked.append(badge)
                }
            }
        }
        
        // Lève-tôt
        if !isBadgeUnlocked("early_bird") {
            let calendar = Calendar.current
            let hasEarlyMovie = watchedMovies.contains { movie in
                let hour = calendar.component(.hour, from: movie.watchedDate)
                return hour >= 5 && hour < 7
            }
            if hasEarlyMovie {
                if let badge = BadgeDefinitions.specialBadges.first(where: { $0.id == "early_bird" }) {
                    newlyUnlocked.append(badge)
                }
            }
        }
        
        // Éclectique (10 genres différents)
        if !isBadgeUnlocked("variety_lover") && stats.uniqueGenres.count >= 10 {
            if let badge = BadgeDefinitions.specialBadges.first(where: { $0.id == "variety_lover" }) {
                newlyUnlocked.append(badge)
            }
        }
        
        // Maître des genres (15 genres)
        if !isBadgeUnlocked("genre_master") && stats.uniqueGenres.count >= 15 {
            if let badge = BadgeDefinitions.specialBadges.first(where: { $0.id == "genre_master" }) {
                newlyUnlocked.append(badge)
            }
        }
        
        // Endurant (film de plus de 3h)
        if !isBadgeUnlocked("long_movie") {
            let hasLongMovie = watchedMovies.contains { ($0.runtime ?? 0) >= 180 }
            if hasLongMovie {
                if let badge = BadgeDefinitions.specialBadges.first(where: { $0.id == "long_movie" }) {
                    newlyUnlocked.append(badge)
                }
            }
        }
        
        // Classique (films d'avant 1980)
        if !isBadgeUnlocked("classic_lover") {
            let classicCount = watchedMovies.filter { $0.year < 1980 }.count
            if classicCount >= 10 {
                if let badge = BadgeDefinitions.specialBadges.first(where: { $0.id == "classic_lover" }) {
                    newlyUnlocked.append(badge)
                }
            }
        }
        
        // Contemporain (films de l'année en cours)
        if !isBadgeUnlocked("modern_fan") {
            let currentYear = Calendar.current.component(.year, from: Date())
            let modernCount = watchedMovies.filter { $0.year == currentYear }.count
            if modernCount >= 10 {
                if let badge = BadgeDefinitions.specialBadges.first(where: { $0.id == "modern_fan" }) {
                    newlyUnlocked.append(badge)
                }
            }
        }
        
        // Guerrier du Weekend
        if !isBadgeUnlocked("weekend_warrior") {
            let weekendMovies = moviesWatchedThisWeekend()
            if weekendMovies >= 5 {
                if let badge = BadgeDefinitions.specialBadges.first(where: { $0.id == "weekend_warrior" }) {
                    newlyUnlocked.append(badge)
                }
            }
        }
    }
    
    private func checkSeriesSpecialBadges(_ newlyUnlocked: inout [Badge]) {
        // Binge Watcher (terminer une série complète)
        if !isBadgeUnlocked("series_binger") && stats.completedSeries >= 1 {
            if let badge = BadgeDefinitions.seriesSpecialBadges.first(where: { $0.id == "series_binger" }) {
                newlyUnlocked.append(badge)
            }
        }
        
        // Binger Pro (terminer 5 séries complètes)
        if !isBadgeUnlocked("series_binger_5") && stats.completedSeries >= 5 {
            if let badge = BadgeDefinitions.seriesSpecialBadges.first(where: { $0.id == "series_binger_5" }) {
                newlyUnlocked.append(badge)
            }
        }
        
        // Binger Ultime (terminer 20 séries complètes)
        if !isBadgeUnlocked("series_binger_20") && stats.completedSeries >= 20 {
            if let badge = BadgeDefinitions.seriesSpecialBadges.first(where: { $0.id == "series_binger_20" }) {
                newlyUnlocked.append(badge)
            }
        }
        
        // Longue Haleine (série de plus de 100 épisodes)
        if !isBadgeUnlocked("series_long") {
            let hasLongSeries = watchedSeries.contains { $0.totalEpisodes >= 100 }
            if hasLongSeries {
                if let badge = BadgeDefinitions.seriesSpecialBadges.first(where: { $0.id == "series_long" }) {
                    newlyUnlocked.append(badge)
                }
            }
        }
        
        // Nostalgique (séries d'avant 2000)
        if !isBadgeUnlocked("series_classic") {
            let classicCount = watchedSeries.filter { $0.year < 2000 }.count
            if classicCount >= 5 {
                if let badge = BadgeDefinitions.seriesSpecialBadges.first(where: { $0.id == "series_classic" }) {
                    newlyUnlocked.append(badge)
                }
            }
        }
        
        // Tendance (séries de l'année en cours)
        if !isBadgeUnlocked("series_modern") {
            let currentYear = Calendar.current.component(.year, from: Date())
            let modernCount = watchedSeries.filter { $0.year == currentYear }.count
            if modernCount >= 10 {
                if let badge = BadgeDefinitions.seriesSpecialBadges.first(where: { $0.id == "series_modern" }) {
                    newlyUnlocked.append(badge)
                }
            }
        }
        
        // Éclectique TV (8 genres différents)
        if !isBadgeUnlocked("series_genre_variety") && stats.uniqueSeriesGenres.count >= 8 {
            if let badge = BadgeDefinitions.seriesSpecialBadges.first(where: { $0.id == "series_genre_variety" }) {
                newlyUnlocked.append(badge)
            }
        }
    }
    
    private func moviesWatchedToday() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return watchedMovies.filter {
            calendar.isDate($0.watchedDate, inSameDayAs: today)
        }.count
    }
    
    private func moviesWatchedThisWeekend() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // Trouver le samedi de cette semaine
        var saturdayOffset = 7 - weekday
        if weekday == 1 { saturdayOffset = -1 } // Dimanche
        else if weekday == 7 { saturdayOffset = 0 } // Samedi
        
        guard let saturday = calendar.date(byAdding: .day, value: saturdayOffset, to: today),
              let sunday = calendar.date(byAdding: .day, value: saturdayOffset + 1, to: today) else {
            return 0
        }
        
        let saturdayStart = calendar.startOfDay(for: saturday)
        let sundayEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: sunday))!
        
        return watchedMovies.filter {
            $0.watchedDate >= saturdayStart && $0.watchedDate < sundayEnd
        }.count
    }
    
    private func isBadgeUnlocked(_ id: String) -> Bool {
        unlockedBadges.contains { $0.id == id }
    }
    
    private func showBadgeUnlock(_ badge: Badge) {
        recentlyUnlockedBadge = badge.unlocked()
        showBadgeUnlockAnimation = true
        
        // Cacher l'animation après un délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showBadgeUnlockAnimation = false
            self?.recentlyUnlockedBadge = nil
        }
    }
    
    // MARK: - Helpers
    
    var badgeProgress: Double {
        guard !allBadges.isEmpty else { return 0 }
        return Double(unlockedBadges.count) / Double(allBadges.count)
    }
    
    var badgesByCategory: [BadgeCategory: [Badge]] {
        Dictionary(grouping: allBadges) { $0.category }
    }
    
    func badges(for category: BadgeCategory) -> [Badge] {
        allBadges.filter { $0.category == category }
    }
    
    func recentWatchedMovies(limit: Int = 10) -> [WatchedMovie] {
        Array(watchedMovies.prefix(limit))
    }
    
    func recentWatchedSeries(limit: Int = 10) -> [WatchedSeries] {
        Array(watchedSeries.prefix(limit))
    }
    
    // MARK: - Reset
    
    func resetAllData() {
        storage.resetAllData()
        watchedMovies = []
        watchedSeries = []
        watchedEpisodes = []
        unlockedBadges = []
        stats = WatchedStats()
        setupAllBadges()
    }
}
