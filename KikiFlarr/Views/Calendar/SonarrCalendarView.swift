import SwiftUI

struct SonarrCalendarView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = SonarrCalendarViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if instanceManager.sonarrInstances.isEmpty {
                    noInstancesView
                } else {
                    LoadableView(
                        state: viewModel.state,
                        emptyIcon: "calendar",
                        emptyTitle: "Aucune sortie",
                        emptyDescription: "Les sorties Sonarr des prochaines semaines s'afficheront ici",
                        onRetry: {
                            Task {
                                await viewModel.loadCalendar()
                            }
                        }
                    ) { items in
                        calendarList(items: items)
                    }
                }
            }
            .navigationTitle("Calendrier")
            .onAppear {
                viewModel.setInstanceManager(instanceManager)
                Task {
                    await viewModel.loadCalendar()
                }
            }
            .refreshable {
                await viewModel.loadCalendar()
            }
            .alert("Erreur", isPresented: Binding(get: {
                viewModel.errorMessage != nil
            }, set: { _ in
                viewModel.errorMessage = nil
            })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var noInstancesView: some View {
        ContentUnavailableView {
            Label("Aucune instance Sonarr", systemImage: "tv")
        } description: {
            Text("Ajoutez une instance Sonarr dans les paramètres pour voir le calendrier")
        }
    }

    private func calendarList(items: [SonarrCalendarViewModel.CalendarEpisodeItem]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(groupedItems(from: items), id: \.title) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            ForEach(section.items) { item in
                                SonarrCalendarRow(
                                    item: item,
                                    profileName: viewModel.profileName(for: item),
                                    qualityLabel: viewModel.qualityLabel(for: item),
                                    timeLabel: viewModel.formattedTime(for: item.episode),
                                    profiles: viewModel.profilesByInstance[item.instance.id] ?? [],
                                    isUpdating: viewModel.updatingEpisodeIds.contains(item.id),
                                    onToggleMonitored: { monitored in
                                        Task {
                                            await viewModel.setEpisodeMonitored(item, monitored: monitored)
                                        }
                                    },
                                    onSelectProfile: { profile in
                                        Task {
                                            await viewModel.updateQualityProfile(for: item, profileId: profile.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func groupedItems(from items: [SonarrCalendarViewModel.CalendarEpisodeItem]) -> [(title: String, items: [SonarrCalendarViewModel.CalendarEpisodeItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item -> Date? in
            guard let date = viewModel.dateForEpisode(item.episode) else { return nil }
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
}

private struct SonarrCalendarRow: View {
    let item: SonarrCalendarViewModel.CalendarEpisodeItem
    let profileName: String?
    let qualityLabel: String?
    let timeLabel: String?
    let profiles: [SonarrQualityProfile]
    let isUpdating: Bool
    let onToggleMonitored: (Bool) -> Void
    let onSelectProfile: (SonarrQualityProfile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                PosterImageView(url: item.episode.series?.posterURL, width: 60)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.episode.series?.title ?? "Série inconnue")
                        .font(.headline)

                    Text(episodeSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let timeLabel {
                        Label(timeLabel, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        if let qualityLabel {
                            Label(qualityLabel, systemImage: "sparkles.tv")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let profileName {
                            Label(profileName, systemImage: "slider.horizontal.3")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(item.instance.name)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            HStack {
                Toggle(isOn: Binding(get: {
                    item.episode.monitored ?? false
                }, set: { newValue in
                    onToggleMonitored(newValue)
                })) {
                    Text(item.episode.monitored ?? false ? "Surveillé" : "Non surveillé")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .toggleStyle(.switch)
                .disabled(isUpdating)

                Spacer()

                if !profiles.isEmpty {
                    Menu {
                        ForEach(profiles) { profile in
                            Button(profile.name) {
                                onSelectProfile(profile)
                            }
                        }
                    } label: {
                        Label("Profil", systemImage: "slider.horizontal.3")
                            .font(.caption)
                    }
                    .disabled(isUpdating)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var episodeSubtitle: String {
        let season = item.episode.seasonNumber.map { "S\($0)" } ?? "S?"
        let episode = item.episode.episodeNumber.map { "E\($0)" } ?? "E?"
        let title = item.episode.title ?? "Épisode"
        return "\(season)\(episode) • \(title)"
    }
}

#Preview {
    SonarrCalendarView()
        .environmentObject(InstanceManager())
}
