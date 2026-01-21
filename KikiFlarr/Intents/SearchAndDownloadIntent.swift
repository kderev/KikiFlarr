import AppIntents
import Foundation

/// Intent Siri pour rechercher et télécharger un média
/// Permet de dire : "Va chercher Titanic sur KikiFlarr"
struct SearchAndDownloadIntent: AppIntent {
    static var title: LocalizedStringResource = "Rechercher et télécharger"
    static var description = IntentDescription("Recherche un film ou une série et lance le téléchargement")

    /// Le nom du média à rechercher
    @Parameter(title: "Nom du média", description: "Le titre du film ou de la série à télécharger")
    var mediaName: String

    /// Type de média optionnel (film ou série)
    @Parameter(title: "Type", description: "Film ou série (optionnel)")
    var mediaType: MediaTypeParameter?

    static var parameterSummary: some ParameterSummary {
        Summary("Télécharger \(\.$mediaName)") {
            \.$mediaType
        }
    }

    // Pour supporter les phrases Siri
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Charger les instances depuis UserDefaults (partagé via App Group)
        let instanceManager = InstanceManager()

        guard let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            return .result(
                dialog: "Aucune instance Overseerr n'est configurée. Ouvrez KikiFlarr pour configurer vos services."
            ) {
                SiriResultView(
                    status: .error,
                    title: "Configuration manquante",
                    message: "Configurez Overseerr dans les paramètres"
                )
            }
        }

        do {
            // Recherche du média
            let results = try await service.search(query: mediaName)

            // Filtrer selon le type si spécifié
            var filteredResults = results.results.filter { result in
                result.mediaType == .movie || result.mediaType == .tv
            }

            if let type = mediaType {
                filteredResults = filteredResults.filter { result in
                    switch type {
                    case .movie:
                        return result.resolvedMediaType == .movie
                    case .series:
                        return result.resolvedMediaType == .tv
                    }
                }
            }

            guard let firstResult = filteredResults.first else {
                return .result(
                    dialog: "Je n'ai pas trouvé \"\(mediaName)\". Essayez avec un autre titre."
                ) {
                    SiriResultView(
                        status: .notFound,
                        title: "Aucun résultat",
                        message: "Aucun média trouvé pour \"\(mediaName)\""
                    )
                }
            }

            let displayTitle = firstResult.displayTitle
            let year = firstResult.displayYear
            let mediaTypeText = firstResult.resolvedMediaType == .movie ? "film" : "série"

            // Vérifier si déjà disponible
            if let mediaInfo = firstResult.mediaInfo {
                if mediaInfo.isAvailable {
                    return .result(
                        dialog: "\(displayTitle) (\(year)) est déjà disponible dans votre bibliothèque."
                    ) {
                        SiriResultView(
                            status: .alreadyAvailable,
                            title: displayTitle,
                            message: "Déjà disponible",
                            year: year,
                            posterURL: firstResult.fullPosterURL
                        )
                    }
                }

                if mediaInfo.isRequested {
                    return .result(
                        dialog: "\(displayTitle) (\(year)) a déjà été demandé et est en cours de téléchargement."
                    ) {
                        SiriResultView(
                            status: .alreadyRequested,
                            title: displayTitle,
                            message: "Déjà demandé",
                            year: year,
                            posterURL: firstResult.fullPosterURL
                        )
                    }
                }
            }

            // Créer la demande de téléchargement
            let request = try await service.createRequest(
                mediaType: firstResult.resolvedMediaType,
                mediaId: firstResult.id,
                is4k: false,
                seasons: firstResult.resolvedMediaType == .tv ? nil : nil // Toutes les saisons par défaut pour les séries
            )

            let statusText = request.status == 2 ? "approuvé" : "en attente d'approbation"

            return .result(
                dialog: "C'est fait ! Le \(mediaTypeText) \(displayTitle) (\(year)) a été ajouté à vos téléchargements. Statut : \(statusText)."
            ) {
                SiriResultView(
                    status: .success,
                    title: displayTitle,
                    message: "Téléchargement \(statusText)",
                    year: year,
                    posterURL: firstResult.fullPosterURL
                )
            }

        } catch {
            return .result(
                dialog: "Une erreur s'est produite lors de la recherche : \(error.localizedDescription)"
            ) {
                SiriResultView(
                    status: .error,
                    title: "Erreur",
                    message: error.localizedDescription
                )
            }
        }
    }
}

/// Paramètre de type de média pour Siri
enum MediaTypeParameter: String, AppEnum {
    case movie = "movie"
    case series = "series"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Type de média"

    static var caseDisplayRepresentations: [MediaTypeParameter: DisplayRepresentation] = [
        .movie: DisplayRepresentation(title: "Film"),
        .series: DisplayRepresentation(title: "Série")
    ]
}
