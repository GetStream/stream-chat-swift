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

class OfflineRequestsRepository {
    let database: DatabaseContainer
    let apiClient: APIClient

    /// Serial queue used to enqueue pending requests one after another
    private let retryQueue = DispatchQueue(label: "com.stream.queue-requests")

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }

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
                let deleteQueuedRequest = {
                    log.info("Completed queued offline request /\(endpoint.path)", subsystems: .offlineSupport)
                    database.write { session in
                        session.deleteQueuedRequest(id: id)
                    }
                }

                switch result {
                case let .success(data):
                    deleteQueuedRequest()
                    self?.performDatabaseRecoveryActionsUponSuccess(for: endpoint, data: data)
                case .failure(_ as ClientError.ConnectionError):
                    // If we failed because there is still no successful connection, we don't remove it from the queue
                    log.info(
                        "Keeping offline request /\(endpoint.path) as there is no connection",
                        subsystems: .offlineSupport
                    )
                case .failure:
                    deleteQueuedRequest()
                }

                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            log.info("Done executing all queued offline requests", subsystems: .offlineSupport)
            completion()
        }
    }

    private func performDatabaseRecoveryActionsUponSuccess(for endpoint: DataEndpoint, data: Data) {
        // TODO: Temporary String check. We only process the response for sent messages
        guard endpoint.path.hasSuffix("/message") else { return }
    }

    func queueOfflineRequest(endpoint: DataEndpoint) {
        // TODO: Temporary String check. We are ignoring events for now
        guard !endpoint.path.hasSuffix("event") else { return }

        let date = Date()
        let database = self.database

        retryQueue.async {
            guard let data = try? JSONEncoder.stream.encode(endpoint) else { return }

            database.write { _ in
                QueuedRequestDTO.createRequest(date: date, endpoint: data, context: database.writableContext)
                log.info("Queued request for /\(endpoint.path)", subsystems: .offlineSupport)
            }
        }
    }
}
