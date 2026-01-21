import Foundation
import SwiftUI

@MainActor
final class SonarrCalendarViewModel: ObservableObject {
    struct CalendarEpisodeItem: Identifiable, Hashable {
        let episode: SonarrCalendarEpisode
        let instance: ServiceInstance

        var id: Int { episode.id }
    }

    struct SeriesKey: Hashable {
        let instanceId: UUID
        let seriesId: Int
    }

    @Published var state: LoadableState<[CalendarEpisodeItem]> = .idle
    @Published var profilesByInstance: [UUID: [SonarrQualityProfile]] = [:]
    @Published var updatingEpisodeIds: Set<Int> = []
    @Published var errorMessage: String?

    private var instanceManager: InstanceManager?
    private var seriesProfileOverrides: [SeriesKey: Int] = [:]

    private let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func setInstanceManager(_ manager: InstanceManager) {
        instanceManager = manager
    }

    func loadCalendar() async {
        guard let instanceManager else {
            state = .empty
            return
        }

        state = .loading
        errorMessage = nil
        profilesByInstance = [:]
        seriesProfileOverrides = [:]

        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        let startString = apiDateFormatter.string(from: startDate)
        let endString = apiDateFormatter.string(from: endDate)

        var items: [CalendarEpisodeItem] = []
        var lastError: Error?

        for instance in instanceManager.sonarrInstances {
            guard let service = instanceManager.sonarrService(for: instance) else { continue }
            do {
                let profiles = try await service.getQualityProfiles()
                profilesByInstance[instance.id] = profiles

                let calendarEpisodes = try await service.getCalendar(startDate: startString, endDate: endString)
                for episode in calendarEpisodes {
                    items.append(CalendarEpisodeItem(episode: episode, instance: instance))
                    if let seriesId = episode.seriesId ?? episode.series?.id,
                       let profileId = episode.series?.qualityProfileId {
                        seriesProfileOverrides[SeriesKey(instanceId: instance.id, seriesId: seriesId)] = profileId
                    }
                }
            } catch {
                lastError = error
            }
        }

        if items.isEmpty {
            if let lastError {
                state = .failed(lastError)
            } else {
                state = .empty
            }
            return
        }

        let sortedItems = items.sorted { lhs, rhs in
            let leftDate = dateForEpisode(lhs.episode) ?? .distantFuture
            let rightDate = dateForEpisode(rhs.episode) ?? .distantFuture
            if leftDate == rightDate {
                return lhs.episode.series?.title ?? "" < (rhs.episode.series?.title ?? "")
            }
            return leftDate < rightDate
        }
        state = .loaded(sortedItems)
    }

    func dateForEpisode(_ episode: SonarrCalendarEpisode) -> Date? {
        let dateString = episode.airDateUtc ?? episode.airDate
        guard let dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    func formattedTime(for episode: SonarrCalendarEpisode) -> String? {
        guard let date = dateForEpisode(episode) else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    func qualityLabel(for item: CalendarEpisodeItem) -> String? {
        if let qualityName = item.episode.episodeFile?.quality?.quality?.name {
            return qualityName
        }
        if let profileName = profileName(for: item) {
            return profileName
        }
        return nil
    }

    func profileName(for item: CalendarEpisodeItem) -> String? {
        let profileId = profileId(for: item)
        guard let profileId,
              let profiles = profilesByInstance[item.instance.id] else {
            return nil
        }
        return profiles.first { $0.id == profileId }?.name
    }

    func profileId(for item: CalendarEpisodeItem) -> Int? {
        if let seriesId = item.episode.seriesId ?? item.episode.series?.id {
            let key = SeriesKey(instanceId: item.instance.id, seriesId: seriesId)
            if let override = seriesProfileOverrides[key] {
                return override
            }
        }
        return item.episode.series?.qualityProfileId
    }

    func setEpisodeMonitored(_ item: CalendarEpisodeItem, monitored: Bool) async {
        guard let instanceManager,
              let service = instanceManager.sonarrService(for: item.instance) else {
            return
        }

        updatingEpisodeIds.insert(item.id)
        let previousValue = item.episode.monitored
        updateEpisode(itemId: item.id, monitored: monitored)

        do {
            try await service.updateEpisodeMonitor(episodeIds: [item.id], monitored: monitored)
        } catch {
            updateEpisode(itemId: item.id, monitored: previousValue)
            errorMessage = error.localizedDescription
        }

        updatingEpisodeIds.remove(item.id)
    }

    func updateQualityProfile(for item: CalendarEpisodeItem, profileId: Int) async {
        guard let instanceManager,
              let service = instanceManager.sonarrService(for: item.instance),
              let seriesId = item.episode.seriesId ?? item.episode.series?.id else {
            return
        }

        let key = SeriesKey(instanceId: item.instance.id, seriesId: seriesId)
        let previousProfileId = seriesProfileOverrides[key] ?? item.episode.series?.qualityProfileId
        seriesProfileOverrides[key] = profileId

        do {
            try await service.updateSeriesQualityProfile(seriesId: seriesId, qualityProfileId: profileId)
        } catch {
            if let previousProfileId {
                seriesProfileOverrides[key] = previousProfileId
            } else {
                seriesProfileOverrides.removeValue(forKey: key)
            }
            errorMessage = error.localizedDescription
        }
    }

    private func updateEpisode(itemId: Int, monitored: Bool?) {
        guard case .loaded(var items) = state,
              let index = items.firstIndex(where: { $0.id == itemId }) else {
            return
        }
        var updatedItem = items[index]
        updatedItem.episode.monitored = monitored
        items[index] = updatedItem
        state = .loaded(items)
    }
}
