import SwiftUI

/// Vue affichée dans les résultats Siri
struct SiriResultView: View {
    let status: SiriResultStatus
    let title: String
    let message: String
    var year: String = ""
    var posterURL: URL?

    var body: some View {
        HStack(spacing: 12) {
            // Affiche le poster si disponible
            if let posterURL = posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        posterPlaceholder
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 90)
                    @unknown default:
                        posterPlaceholder
                    }
                }
            } else {
                posterPlaceholder
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    statusIcon
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                }

                if !year.isEmpty {
                    Text(year)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text(message)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 60, height: 90)
            .overlay {
                Image(systemName: "film")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
    }

    @ViewBuilder
    private var statusIcon: some View {
        Image(systemName: status.iconName)
            .foregroundColor(statusColor)
    }

    private var statusColor: Color {
        switch status {
        case .success:
            return .green
        case .alreadyAvailable:
            return .blue
        case .alreadyRequested:
            return .orange
        case .notFound:
            return .gray
        case .error:
            return .red
        }
    }
}

/// Statuts possibles pour le résultat Siri
enum SiriResultStatus {
    case success           // Téléchargement lancé avec succès
    case alreadyAvailable  // Déjà dans la bibliothèque
    case alreadyRequested  // Déjà demandé
    case notFound          // Média non trouvé
    case error             // Erreur

    var iconName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .alreadyAvailable:
            return "checkmark.seal.fill"
        case .alreadyRequested:
            return "clock.fill"
        case .notFound:
            return "questionmark.circle"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SiriResultView(
            status: .success,
            title: "Titanic",
            message: "Téléchargement lancé",
            year: "1997"
        )

        SiriResultView(
            status: .alreadyAvailable,
            title: "Inception",
            message: "Déjà disponible",
            year: "2010"
        )

        SiriResultView(
            status: .error,
            title: "Erreur",
            message: "Connexion impossible"
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
