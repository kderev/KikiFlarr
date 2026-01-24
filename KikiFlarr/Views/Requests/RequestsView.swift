import SwiftUI

struct RequestsView: View {
    @EnvironmentObject var instanceManager: InstanceManager
    @StateObject private var viewModel = RequestsViewModel()
    @State private var selectedRequest: RequestWithMedia?
    @State private var showingDeleteConfirmation = false
    @State private var requestToDelete: RequestWithMedia?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker

                ZStack {
                    requestsContent

                    if viewModel.isPerformingAction {
                        actionOverlay
                    }
                }

                if let success = viewModel.actionSuccess {
                    successBanner(message: success)
                }

                if let error = viewModel.actionError {
                    errorBanner(message: error)
                }
            }
            .navigationTitle("Requêtes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.totalCount > 0 {
                        Text("\(viewModel.totalCount) requête(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                viewModel.setInstanceManager(instanceManager)
                Task {
                    await viewModel.loadRequests()
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert("Supprimer la requête", isPresented: $showingDeleteConfirmation, presenting: requestToDelete) { request in
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    Task {
                        await viewModel.deleteRequest(request)
                    }
                }
            } message: { request in
                Text("Voulez-vous vraiment supprimer la requête pour \"\(request.title)\" ?")
            }
        }
    }

    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "Toutes",
                    isSelected: viewModel.selectedFilter == .all,
                    count: nil
                ) {
                    Task { await viewModel.changeFilter(.all) }
                }

                FilterChip(
                    title: "En attente",
                    isSelected: viewModel.selectedFilter == .pending,
                    count: viewModel.pendingCount > 0 ? viewModel.pendingCount : nil,
                    badgeColor: .yellow
                ) {
                    Task { await viewModel.changeFilter(.pending) }
                }

                FilterChip(
                    title: "Approuvées",
                    isSelected: viewModel.selectedFilter == .approved,
                    count: nil
                ) {
                    Task { await viewModel.changeFilter(.approved) }
                }

                FilterChip(
                    title: "Disponibles",
                    isSelected: viewModel.selectedFilter == .available,
                    count: nil
                ) {
                    Task { await viewModel.changeFilter(.available) }
                }

                FilterChip(
                    title: "En cours",
                    isSelected: viewModel.selectedFilter == .processing,
                    count: nil
                ) {
                    Task { await viewModel.changeFilter(.processing) }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private var requestsContent: some View {
        LoadableView(
            state: viewModel.requestsState,
            emptyIcon: "tray",
            emptyTitle: "Aucune requête",
            emptyDescription: filterEmptyDescription,
            onRetry: {
                Task {
                    await viewModel.loadRequests()
                }
            }
        ) { requests in
            requestsList(requests: requests)
        }
    }

    private var filterEmptyDescription: String {
        switch viewModel.selectedFilter {
        case .all:
            return "Aucune requête n'a été effectuée"
        case .pending:
            return "Aucune requête en attente d'approbation"
        case .approved:
            return "Aucune requête approuvée"
        case .available:
            return "Aucun média disponible"
        case .processing:
            return "Aucun téléchargement en cours"
        case .unavailable:
            return "Aucune requête indisponible"
        }
    }

    private func requestsList(requests: [RequestWithMedia]) -> some View {
        List {
            ForEach(requests) { request in
                RequestRow(request: request)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if request.canBeApproved {
                            Button {
                                Task {
                                    await viewModel.approveRequest(request)
                                }
                            } label: {
                                Label("Approuver", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            requestToDelete = request
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }

                        if request.canBeDeclined {
                            Button {
                                Task {
                                    await viewModel.declineRequest(request)
                                }
                            } label: {
                                Label("Refuser", systemImage: "xmark")
                            }
                            .tint(.orange)
                        }
                    }
                    .onAppear {
                        Task {
                            await viewModel.loadMoreIfNeeded(currentRequest: request)
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    private var actionOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                Text("Traitement en cours...")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func successBanner(message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button {
                viewModel.clearMessages()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var count: Int? = nil
    var badgeColor: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badgeColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct RequestRow: View {
    let request: RequestWithMedia

    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: request.fullPosterURL, placeholder: "photo")
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(request.title)
                        .font(.headline)
                        .lineLimit(2)

                    if request.request.is4k == true {
                        Text("4K")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                HStack(spacing: 8) {
                    mediaTypeTag

                    if !request.year.isEmpty {
                        Text(request.year)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    requestStatusBadge
                    downloadStatusBadge
                }

                if let user = request.request.requestedBy {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                        Text(user.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                if let date = request.request.formattedCreatedAt {
                    Text(date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if request.canBeApproved {
                VStack(spacing: 8) {
                    Button {
                        // Will be handled by parent view via Task
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    .disabled(true) // Disabled as swipe actions are preferred
                    .opacity(0.5)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var mediaTypeTag: some View {
        HStack(spacing: 2) {
            Image(systemName: request.request.type == "movie" ? "film" : "tv")
                .font(.caption2)
            Text(request.request.type == "movie" ? "Film" : "Série")
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(request.request.type == "movie" ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
        .foregroundColor(request.request.type == "movie" ? .orange : .blue)
        .clipShape(Capsule())
    }

    private var requestStatusBadge: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(requestStatusColor)
                .frame(width: 6, height: 6)
            Text(request.requestStatusDescription)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(requestStatusColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var requestStatusColor: Color {
        switch request.request.requestStatus {
        case .pending: return .yellow
        case .approved: return .green
        case .declined: return .red
        case .unknown: return .gray
        }
    }

    private var downloadStatusBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: downloadStatusIcon)
                .font(.caption2)
            Text(request.downloadStatusDescription)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(downloadStatusColorValue.opacity(0.1))
        .foregroundColor(downloadStatusColorValue)
        .clipShape(Capsule())
    }

    private var downloadStatusIcon: String {
        switch request.downloadStatus {
        case .available: return "checkmark.circle.fill"
        case .partiallyAvailable: return "circle.lefthalf.filled"
        case .downloading: return "arrow.down.circle"
        case .pending: return "clock"
        case .unknown: return "questionmark.circle"
        }
    }

    private var downloadStatusColorValue: Color {
        switch request.downloadStatus {
        case .available: return .green
        case .partiallyAvailable: return .orange
        case .downloading: return .blue
        case .pending: return .yellow
        case .unknown: return .gray
        }
    }
}

#Preview {
    RequestsView()
        .environmentObject(InstanceManager())
}
