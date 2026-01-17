import SwiftUI

/// Vue générique pour afficher les différents états d'un LoadableState
struct LoadableView<Data, Content: View>: View {
    let state: LoadableState<Data>
    let emptyIcon: String
    let emptyTitle: String
    let emptyDescription: String
    let onRetry: () -> Void
    @ViewBuilder let content: (Data) -> Content

    init(
        state: LoadableState<Data>,
        emptyIcon: String = "tray",
        emptyTitle: String = "Aucune donnée",
        emptyDescription: String = "Aucune donnée disponible",
        onRetry: @escaping () -> Void,
        @ViewBuilder content: @escaping (Data) -> Content
    ) {
        self.state = state
        self.emptyIcon = emptyIcon
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.onRetry = onRetry
        self.content = content
    }

    var body: some View {
        switch state {
        case .idle:
            // État initial - on pourrait afficher un placeholder ou rien
            Color.clear
                .onAppear {
                    onRetry()
                }

        case .loading:
            LoadingStateView()

        case .loaded(let data):
            content(data)

        case .empty:
            EmptyStateView(
                icon: emptyIcon,
                title: emptyTitle,
                description: emptyDescription,
                onRetry: onRetry
            )

        case .failed(let error):
            ErrorStateView(error: error, onRetry: onRetry)
        }
    }
}

/// Vue pour l'état de chargement
struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Chargement...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Vue pour l'état vide
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(description)
        } actions: {
            Button("Rafraîchir") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

/// Vue pour l'état d'erreur
struct ErrorStateView: View {
    let error: AppError
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(error.title, systemImage: "exclamationmark.triangle")
        } description: {
            VStack(spacing: 8) {
                Text(error.message)
                    .multilineTextAlignment(.center)

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        } actions: {
            Button("Réessayer") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension LoadableState {
    static var previewIdle: LoadableState<String> { .idle }
    static var previewLoading: LoadableState<String> { .loading }
    static var previewLoaded: LoadableState<String> { .loaded("Sample Data") }
    static var previewEmpty: LoadableState<String> { .empty }
    static var previewFailed: LoadableState<String> {
        .failed(AppError(
            title: "Erreur de test",
            message: "Ceci est un message d'erreur de test",
            recoverySuggestion: "Veuillez réessayer"
        ))
    }
}

#Preview("Loading") {
    LoadableView(
        state: .previewLoading as LoadableState<String>,
        onRetry: {}
    ) { data in
        Text(data)
    }
}

#Preview("Empty") {
    LoadableView(
        state: .previewEmpty as LoadableState<String>,
        emptyIcon: "film",
        emptyTitle: "Aucun film",
        emptyDescription: "Votre bibliothèque est vide",
        onRetry: {}
    ) { data in
        Text(data)
    }
}

#Preview("Error") {
    LoadableView(
        state: .previewFailed as LoadableState<String>,
        onRetry: {}
    ) { data in
        Text(data)
    }
}

#Preview("Loaded") {
    LoadableView(
        state: .previewLoaded as LoadableState<String>,
        onRetry: {}
    ) { data in
        Text(data)
            .font(.largeTitle)
    }
}
#endif
