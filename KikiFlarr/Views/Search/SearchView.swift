import SwiftUI

struct SearchView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.searchResults.isEmpty {
                    ProgressView("Recherche en cours...")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Erreur", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Réessayer") {
                            viewModel.search()
                        }
                    }
                } else if viewModel.hasSearched && viewModel.searchResults.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchQuery)
                } else if viewModel.searchResults.isEmpty {
                    ContentUnavailableView {
                        Label("Rechercher", systemImage: "magnifyingglass")
                    } description: {
                        Text("Recherchez un film ou une série")
                    }
                } else {
                    resultsList
                }
            }
            .navigationTitle("Recherche")
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Film ou série..."
            )
            .onSubmit(of: .search) {
                viewModel.search()
            }
            .onAppear {
                viewModel.setInstanceManager(instanceManager)
            }
        }
    }
    
    private var resultsList: some View {
        List(viewModel.searchResults) { result in
            NavigationLink {
                DetailsView(searchResult: result)
            } label: {
                SearchResultCard(result: result)
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.search()
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(InstanceManager())
}
