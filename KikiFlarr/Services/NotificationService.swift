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

    func notifyDownloadCompleted(torrentName: String, torrentHash: String, instanceId: String, instanceName: String) async {
        guard downloadNotificationsEnabled else { return }
        guard isAuthorized else { return }

        // Utiliser une clé composite instance+hash pour éviter la suppression cross-instance
        let notificationKey = "\(instanceId)-\(torrentHash)"
        guard !hasAlreadyNotified(key: notificationKey) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Téléchargement terminé"
        content.body = torrentName
        content.subtitle = instanceName
        content.sound = .default
        content.categoryIdentifier = "DOWNLOAD_COMPLETE"
        content.userInfo = [
            "torrentHash": torrentHash,
            "torrentName": torrentName,
            "instanceId": instanceId,
            "instanceName": instanceName
        ]

        let request = UNNotificationRequest(
            identifier: "download-\(instanceId)-\(torrentHash)",
            content: content,
            trigger: nil // Notification immédiate
        )

        do {
            try await notificationCenter.add(request)
            markAsNotified(key: notificationKey)
        } catch {
            print("Erreur lors de l'envoi de la notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Tracking des torrents déjà notifiés

    private func hasAlreadyNotified(key: String) -> Bool {
        let notifiedTorrents = getNotifiedTorrents()
        return notifiedTorrents.contains(key)
    }

    private func markAsNotified(key: String) {
        var notifiedTorrents = getNotifiedTorrents()
        notifiedTorrents.insert(key)

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
