import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(Int)
    case timeout
    case noConnection
    case decodingError(Error)
    case encodingError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .unauthorized:
            return "Non autorisé - vérifiez votre clé API"
        case .notFound:
            return "Ressource non trouvée (404)"
        case .serverError(let code):
            return "Erreur serveur (\(code))"
        case .timeout:
            return "Délai d'attente dépassé"
        case .noConnection:
            return "Pas de connexion réseau"
        case .decodingError(let error):
            return "Erreur de décodage: \(error.localizedDescription)"
        case .encodingError:
            return "Erreur d'encodage des données"
        case .unknown(let error):
            return "Erreur inconnue: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Vérifiez l'URL de base de votre instance"
        case .unauthorized:
            return "Vérifiez que votre clé API est correcte et valide"
        case .notFound:
            return "Vérifiez que le service est correctement configuré"
        case .timeout:
            return "Vérifiez votre connexion réseau et réessayez"
        case .noConnection:
            return "Vérifiez que vous êtes connecté à Internet ou au réseau local"
        case .serverError:
            return "Le serveur rencontre un problème, réessayez plus tard"
        default:
            return nil
        }
    }
}
