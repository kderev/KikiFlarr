import SwiftUI

struct SearchView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        NavigationStack {
            LoadableView(
                state: viewModel.state,
                emptyIcon: "magnifyingglass",
                emptyTitle: viewModel.hasSearched ? "Aucun résultat" : "Rechercher",
                emptyDescription: viewModel.hasSearched ? "Aucun résultat pour '\(viewModel.searchQuery)'" : "Recherchez un film ou une série",
                onRetry: {
                    if viewModel.hasSearched {
                        viewModel.search()
                    }
                }
            ) { results in
                resultsList(results: results)
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
    
    private func resultsList(results: [OverseerrSearchResult]) -> some View {
        List(results) { result in
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
