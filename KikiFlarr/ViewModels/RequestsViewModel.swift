import Foundation
import SwiftUI

@MainActor
class RequestsViewModel: ObservableObject {
    @Published var requestsState: LoadableState<[RequestWithMedia]> = .idle
    @Published var isRefreshing = false
    @Published var selectedFilter: RequestFilter = .all
    @Published var isPerformingAction = false
    @Published var actionError: String?
    @Published var actionSuccess: String?

    private var pageInfo: PageInfo?
    private var currentPage = 0
    private let pageSize = 20

    var hasMorePages: Bool {
        guard let pageInfo = pageInfo else { return false }
        return pageInfo.page < pageInfo.pages
    }

    var totalCount: Int {
        pageInfo?.results ?? 0
    }

    var pendingCount: Int {
        requestsState.data?.filter { $0.isPending }.count ?? 0
    }

    private weak var instanceManager: InstanceManager?

    init(instanceManager: InstanceManager? = nil) {
        self.instanceManager = instanceManager
    }

    func setInstanceManager(_ manager: InstanceManager) {
        self.instanceManager = manager
    }

    func loadRequests(reset: Bool = true) async {
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            requestsState = .failed(AppError(
                title: "Configuration manquante",
                message: "Aucune instance Overseerr configurée",
                recoverySuggestion: "Ajoutez une instance Overseerr dans les paramètres"
            ))
            return
        }

        if reset {
            currentPage = 0
            if requestsState.data == nil {
                requestsState = .loading
            }
        }

        do {
            let skip = reset ? 0 : (requestsState.data?.count ?? 0)
            let result = try await service.getRequestsWithMediaPaginated(
                take: pageSize,
                skip: skip,
                filter: selectedFilter
            )

            pageInfo = result.pageInfo

            // Sort by creation date (most recent first)
            let sortedRequests = result.requests.sorted { req1, req2 in
                guard let date1 = req1.request.createdAt,
                      let date2 = req2.request.createdAt else { return false }
                return date1 > date2
            }

            if reset {
                if sortedRequests.isEmpty {
                    requestsState = .empty
                } else {
                    requestsState = .loaded(sortedRequests)
                }
            } else {
                var existingRequests = requestsState.data ?? []
                existingRequests.append(contentsOf: sortedRequests)
                requestsState = .loaded(existingRequests)
            }

            currentPage = result.pageInfo.page

        } catch let error as NetworkError {
            requestsState = .failed(AppError(
                title: "Erreur de chargement",
                message: error.localizedDescription,
                recoverySuggestion: error.recoverySuggestion
            ))
        } catch {
            requestsState = .failed(AppError(
                title: "Erreur",
                message: error.localizedDescription,
                recoverySuggestion: "Veuillez réessayer"
            ))
        }
    }

    func loadMoreIfNeeded(currentRequest: RequestWithMedia) async {
        guard let requests = requestsState.data,
              hasMorePages,
              let lastRequest = requests.last,
              currentRequest.id == lastRequest.id else {
            return
        }

        await loadRequests(reset: false)
    }

    func refresh() async {
        isRefreshing = true
        await loadRequests(reset: true)
        isRefreshing = false
    }

    func changeFilter(_ filter: RequestFilter) async {
        selectedFilter = filter
        await loadRequests(reset: true)
    }

    func approveRequest(_ request: RequestWithMedia) async {
        await performAction(on: request) { service in
            _ = try await service.approveRequest(requestId: request.id)
            return "Requête approuvée"
        }
    }

    func declineRequest(_ request: RequestWithMedia) async {
        await performAction(on: request) { service in
            _ = try await service.declineRequest(requestId: request.id)
            return "Requête refusée"
        }
    }

    func deleteRequest(_ request: RequestWithMedia) async {
        await performAction(on: request) { service in
            try await service.deleteRequest(requestId: request.id)
            return "Requête supprimée"
        }
    }

    func retryRequest(_ request: RequestWithMedia) async {
        await performAction(on: request) { service in
            _ = try await service.retryRequest(requestId: request.id)
            return "Requête relancée"
        }
    }

    private func performAction(on request: RequestWithMedia, action: (OverseerrService) async throws -> String) async {
        guard let instanceManager = instanceManager,
              let overseerrInstance = instanceManager.primaryOverseerr,
              let service = instanceManager.overseerrService(for: overseerrInstance) else {
            actionError = "Instance Overseerr non configurée"
            return
        }

        isPerformingAction = true
        actionError = nil
        actionSuccess = nil

        do {
            let successMessage = try await action(service)
            actionSuccess = successMessage

            // Reload requests to reflect changes
            await loadRequests(reset: true)

            // Auto-dismiss success message after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            actionSuccess = nil
        } catch let error as NetworkError {
            actionError = error.localizedDescription
        } catch {
            actionError = error.localizedDescription
        }

        isPerformingAction = false
    }

    func clearMessages() {
        actionError = nil
        actionSuccess = nil
    }
}
