import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Bibliothèque", selection: $viewModel.selectedTab) {
                    Text("Films (\(viewModel.moviesCount))").tag(LibraryViewModel.LibraryTab.movies)
                    Text("Séries (\(viewModel.seriesCount))").tag(LibraryViewModel.LibraryTab.series)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Group {
                    switch viewModel.selectedTab {
                    case .movies:
                        moviesContent
                    case .series:
                        seriesContent
                    }
                }
            }
            .navigationTitle("Bibliothèque")
            .onAppear {
                viewModel.setInstanceManager(instanceManager)
                Task {
                    await viewModel.loadAll()
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
    
    private var moviesContent: some View {
        LoadableView(
            state: viewModel.moviesState,
            emptyIcon: "film",
            emptyTitle: "Aucun film",
            emptyDescription: "Votre bibliothèque Radarr est vide",
            onRetry: {
                Task {
                    await viewModel.loadMovies()
                }
            }
        ) { movies in
            moviesList(movies: movies)
        }
    }
    
    private var seriesContent: some View {
        LoadableView(
            state: viewModel.seriesState,
            emptyIcon: "tv",
            emptyTitle: "Aucune série",
            emptyDescription: "Votre bibliothèque Sonarr est vide",
            onRetry: {
                Task {
                    await viewModel.loadSeries()
                }
            }
        ) { series in
            seriesList(series: series)
        }
    }
    
    private func moviesList(movies: [LibraryViewModel.MovieWithInstance]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 16) {
                ForEach(movies) { item in
                    NavigationLink {
                        MovieDetailView(movie: item.movie, instance: item.instance)
                    } label: {
                        MovieCard(movieID: item.movie.id, title: item.movie.title, year: item.movie.year, posterURL: item.movie.posterURL, hasFile: item.movie.hasFile ?? false, instanceName: item.instance.name)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    private func seriesList(series: [LibraryViewModel.SeriesWithInstance]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 16) {
                ForEach(series) { item in
                    NavigationLink {
                        SeriesDetailView(series: item.series, instance: item.instance)
                    } label: {
                        SeriesCard(seriesID: item.series.id, title: item.series.title, posterURL: item.series.posterURL, episodeFileCount: item.series.statistics?.episodeFileCount ?? 0, episodeCount: item.series.statistics?.episodeCount ?? 0, percentComplete: item.series.statistics?.percentOfEpisodes ?? 0, instanceName: item.instance.name)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

struct MovieCard: View, Equatable {
    let movieID: Int
    let title: String
    let year: Int
    let posterURL: URL?
    let hasFile: Bool
    let instanceName: String
    
    static func == (lhs: MovieCard, rhs: MovieCard) -> Bool {
        lhs.movieID == rhs.movieID && lhs.hasFile == rhs.hasFile
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                AsyncImageView(url: posterURL, placeholder: "film")
                    .frame(width: 100, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if hasFile {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(.white))
                        .padding(4)
                }
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Text("\(year)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(instanceName)
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.orange)
                .clipShape(Capsule())
        }
        .frame(width: 100)
    }
}

struct SeriesCard: View, Equatable {
    let seriesID: Int
    let title: String
    let posterURL: URL?
    let episodeFileCount: Int
    let episodeCount: Int
    let percentComplete: Double
    let instanceName: String
    
    static func == (lhs: SeriesCard, rhs: SeriesCard) -> Bool {
        lhs.seriesID == rhs.seriesID && lhs.episodeFileCount == rhs.episodeFileCount && lhs.episodeCount == rhs.episodeCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                AsyncImageView(url: posterURL, placeholder: "tv")
                    .frame(width: 100, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if percentComplete >= 100 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(.white))
                        .padding(4)
                }
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Text("\(episodeFileCount)/\(episodeCount) épisodes")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(instanceName)
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
        .frame(width: 100)
    }
}

#Preview {
    LibraryView()
        .environmentObject(InstanceManager())
}
