//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

typealias QueueOfflineRequestBlock = (DataEndpoint) -> Void
typealias DataEndpoint = Endpoint<Data>

extension Endpoint {
    var withDataResponse: DataEndpoint {
        DataEndpoint(
            path: path,
            method: method,
            queryItems: queryItems,
            requiresConnectionId: requiresConnectionId,
            requiresToken: requiresToken,
            body: body
        )
    }
}

/// OfflineRequestsRepository handles both the enqueuing and the execution of offline requests when needed.
/// When running the queued requests, it basically passes the requests on to the APIClient, and waits for its result.
class OfflineRequestsRepository {
    let database: DatabaseContainer
    let apiClient: APIClient

    /// Serial queue used to enqueue pending requests one after another
    private let retryQueue = DispatchQueue(label: "com.stream.queue-requests")

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }

    /// - If the requests succeeds -> The request is removed from the pending ones
    /// - If the request fails with a connection error -> The request is kept to be executed once the connection is back (we are not putting it back at the queue to make sure we respect the order)
    /// - If the request fails with any other error -> We are dismissing the request, and removing it from the queue
    func runQueuedRequests(completion: @escaping () -> Void) {
        var pendingActions: [(String, Data)] = []

        let readContext = database.backgroundReadOnlyContext
        readContext.performAndWait {
            pendingActions = QueuedRequestDTO.loadAllPendingRequests(context: readContext).map {
                ($0.id, $0.endpoint)
            }
        }

        log.info("\(pendingActions.count) pending offline requests", subsystems: .offlineSupport)

        let database = self.database
        let group = DispatchGroup()
        for (id, endpoint) in pendingActions {
            guard let endpoint = try? JSONDecoder.stream.decode(DataEndpoint.self, from: endpoint) else {
                continue
            }
            log.info("Executing queued offline request for /\(endpoint.path)", subsystems: .offlineSupport)

            group.enter()
            apiClient.recoveryRequest(endpoint: endpoint) { [weak self] result in
                let leave = {
                    group.leave()
                }
                let deleteQueuedRequestAndComplete = {
                    log.info("Completed queued offline request /\(endpoint.path)", subsystems: .offlineSupport)
                    database.write({ session in
                        session.deleteQueuedRequest(id: id)
                    }, completion: { _ in leave() })
                }

                switch result {
                case let .success(data):
                    self?.performDatabaseRecoveryActionsUponSuccess(
                        for: endpoint,
                        data: data,
                        completion: deleteQueuedRequestAndComplete
                    )
                case .failure(_ as ClientError.ConnectionError):
                    // If we failed because there is still no successful connection, we don't remove it from the queue
                    log.info(
                        "Keeping offline request /\(endpoint.path) as there is no connection",
                        subsystems: .offlineSupport
                    )
                    leave()
                case .failure:
                    deleteQueuedRequestAndComplete()
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            log.info("Done executing all queued offline requests", subsystems: .offlineSupport)
            completion()
        }
    }

    private func performDatabaseRecoveryActionsUponSuccess(
        for endpoint: DataEndpoint,
        data: Data,
        completion: @escaping () -> Void
    ) {
        // TODO: Temporary String check. We only process the response for sent messages
        guard case .sendMessage = endpoint.path else {
            completion()
            return
        }
        completion()
    }

    func queueOfflineRequest(endpoint: DataEndpoint, completion: (() -> Void)? = nil) {
        guard endpoint.path.shouldBeQueuedOffline else {
            completion?()
            return
        }

        let date = Date()
        let database = self.database

        retryQueue.async {
            guard let data = try? JSONEncoder.stream.encode(endpoint) else {
                completion?()
                return
            }

            database.write { _ in
                QueuedRequestDTO.createRequest(date: date, endpoint: data, context: database.writableContext)
                log.info("Queued request for /\(endpoint.path)", subsystems: .offlineSupport)
                completion?()
            }
        }
    }
}

private extension EndpointPath {
    var shouldBeQueuedOffline: Bool {
        // TODO: To be finalized. We are just ignoring events for now
        if case .channelEvent = self { return false }
        return true
    }
}
