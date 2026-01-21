import SwiftUI
import AppIntents

@main
struct KikiFlarrApp: App {
    @StateObject private var instanceManager = InstanceManager()

    init() {
        // Initialiser le service de notifications au lancement
        _ = NotificationService.shared

        // Enregistrer les raccourcis Siri
        if #available(iOS 16.0, *) {
            updateSiriShortcuts()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(instanceManager)
                .task {
                    // Demander l'autorisation de notifications si pas encore déterminée
                    await NotificationService.shared.checkAuthorizationStatus()
                    if NotificationService.shared.authorizationStatus == .notDetermined {
                        _ = await NotificationService.shared.requestAuthorization()
                    }
                    // Effacer le badge au lancement
                    await NotificationService.shared.clearBadge()
                }
        }
    }
}
