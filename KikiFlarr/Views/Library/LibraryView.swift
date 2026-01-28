import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = LibraryViewModel()
    @StateObject private var calendarViewModel = SonarrCalendarViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Bibliothèque", selection: $viewModel.selectedTab) {
                    Text("Films (\(viewModel.moviesCount))").tag(LibraryViewModel.LibraryTab.movies)
                    Text("Séries (\(viewModel.seriesCount))").tag(LibraryViewModel.LibraryTab.series)
                    Label("À venir", systemImage: "calendar").tag(LibraryViewModel.LibraryTab.calendar)
                }
                .pickerStyle(.segmented)
                .padding()

                Group {
                    switch viewModel.selectedTab {
                    case .movies:
                        moviesContent
                    case .series:
                        seriesContent
                    case .calendar:
                        calendarContent
                    }
                }
            }
            .navigationTitle("Bibliothèque")
            .onAppear {
                viewModel.setInstanceManager(instanceManager)
                calendarViewModel.setInstanceManager(instanceManager)
                Task {
                    await viewModel.loadAll()
                }
            }
            .refreshable {
                if viewModel.selectedTab == .calendar {
                    await calendarViewModel.loadCalendar()
                } else {
                    await viewModel.refresh()
                }
            }
        }
    }
    
    private var moviesContent: some View {
        LoadableView(
            state: viewModel.moviesState,
            emptyIcon: "film",
            emptyTitle: "Aucun film",
            emptyDescription: "Votre bibliothèque Radarr est vide",
            onRetry: {
                Task {
                    await viewModel.loadMovies()
                }
            }
        ) { movies in
            moviesList(movies: movies)
        }
    }
    
    private var seriesContent: some View {
        LoadableView(
            state: viewModel.seriesState,
            emptyIcon: "tv",
            emptyTitle: "Aucune série",
            emptyDescription: "Votre bibliothèque Sonarr est vide",
            onRetry: {
                Task {
                    await viewModel.loadSeries()
                }
            }
        ) { series in
            seriesList(series: series)
        }
    }

    private var calendarContent: some View {
        Group {
            if instanceManager.sonarrInstances.isEmpty {
                ContentUnavailableView {
                    Label("Aucune instance Sonarr", systemImage: "tv")
                } description: {
                    Text("Ajoutez une instance Sonarr dans les paramètres pour voir le calendrier")
                }
            } else {
                LoadableView(
                    state: calendarViewModel.state,
                    emptyIcon: "calendar",
                    emptyTitle: "Aucune sortie",
                    emptyDescription: "Les sorties Sonarr des prochaines semaines s'afficheront ici",
                    onRetry: {
                        Task {
                            await calendarViewModel.loadCalendar()
                        }
                    }
                ) { items in
                    calendarList(items: items)
                }
            }
        }
        .onAppear {
            if calendarViewModel.state.data == nil {
                Task {
                    await calendarViewModel.loadCalendar()
                }
            }
        }
    }

    private func calendarList(items: [SonarrCalendarViewModel.CalendarEpisodeItem]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(groupedCalendarItems(from: items), id: \.title) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        calendarSectionHeader(section.title)

                        VStack(spacing: 12) {
                            ForEach(section.items) { item in
                                LibraryCalendarRow(
                                    item: item,
                                    profileName: calendarViewModel.profileName(for: item),
                                    qualityLabel: calendarViewModel.qualityLabel(for: item),
                                    timeLabel: calendarViewModel.formattedTime(for: item.episode),
                                    profiles: calendarViewModel.profilesByInstance[item.instance.id] ?? [],
                                    isUpdating: calendarViewModel.updatingEpisodeIds.contains(item.id),
                                    onToggleMonitored: { monitored in
                                        Task {
                                            await calendarViewModel.setEpisodeMonitored(item, monitored: monitored)
                                        }
                                    },
                                    onSelectProfile: { profile in
                                        Task {
                                            await calendarViewModel.updateQualityProfile(for: item, profileId: profile.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(calendarBackground.ignoresSafeArea())
    }

    private func calendarSectionHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    private var calendarBackground: some View {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                Color(.secondarySystemGroupedBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func groupedCalendarItems(from items: [SonarrCalendarViewModel.CalendarEpisodeItem]) -> [(title: String, items: [SonarrCalendarViewModel.CalendarEpisodeItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item -> Date? in
            guard let date = calendarViewModel.dateForEpisode(item.episode) else { return nil }
            return calendar.startOfDay(for: date)
        }

        let sortedKeys = grouped.keys.sorted { lhs, rhs in
            switch (lhs, rhs) {
            case let (left?, right?):
                return left < right
            case (nil, _?):
                return false
            case (_?, nil):
                return true
            case (nil, nil):
                return false
            }
        }

        return sortedKeys.map { key in
            let title: String
            if let key {
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                formatter.timeStyle = .none
                formatter.locale = Locale(identifier: "fr_FR")
                title = formatter.string(from: key)
            } else {
                title = "Date inconnue"
            }
            return (title: title, items: grouped[key] ?? [])
        }
    }
    
    private func moviesList(movies: [LibraryViewModel.MovieWithInstance]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 16) {
                ForEach(movies) { item in
                    NavigationLink {
                        MovieDetailView(movie: item.movie, instance: item.instance)
                    } label: {
                        MovieCard(movieID: item.movie.id, title: item.movie.title, year: item.movie.year, posterURL: item.movie.posterURL, hasFile: item.movie.hasFile ?? false, instanceName: item.instance.name)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    private func seriesList(series: [LibraryViewModel.SeriesWithInstance]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 16) {
                ForEach(series) { item in
                    NavigationLink {
                        SeriesDetailView(series: item.series, instance: item.instance)
                    } label: {
                        SeriesCard(seriesID: item.series.id, title: item.series.title, posterURL: item.series.posterURL, episodeFileCount: item.series.statistics?.episodeFileCount ?? 0, episodeCount: item.series.statistics?.episodeCount ?? 0, percentComplete: item.series.statistics?.percentOfEpisodes ?? 0, instanceName: item.instance.name)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

struct MovieCard: View, Equatable {
    let movieID: Int
    let title: String
    let year: Int
    let posterURL: URL?
    let hasFile: Bool
    let instanceName: String
    
    static func == (lhs: MovieCard, rhs: MovieCard) -> Bool {
        lhs.movieID == rhs.movieID && lhs.hasFile == rhs.hasFile
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                AsyncImageView(url: posterURL, placeholder: "film")
                    .frame(width: 100, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if hasFile {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(.white))
                        .padding(4)
                }
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Text("\(year)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(instanceName)
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.orange)
                .clipShape(Capsule())
        }
        .frame(width: 100)
    }
}

struct SeriesCard: View, Equatable {
    let seriesID: Int
    let title: String
    let posterURL: URL?
    let episodeFileCount: Int
    let episodeCount: Int
    let percentComplete: Double
    let instanceName: String
    
    static func == (lhs: SeriesCard, rhs: SeriesCard) -> Bool {
        lhs.seriesID == rhs.seriesID && lhs.episodeFileCount == rhs.episodeFileCount && lhs.episodeCount == rhs.episodeCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                AsyncImageView(url: posterURL, placeholder: "tv")
                    .frame(width: 100, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if percentComplete >= 100 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(.white))
                        .padding(4)
                }
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Text("\(episodeFileCount)/\(episodeCount) épisodes")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(instanceName)
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
        .frame(width: 100)
    }
}

private struct LibraryCalendarRow: View {
    let item: SonarrCalendarViewModel.CalendarEpisodeItem
    let profileName: String?
    let qualityLabel: String?
    let timeLabel: String?
    let profiles: [SonarrQualityProfile]
    let isUpdating: Bool
    let onToggleMonitored: (Bool) -> Void
    let onSelectProfile: (SonarrQualityProfile) -> Void

    private var episodeDate: Date? {
        let dateString = item.episode.airDateUtc ?? item.episode.airDate
        guard let dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                PosterImageView(url: item.episode.series?.posterURL, width: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        dateBadge
                        if let timeLabel {
                            Label(timeLabel, systemImage: "clock")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }

                    Text(item.episode.series?.title ?? "Série inconnue")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(episodeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    metadataChips
                }
            }

            HStack(spacing: 12) {
                monitoredToggle
                Spacer(minLength: 0)
                profileMenu
            }

            instancePill
        }
        .padding(16)
        .background(cardBackground)
        .overlay(cardBorder)
        .opacity(isUpdating ? 0.7 : 1)
        .animation(.easeInOut(duration: 0.2), value: isUpdating)
    }

    private var dateBadge: some View {
        HStack(spacing: 6) {
            Text(dayNumberText)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            Text(monthText)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.accentColor.opacity(0.16))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Diffusion le \(fullDateText)")
    }

    private var monitoredToggle: some View {
        Toggle(isOn: Binding(get: {
            item.episode.monitored ?? false
        }, set: { newValue in
            onToggleMonitored(newValue)
        })) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Suivi")
                    .font(.subheadline.weight(.semibold))

                Text(item.episode.monitored ?? false ? "Activé" : "Désactivé")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.switch)
        .disabled(isUpdating)
    }

    @ViewBuilder
    private var profileMenu: some View {
        if !profiles.isEmpty {
            Menu {
                ForEach(profiles) { profile in
                    Button(profile.name) {
                        onSelectProfile(profile)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                    Text(profileName ?? "Profil")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .disabled(isUpdating)
        }
    }

    private var instancePill: some View {
        HStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.caption.weight(.semibold))
            Text(item.instance.name)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.accentColor.opacity(0.12))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var metadataChips: some View {
        if let qualityLabel {
            chip(text: qualityLabel, systemImage: "sparkles.tv")
        }
    }

    private func chip(text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .allowsTightening(true)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.22), lineWidth: 1)
            )
            .foregroundStyle(.primary)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.secondarySystemBackground),
                        Color(.secondarySystemBackground).opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 10)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
    }

    private var dayNumberText: String {
        guard let date = episodeDate else { return "--" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var monthText: String {
        guard let date = episodeDate else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private var fullDateText: String {
        guard let date = episodeDate else { return "date inconnue" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private var episodeSubtitle: String {
        let season = item.episode.seasonNumber.map { "S\($0)" } ?? "S?"
        let episode = item.episode.episodeNumber.map { "E\($0)" } ?? "E?"
        let title = item.episode.title ?? "Épisode"
        return "\(season)\(episode) • \(title)"
    }
}

#Preview {
    LibraryView()
        .environmentObject(InstanceManager())
}
