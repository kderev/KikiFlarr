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
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(groupedItems(from: items), id: \.title) { section in
                    VStack(alignment: .leading, spacing: 14) {
                        calendarSectionHeader(section.title)

                        VStack(spacing: 14) {
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
                    }
                    .padding(18)
                    .background(sectionBackground)
                    .overlay(sectionBorder)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func calendarSectionHeader(_ title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private var sectionBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
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

    private var episodeDate: Date? {
        item.episode.airDateUtc ?? item.episode.airDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                dateBadge

                PosterImageView(url: item.episode.series?.posterURL, width: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.episode.series?.title ?? "Série inconnue")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(episodeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if let timeLabel {
                        Label(timeLabel, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    metadataChips
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    monitoredToggle
                    Spacer(minLength: 0)
                    profileMenu
                }

                instancePill
            }
        }
        .padding(18)
        .background(cardBackground)
        .overlay(cardBorder)
        .opacity(isUpdating ? 0.7 : 1)
        .animation(.easeInOut(duration: 0.2), value: isUpdating)
    }

    private var dateBadge: some View {
        VStack(spacing: 2) {
            Text(dayNumberText)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)

            Text(monthText)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
        .frame(width: 58, height: 72)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
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
        HStack(spacing: 8) {
            if let qualityLabel {
                chip(text: qualityLabel, systemImage: "sparkles.tv")
            }

            if let profileName {
                chip(text: profileName, systemImage: "bolt.badge.checkmark")
            }
        }
    }

    private func chip(text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .foregroundStyle(.primary)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 6)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
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
    SonarrCalendarView()
        .environmentObject(InstanceManager())
}
