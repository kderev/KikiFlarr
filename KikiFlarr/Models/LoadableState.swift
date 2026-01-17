import Foundation

/// Représente une erreur applicative avec un message user-friendly
struct AppError: Error {
    let title: String
    let message: String
    let recoverySuggestion: String?

    init(title: String = "Erreur", message: String, recoverySuggestion: String? = nil) {
        self.title = title
        self.message = message
        self.recoverySuggestion = recoverySuggestion
    }

    /// Crée un AppError à partir d'une erreur système
    static func from(_ error: Error) -> AppError {
        if let networkError = error as? NetworkError {
            // Améliorer le message pour les erreurs de décodage
            if case .decodingError(let underlyingError) = networkError {
                let decodingContext = (underlyingError as? DecodingError).map { decodingError -> String in
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        return "Clé manquante: \(key.stringValue) - \(context.debugDescription)"
                    case .typeMismatch(let type, let context):
                        return "Type incorrect: attendu \(type) - \(context.debugDescription)"
                    case .valueNotFound(let type, let context):
                        return "Valeur manquante pour type \(type) - \(context.debugDescription)"
                    case .dataCorrupted(let context):
                        return "Données corrompues: \(context.debugDescription)"
                    @unknown default:
                        return underlyingError.localizedDescription
                    }
                } ?? underlyingError.localizedDescription

                print("❌ Erreur de décodage détaillée: \(decodingContext)")

                return AppError(
                    title: "Erreur de décodage",
                    message: "Impossible de lire les données du serveur",
                    recoverySuggestion: "Vérifiez que votre instance Overseerr est à jour"
                )
            }

            return AppError(
                title: "Erreur réseau",
                message: networkError.errorDescription ?? "Une erreur réseau s'est produite",
                recoverySuggestion: networkError.recoverySuggestion
            )
        }

        return AppError(
            title: "Erreur",
            message: error.localizedDescription,
            recoverySuggestion: "Veuillez réessayer"
        )
    }
}

/// État chargeable générique pour gérer les différents états d'une vue
enum LoadableState<T> {
    /// État initial, aucune donnée chargée
    case idle
    /// Chargement en cours
    case loading
    /// Données chargées avec succès
    case loaded(T)
    /// Aucune donnée disponible (liste vide après chargement réussi)
    case empty
    /// Erreur lors du chargement
    case failed(AppError)

    /// Retourne true si l'état est en cours de chargement
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    /// Retourne les données si elles sont chargées, sinon nil
    var data: T? {
        if case .loaded(let data) = self {
            return data
        }
        return nil
    }

    /// Retourne l'erreur si elle existe, sinon nil
    var error: AppError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }

    /// Retourne true si l'état est vide
    var isEmpty: Bool {
        if case .empty = self {
            return true
        }
        return false
    }

    /// Retourne true si l'état est idle
    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }
}

// Extension pour faciliter la transformation des états
extension LoadableState {
    /// Transforme un état chargé en utilisant une fonction de mapping
    func map<U>(_ transform: (T) -> U) -> LoadableState<U> {
        switch self {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case .loaded(let data):
            return .loaded(transform(data))
        case .empty:
            return .empty
        case .failed(let error):
            return .failed(error)
        }
    }
}
