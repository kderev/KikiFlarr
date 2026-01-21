import AppIntents

/// Fournit les raccourcis Siri disponibles pour KikiFlarr
/// Ces phrases seront suggérées automatiquement aux utilisateurs
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchAndDownloadIntent(),
            phrases: [
                // Phrases principales en français
                "Va chercher un média sur \(.applicationName)",
                "Télécharge un média sur \(.applicationName)",
                "Cherche un média sur \(.applicationName)",
                "Ajoute un média sur \(.applicationName)",
                "Demande un média sur \(.applicationName)",

                // Phrases avec type de média
                "Télécharge un film sur \(.applicationName)",
                "Télécharge une série sur \(.applicationName)",
                "Cherche un film sur \(.applicationName)",
                "Cherche une série sur \(.applicationName)",

                // Phrases plus naturelles
                "Je veux regarder quelque chose avec \(.applicationName)",
                "Trouve un média sur \(.applicationName)",
                "Mets un média en téléchargement sur \(.applicationName)"
            ],
            shortTitle: "Télécharger un média",
            systemImageName: "arrow.down.circle.fill"
        )
    }
}

/// Intent simple pour juste ouvrir l'app sur la recherche
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
