import SwiftUI

struct DetailsView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel: DetailsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(searchResult: OverseerrSearchResult) {
        _viewModel = StateObject(wrappedValue: DetailsViewModel(searchResult: searchResult))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                
                VStack(alignment: .leading, spacing: 20) {
                    infoSection
                    
                    // Indicateur de chargement pour les détails additionnels
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                            Text("Chargement des détails...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    
                    // Message d'erreur si le chargement a échoué
                    if let error = viewModel.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Synopsis en premier - utilise searchResult comme fallback
                    if let overview = viewModel.movieDetails?.overview ?? viewModel.tvDetails?.overview ?? viewModel.searchResult.overview,
                       !overview.isEmpty {
                        synopsisSection(overview: overview)
                    }
                    
                    // Cast après le synopsis
                    if let credits = viewModel.movieDetails?.credits ?? viewModel.tvDetails?.credits,
                       let cast = credits.cast, !cast.isEmpty {
                        castSection(cast: Array(cast.prefix(10)))
                    }
                    
                    // Saisons pour les séries (avant les options d'ajout)
                    if viewModel.isTVShow, let seasons = viewModel.tvDetails?.seasons {
                        seasonsSection(seasons: seasons)
                    }
                    
                    // Section d'ajout en bas après tout le contenu informatif
                    addSection
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setInstanceManager(instanceManager)
            Task {
                await viewModel.loadDetails()
            }
        }
        .alert("Ajouté avec succès", isPresented: $viewModel.addSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(viewModel.isMovie ? "Le film a été ajouté à Radarr" : "La série a été ajoutée à Sonarr")
        }
        .alert("Demande envoyée", isPresented: $viewModel.overseerrRequestSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Votre demande a été envoyée via Overseerr")
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            BackdropImageView(
                url: viewModel.movieDetails?.fullBackdropURL ?? viewModel.tvDetails?.fullBackdropURL ?? viewModel.searchResult.fullBackdropURL,
                height: 300
            )
            .overlay(
                LinearGradient(
                    colors: [.clear, .clear, Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            HStack(alignment: .bottom, spacing: 16) {
                PosterImageView(
                    url: viewModel.movieDetails?.fullPosterURL ?? viewModel.tvDetails?.fullPosterURL ?? viewModel.searchResult.fullPosterURL,
                    width: 100
                )
                .shadow(radius: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.movieDetails?.title ?? viewModel.tvDetails?.name ?? viewModel.searchResult.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Text(viewModel.movieDetails?.displayYear ?? viewModel.tvDetails?.displayYear ?? viewModel.searchResult.displayYear)
                            .foregroundColor(.secondary)
                        
                        if let runtime = viewModel.movieDetails?.formattedRuntime ?? viewModel.tvDetails?.formattedRuntime {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(runtime)
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.subheadline)
                    
                    if let voteAverage = viewModel.movieDetails?.voteAverage ?? viewModel.tvDetails?.voteAverage ?? viewModel.searchResult.voteAverage,
                       voteAverage > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(Formatters.formatVoteAverage(voteAverage))
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let genres = viewModel.movieDetails?.genres ?? viewModel.tvDetails?.genres, !genres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(genres) { genre in
                            Text(genre.name)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            if let status = viewModel.movieDetails?.status ?? viewModel.tvDetails?.status {
                HStack {
                    Text("Statut:")
                        .foregroundColor(.secondary)
                    Text(status)
                }
                .font(.subheadline)
            }
            
            if viewModel.isTVShow {
                if let seasons = viewModel.tvDetails?.numberOfSeasons,
                   let episodes = viewModel.tvDetails?.numberOfEpisodes {
                    HStack {
                        Text("\(seasons) saisons")
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(episodes) épisodes")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Seasons Section
    
    private func seasonsSection(seasons: [OverseerrTVSeason]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saisons")
                    .font(.headline)
                
                Spacer()
                
                Button("Tout") {
                    viewModel.selectAllSeasons()
                }
                .font(.caption)
                
                Button("Aucun") {
                    viewModel.deselectAllSeasons()
                }
                .font(.caption)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                ForEach(seasons.filter { $0.seasonNumber > 0 }) { season in
                    Button {
                        viewModel.toggleSeason(season.seasonNumber)
                    } label: {
                        Text("S\(season.seasonNumber)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(minWidth: 50)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedSeasons.contains(season.seasonNumber)
                                    ? Color.blue
                                    : Color.secondary.opacity(0.2)
                            )
                            .foregroundColor(
                                viewModel.selectedSeasons.contains(season.seasonNumber)
                                    ? .white
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Add Section
    
    private var addSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ajouter au téléchargement")
                .font(.headline)
            
            if viewModel.isAlreadyAvailable {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Déjà disponible dans votre bibliothèque")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            } else if viewModel.isRequested {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Demande en cours de traitement")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            } else {
                if viewModel.isMovie {
                    movieAddOptions
                } else {
                    tvAddOptions
                }
                
                if viewModel.canRequestOverseerr {
                    Divider()
                        .padding(.vertical, 8)
                    
                    overseerrRequestButton
                }
            }
            
            if let error = viewModel.addErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var movieAddOptions: some View {
        VStack(spacing: 12) {
            if instanceManager.radarrInstances.isEmpty {
                Text("Aucune instance Radarr configurée")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                Picker("Instance Radarr", selection: $viewModel.selectedRadarrInstance) {
                    ForEach(instanceManager.radarrInstances) { instance in
                        Text(instance.name).tag(Optional(instance))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedRadarrInstance) { _, _ in
                    Task {
                        await viewModel.loadRadarrOptions()
                    }
                }
                
                if !viewModel.radarrProfiles.isEmpty {
                    Picker("Profil qualité", selection: $viewModel.selectedQualityProfileId) {
                        ForEach(viewModel.radarrProfiles) { profile in
                            Text(profile.name).tag(Optional(profile.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if !viewModel.radarrRootFolders.isEmpty {
                    Picker("Dossier", selection: $viewModel.selectedRootFolderId) {
                        ForEach(viewModel.radarrRootFolders) { folder in
                            Text(folder.path).tag(Optional(folder.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Button {
                    Task {
                        await viewModel.addToRadarr()
                    }
                } label: {
                    HStack {
                        if viewModel.isAdding {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text("Ajouter à Radarr")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.isAdding || viewModel.selectedQualityProfileId == nil)
            }
        }
    }
    
    private var tvAddOptions: some View {
        VStack(spacing: 12) {
            if instanceManager.sonarrInstances.isEmpty {
                Text("Aucune instance Sonarr configurée")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                Picker("Instance Sonarr", selection: $viewModel.selectedSonarrInstance) {
                    ForEach(instanceManager.sonarrInstances) { instance in
                        Text(instance.name).tag(Optional(instance))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedSonarrInstance) { _, _ in
                    Task {
                        await viewModel.loadSonarrOptions()
                    }
                }
                
                if !viewModel.sonarrProfiles.isEmpty {
                    Picker("Profil qualité", selection: $viewModel.selectedQualityProfileId) {
                        ForEach(viewModel.sonarrProfiles) { profile in
                            Text(profile.name).tag(Optional(profile.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if !viewModel.sonarrRootFolders.isEmpty {
                    Picker("Dossier", selection: $viewModel.selectedRootFolderId) {
                        ForEach(viewModel.sonarrRootFolders) { folder in
                            Text(folder.path).tag(Optional(folder.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Button {
                    Task {
                        await viewModel.addToSonarr()
                    }
                } label: {
                    HStack {
                        if viewModel.isAdding {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text("Ajouter à Sonarr")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.isAdding || viewModel.selectedSeasons.isEmpty || viewModel.selectedQualityProfileId == nil)
            }
        }
    }
    
    // MARK: - Overseerr Request
    
    private var overseerrRequestButton: some View {
        VStack(spacing: 12) {
            // Compact header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Overseerr")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 4K toggle inline
                HStack(spacing: 6) {
                    Text("4K")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.is4K ? .purple : .secondary)
                    
                    Toggle("", isOn: $viewModel.is4K)
                        .labelsHidden()
                        .scaleEffect(0.8)
                        .tint(.purple)
                }
            }
            
            // Server + options in single row when possible
            HStack(spacing: 8) {
                // Server picker
                if viewModel.isMovie && !viewModel.overseerrRadarrServers.isEmpty {
                    overseerrCompactMenu(
                        icon: "server.rack",
                        selection: viewModel.overseerrRadarrServers.first { $0.id == viewModel.selectedOverseerrServer }?.name ?? "Serveur"
                    ) {
                        ForEach(viewModel.overseerrRadarrServers) { server in
                            Button {
                                viewModel.selectedOverseerrServer = server.id
                                Task {
                                    await viewModel.loadOverseerrServerProfiles(serverId: server.id, isMovie: true)
                                }
                            } label: {
                                HStack {
                                    Text(server.name)
                                    if viewModel.selectedOverseerrServer == server.id {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if viewModel.isTVShow && !viewModel.overseerrSonarrServers.isEmpty {
                    overseerrCompactMenu(
                        icon: "server.rack",
                        selection: viewModel.overseerrSonarrServers.first { $0.id == viewModel.selectedOverseerrServer }?.name ?? "Serveur"
                    ) {
                        ForEach(viewModel.overseerrSonarrServers) { server in
                            Button {
                                viewModel.selectedOverseerrServer = server.id
                                Task {
                                    await viewModel.loadOverseerrServerProfiles(serverId: server.id, isMovie: false)
                                }
                            } label: {
                                HStack {
                                    Text(server.name)
                                    if viewModel.selectedOverseerrServer == server.id {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Quality picker
                if !viewModel.overseerrProfiles.isEmpty {
                    overseerrCompactMenu(
                        icon: "sparkles.tv",
                        selection: viewModel.overseerrProfiles.first { $0.id == viewModel.selectedOverseerrProfileId }?.name ?? "Qualité"
                    ) {
                        ForEach(viewModel.overseerrProfiles) { profile in
                            Button {
                                viewModel.selectedOverseerrProfileId = profile.id
                            } label: {
                                HStack {
                                    Text(profile.name)
                                    if viewModel.selectedOverseerrProfileId == profile.id {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Folder picker on separate row if needed
            if !viewModel.overseerrRootFolders.isEmpty {
                overseerrCompactMenu(
                    icon: "folder.fill",
                    selection: viewModel.selectedOverseerrRootFolder?.components(separatedBy: "/").last ?? "Dossier",
                    fullWidth: true
                ) {
                    ForEach(viewModel.overseerrRootFolders) { folder in
                        Button {
                            viewModel.selectedOverseerrRootFolder = folder.path
                        } label: {
                            HStack {
                                Text(folder.path)
                                if viewModel.selectedOverseerrRootFolder == folder.path {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
            }
            
            // Request button
            Button {
                Task {
                    await viewModel.requestViaOverseerr()
                }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isRequestingOverseerr {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12, weight: .medium))
                    }
                    Text("Demander")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.6, green: 0.2, blue: 0.9), Color(red: 0.8, green: 0.3, blue: 0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .purple.opacity(0.3), radius: 4, y: 2)
            }
            .disabled(viewModel.isRequestingOverseerr || (viewModel.isTVShow && viewModel.selectedSeasons.isEmpty))
            .opacity((viewModel.isRequestingOverseerr || (viewModel.isTVShow && viewModel.selectedSeasons.isEmpty)) ? 0.5 : 1)
        }
    }
    
    @ViewBuilder
    private func overseerrCompactMenu<Content: View>(
        icon: String,
        selection: String,
        fullWidth: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.purple)
                
                Text(selection)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Synopsis Section
    
    private func synopsisSection(overview: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)
            
            Text(overview)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Cast Section
    
    private func castSection(cast: [OverseerrCastMember]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distribution")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cast) { member in
                        VStack(spacing: 4) {
                            AsyncImage(url: member.profileURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.2)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            
                            Text(member.name)
                                .font(.caption2)
                                .lineLimit(1)
                            
                            if let character = member.character {
                                Text(character)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 80)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailsView(searchResult: OverseerrSearchResult(
            id: 550,
            mediaType: .movie,
            popularity: 100,
            posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
            backdropPath: "/hZkgoQYus5vegHoetLkCJzb17zJ.jpg",
            voteCount: 1000,
            voteAverage: 8.5,
            genreIds: nil,
            overview: "Un employé de bureau insomniaque et un fabricant de savon forment un club de combat clandestin qui évolue en quelque chose de beaucoup plus grand.",
            originalLanguage: "en",
            title: "Fight Club",
            originalTitle: nil,
            releaseDate: "1999-10-15",
            adult: false,
            video: false,
            name: nil,
            originalName: nil,
            firstAirDate: nil,
            originCountry: nil,
            mediaInfo: nil
        ))
    }
    .environmentObject(InstanceManager())
}
