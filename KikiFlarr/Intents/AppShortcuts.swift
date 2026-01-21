import AppIntents

/// Fournit les raccourcis Siri disponibles pour KikiFlarr
/// Ces phrases seront suggérées automatiquement aux utilisateurs
@available(iOS 16.0, *)
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchAndDownloadIntent(),
            phrases: [
                // Phrases principales en français
                "Va chercher \(\.$mediaName) sur \(.applicationName)",
                "Télécharge \(\.$mediaName) sur \(.applicationName)",
                "Cherche \(\.$mediaName) sur \(.applicationName)",
                "Ajoute \(\.$mediaName) sur \(.applicationName)",
                "Demande \(\.$mediaName) sur \(.applicationName)",

                // Phrases avec type de média
                "Télécharge le film \(\.$mediaName) sur \(.applicationName)",
                "Télécharge la série \(\.$mediaName) sur \(.applicationName)",
                "Cherche le film \(\.$mediaName) sur \(.applicationName)",
                "Cherche la série \(\.$mediaName) sur \(.applicationName)",

                // Phrases plus naturelles
                "Je veux regarder \(\.$mediaName) avec \(.applicationName)",
                "Trouve \(\.$mediaName) sur \(.applicationName)",
                "Mets \(\.$mediaName) en téléchargement sur \(.applicationName)"
            ],
            shortTitle: "Télécharger un média",
            systemImageName: "arrow.down.circle.fill"
        )
    }
}

/// Intent simple pour juste ouvrir l'app sur la recherche
@available(iOS 16.0, *)
struct OpenSearchIntent: AppIntent {
    static var title: LocalizedStringResource = "Ouvrir la recherche"
    static var description = IntentDescription("Ouvre KikiFlarr sur l'écran de recherche")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // L'app s'ouvrira automatiquement grâce à openAppWhenRun
        return .result()
    }
}

/// Intent pour voir les téléchargements en cours
@available(iOS 16.0, *)
struct CheckDownloadsIntent: AppIntent {
    static var title: LocalizedStringResource = "Voir les téléchargements"
    static var description = IntentDescription("Affiche les téléchargements en cours")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Notifier l'app qu'elle doit ouvrir l'onglet Downloads
        UserDefaults.standard.set("downloads", forKey: "siri.openTab")
        return .result()
    }
}
