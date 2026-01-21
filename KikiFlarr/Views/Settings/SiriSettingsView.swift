import SwiftUI
import AppIntents

/// Vue de configuration des raccourcis Siri
struct SiriSettingsView: View {
    @State private var showingSiriTips = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.linearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Siri est activé")
                                .font(.headline)
                            Text("Demandez à Siri de télécharger vos médias")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Section {
                ForEach(siriPhrases, id: \.self) { phrase in
                    HStack {
                        Image(systemName: "quote.bubble")
                            .foregroundColor(.purple)
                        Text(phrase)
                            .font(.subheadline)
                    }
                }
            } header: {
                Text("Exemples de commandes")
            } footer: {
                Text("Dites \"Dis Siri\" suivi d'une de ces phrases pour télécharger un média.")
            }

            Section {
                NavigationLink {
                    SiriTipsView()
                } label: {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Conseils d'utilisation")
                    }
                }

                if #available(iOS 17.0, *) {
                    Button {
                        openSiriSettings()
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                            Text("Réglages Siri")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Plus d'options")
            }
        }
        .navigationTitle("Siri")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var siriPhrases: [String] {
        [
            "\"Va chercher Titanic sur KikiFlarr\"",
            "\"Télécharge Inception sur KikiFlarr\"",
            "\"Cherche Breaking Bad sur KikiFlarr\"",
            "\"Ajoute The Office sur KikiFlarr\""
        ]
    }

    private func openSiriSettings() {
        if let url = URL(string: "App-prefs:SIRI") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

/// Vue avec des conseils pour utiliser Siri
struct SiriTipsView: View {
    var body: some View {
        List {
            Section {
                TipRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    title: "Soyez précis",
                    description: "Utilisez le titre exact du film ou de la série pour de meilleurs résultats."
                )

                TipRow(
                    icon: "film.fill",
                    iconColor: .blue,
                    title: "Films vs Séries",
                    description: "Dites \"le film\" ou \"la série\" pour préciser le type si nécessaire."
                )

                TipRow(
                    icon: "clock.fill",
                    iconColor: .orange,
                    title: "Patience",
                    description: "La recherche peut prendre quelques secondes selon votre connexion."
                )

                TipRow(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .yellow,
                    title: "Configuration requise",
                    description: "Assurez-vous qu'Overseerr est configuré dans les paramètres de l'app."
                )
            } header: {
                Text("Conseils")
            }

            Section {
                TipRow(
                    icon: "wifi.slash",
                    iconColor: .red,
                    title: "Erreur de connexion",
                    description: "Vérifiez que vous êtes connecté à internet et/ou au VPN."
                )

                TipRow(
                    icon: "magnifyingglass",
                    iconColor: .gray,
                    title: "Média non trouvé",
                    description: "Essayez avec un autre titre ou vérifiez l'orthographe."
                )

                TipRow(
                    icon: "checkmark.seal.fill",
                    iconColor: .blue,
                    title: "Déjà disponible",
                    description: "Si le média est déjà dans votre bibliothèque, Siri vous le dira."
                )
            } header: {
                Text("Résolution de problèmes")
            }
        }
        .navigationTitle("Conseils")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Ligne de conseil réutilisable
struct TipRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SiriSettingsView()
    }
}
