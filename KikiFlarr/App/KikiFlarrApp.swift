import SwiftUI

@main
struct KikiFlarrApp: App {
    @StateObject private var instanceManager = InstanceManager()

    init() {
        // Initialiser le service de notifications au lancement
        _ = NotificationService.shared
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
