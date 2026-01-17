import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24, pinnedViews: []) {
                    if !viewModel.recentRequests.isEmpty {
                        requestsSection
                    }
                    
                    if !viewModel.trendingMovies.isEmpty {
                        trendingMoviesSection
                    }
                    
                    if !viewModel.trendingTV.isEmpty {
                        trendingTVSection
                    }
                    
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.top, 50)
                    }
                    
                    if let error = viewModel.errorMessage {
                        ContentUnavailableView {
                            Label("Erreur", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(error)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Découvrir")
            .searchable(text: $searchText, prompt: "Rechercher un film ou série...")
            .onSubmit(of: .search) {
                isSearching = true
            }
            .navigationDestination(isPresented: $isSearching) {
                SearchResultsView(query: searchText)
            }
            .onAppear {
                viewModel.setInstanceManager(instanceManager)
                if viewModel.trendingMovies.isEmpty {
                    Task {
                        await viewModel.loadAll()
                    }
                }
            }
            .refreshable {
                await viewModel.loadAll()
            }
        }
    }
    
    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Demandes récentes")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.recentRequests) { requestWithMedia in
                        RequestCard(requestWithMedia: requestWithMedia)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var trendingMoviesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Films populaires")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    AllMediaView(title: "Films populaires", results: viewModel.trendingMovies)
                } label: {
                    Text("Voir tout")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.trendingMovies) { result in
                        NavigationLink {
                            DetailsView(searchResult: result)
                        } label: {
                            MediaPosterCard(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var trendingTVSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Séries populaires")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    AllMediaView(title: "Séries populaires", results: viewModel.trendingTV)
                } label: {
                    Text("Voir tout")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.trendingTV) { result in
                        NavigationLink {
                            DetailsView(searchResult: result)
                        } label: {
                            MediaPosterCard(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct MediaPosterCard: View, Equatable {
    let result: OverseerrSearchResult
    
    static func == (lhs: MediaPosterCard, rhs: MediaPosterCard) -> Bool {
        lhs.result.id == rhs.result.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                AsyncImageView(url: result.fullPosterURL, placeholder: "photo")
                    .frame(width: 110, height: 165)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if let mediaInfo = result.mediaInfo {
                    statusBadge(mediaInfo: mediaInfo)
                }
            }
            
            Text(result.displayTitle)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
            
            HStack(spacing: 4) {
                Text(result.displayYear)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let vote = result.voteAverage, vote > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", vote))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(width: 110)
    }
    
    @ViewBuilder
    private func statusBadge(mediaInfo: OverseerrMediaInfo) -> some View {
        if mediaInfo.isAvailable {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .background(Circle().fill(.white))
                .padding(4)
        } else if mediaInfo.isRequested {
            Image(systemName: "clock.fill")
                .foregroundColor(.blue)
                .background(Circle().fill(.white))
                .padding(4)
        }
    }
}

struct RequestCard: View, Equatable {
    let requestWithMedia: RequestWithMedia
    
    static func == (lhs: RequestCard, rhs: RequestCard) -> Bool {
        lhs.requestWithMedia.request.id == rhs.requestWithMedia.request.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImageView(url: requestWithMedia.fullPosterURL, placeholder: "photo")
                    .frame(width: 110, height: 165)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                downloadStatusBadge
            }
            
            Text(requestWithMedia.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
            
            HStack(spacing: 4) {
                Image(systemName: requestWithMedia.request.type == "movie" ? "film" : "tv")
                    .font(.system(size: 10))
                    .foregroundColor(requestWithMedia.request.type == "movie" ? .orange : .blue)
                
                if !requestWithMedia.year.isEmpty {
                    Text(requestWithMedia.year)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                
                Text(requestWithMedia.downloadStatusDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let user = requestWithMedia.request.requestedBy {
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 10))
                    Text(user.displayName)
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .frame(width: 110)
    }
    
    private var statusColor: Color {
        switch requestWithMedia.downloadStatus {
        case .available: return .green
        case .partiallyAvailable: return .orange
        case .downloading: return .blue
        case .pending: return .yellow
        case .unknown: return .gray
        }
    }
    
    @ViewBuilder
    private var downloadStatusBadge: some View {
        switch requestWithMedia.downloadStatus {
        case .available:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .background(Circle().fill(.white))
                .padding(4)
        case .partiallyAvailable:
            Image(systemName: "circle.lefthalf.filled")
                .foregroundColor(.orange)
                .background(Circle().fill(.white))
                .padding(4)
        case .downloading:
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.blue)
                .background(Circle().fill(.white))
                .padding(4)
        case .pending:
            Image(systemName: "clock.fill")
                .foregroundColor(.yellow)
                .background(Circle().fill(.white))
                .padding(4)
        case .unknown:
            EmptyView()
        }
    }
}

struct AllMediaView: View {
    let title: String
    let results: [OverseerrSearchResult]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 16) {
                ForEach(results) { result in
                    NavigationLink {
                        DetailsView(searchResult: result)
                    } label: {
                        MediaPosterCard(result: result)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(title)
    }
}

struct SearchResultsView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = SearchViewModel()
    let query: String

    var body: some View {
        LoadableView(
            state: viewModel.state,
            emptyIcon: "magnifyingglass",
            emptyTitle: "Aucun résultat",
            emptyDescription: "Aucun résultat pour '\(query)'",
            onRetry: {
                viewModel.search()
            }
        ) { results in
            List(results) { result in
                NavigationLink {
                    DetailsView(searchResult: result)
                } label: {
                    SearchResultCard(result: result)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Résultats")
        .onAppear {
            viewModel.setInstanceManager(instanceManager)
            viewModel.searchQuery = query
            viewModel.search()
        }
    }
}

#Preview {
    DiscoverView()
        .environmentObject(InstanceManager())
}
