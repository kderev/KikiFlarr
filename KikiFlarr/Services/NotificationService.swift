import Foundation
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()
    private let notifiedTorrentsKey = "notifiedCompletedTorrents"

    // Préférence utilisateur pour activer/désactiver les notifications
    @Published var downloadNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(downloadNotificationsEnabled, forKey: "downloadNotificationsEnabled")
        }
    }

    private init() {
        self.downloadNotificationsEnabled = UserDefaults.standard.object(forKey: "downloadNotificationsEnabled") as? Bool ?? true
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Erreur lors de la demande d'autorisation: \(error.localizedDescription)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Download Notifications

    func notifyDownloadCompleted(torrentName: String, torrentHash: String, instanceName: String) async {
        guard downloadNotificationsEnabled else { return }
        guard isAuthorized else { return }
        guard !hasAlreadyNotified(torrentHash: torrentHash) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Téléchargement terminé"
        content.body = torrentName
        content.subtitle = instanceName
        content.sound = .default
        content.categoryIdentifier = "DOWNLOAD_COMPLETE"
        content.userInfo = [
            "torrentHash": torrentHash,
            "torrentName": torrentName,
            "instanceName": instanceName
        ]

        let request = UNNotificationRequest(
            identifier: "download-\(torrentHash)",
            content: content,
            trigger: nil // Notification immédiate
        )

        do {
            try await notificationCenter.add(request)
            markAsNotified(torrentHash: torrentHash)
        } catch {
            print("Erreur lors de l'envoi de la notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Tracking des torrents déjà notifiés

    private func hasAlreadyNotified(torrentHash: String) -> Bool {
        let notifiedTorrents = getNotifiedTorrents()
        return notifiedTorrents.contains(torrentHash)
    }

    private func markAsNotified(torrentHash: String) {
        var notifiedTorrents = getNotifiedTorrents()
        notifiedTorrents.insert(torrentHash)

        // Limiter à 500 entrées pour éviter une croissance infinie
        if notifiedTorrents.count > 500 {
            let sortedTorrents = Array(notifiedTorrents)
            notifiedTorrents = Set(sortedTorrents.suffix(400))
        }

        UserDefaults.standard.set(Array(notifiedTorrents), forKey: notifiedTorrentsKey)
    }

    private func getNotifiedTorrents() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: notifiedTorrentsKey) ?? []
        return Set(array)
    }

    func clearNotifiedTorrents() {
        UserDefaults.standard.removeObject(forKey: notifiedTorrentsKey)
    }

    // MARK: - Badge Management

    func clearBadge() async {
        do {
            try await notificationCenter.setBadgeCount(0)
        } catch {
            print("Erreur lors de la réinitialisation du badge: \(error.localizedDescription)")
        }
    }

    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
}
