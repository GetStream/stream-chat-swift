//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
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
    enum Constants {
        static let secondsInHour: Double = 3600
    }
    
    private let messageRepository: MessageRepository
    private let database: DatabaseContainer
    private let apiClient: APIClient
    private let maxHoursThreshold: Int

    /// Serial queue used to enqueue pending requests one after another
    private let retryQueue = DispatchQueue(label: "io.getstream.queue-requests")

    init(
        messageRepository: MessageRepository,
        database: DatabaseContainer,
        apiClient: APIClient,
        maxHoursThreshold: Int
    ) {
        self.messageRepository = messageRepository
        self.database = database
        self.apiClient = apiClient
        self.maxHoursThreshold = maxHoursThreshold
    }

    /// - If the requests succeeds -> The request is removed from the pending ones
    /// - If the request fails with a connection error -> The request is kept to be executed once the connection is back (we are not putting it back at the queue to make sure we respect the order)
    /// - If the request fails with any other error -> We are dismissing the request, and removing it from the queue
    func runQueuedRequests(completion: @escaping () -> Void) {
        database.read { session in
            let dtos = session.allQueuedRequests()
            var requests = [Request]()
            requests.reserveCapacity(dtos.count)
            var requestIdsToDelete = Set<String>()
            let currentDate = Date()
            
            for dto in dtos {
                let id = dto.id
                let endpointData = dto.endpoint
                let date = dto.date.bridgeDate
                
                // Is valid
                guard let endpoint = try? JSONDecoder.stream.decode(DataEndpoint.self, from: endpointData) else {
                    log.error("Could not decode queued request \(id)", subsystems: .offlineSupport)
                    requestIdsToDelete.insert(dto.id)
                    continue
                }
                
                // Is expired
                let hoursQueued = currentDate.timeIntervalSince(date) / Constants.secondsInHour
                let shouldBeDiscarded = hoursQueued > Double(self.maxHoursThreshold)
                guard endpoint.shouldBeQueuedOffline && !shouldBeDiscarded else {
                    log.error("Queued request for /\(endpoint.path.value) should not be queued", subsystems: .offlineSupport)
                    requestIdsToDelete.insert(dto.id)
                    continue
                }
                requests.append(Request(id: id, date: date, endpoint: endpoint))
            }
            
            // Out of valid requests, merge send message requests for the same id
            let sendMessageIdGroups = Dictionary(grouping: requests, by: { $0.sendMessageId })
            var mergedRequests = [Request]()
            mergedRequests.reserveCapacity(requests.count)
            for request in requests {
                if let sendMessageId = request.sendMessageId {
                    // Is it already merged into another
                    if requestIdsToDelete.contains(request.id) {
                        continue
                    }
                    if let duplicates = sendMessageIdGroups[sendMessageId], duplicates.count >= 2 {
                        // Coalesce send message requests in a way that we use the latest endpoint data
                        // because the message could have changed when there was a manual retry
                        let sortedDuplicates = duplicates.sorted(by: { $0.date < $1.date })
                        let earliest = sortedDuplicates.first!
                        let latest = sortedDuplicates.last!
                        mergedRequests.append(Request(id: earliest.id, date: earliest.date, endpoint: latest.endpoint))
                        // All the others should be deleted
                        requestIdsToDelete.formUnion(duplicates.dropFirst().map(\.id))
                    } else {
                        mergedRequests.append(request)
                    }
                } else {
                    mergedRequests.append(request)
                }
            }
            log.info("\(mergedRequests.count) pending offline requests (coalesced = \(requests.count - mergedRequests.count)", subsystems: .offlineSupport)
            return (requests: mergedRequests, deleteIds: requestIdsToDelete)
        } completion: { [weak self] result in
            switch result {
            case .success(let pair):
                self?.deleteRequests(with: pair.deleteIds, completion: {
                    self?.retryQueue.async {
                        self?.executeRequests(pair.requests, completion: completion)
                    }
                })
            case .failure(let error):
                log.error("Failed to read queued requests with error \(error.localizedDescription)", subsystems: .offlineSupport)
                completion()
            }
        }
    }
    
    private func deleteRequests(with ids: Set<String>, completion: @escaping () -> Void) {
        guard !ids.isEmpty else {
            completion()
            return
        }
        database.write { session in
            for id in ids {
                session.deleteQueuedRequest(id: id)
            }
        } completion: { _ in
            completion()
        }
    }
    
    private func executeRequests(_ requests: [Request], completion: @escaping () -> Void) {
        let database = self.database
        let group = DispatchGroup()
        for request in requests {
            let id = request.id
            let endpoint = request.endpoint
            
            group.enter()
            let leave = {
                group.leave()
            }
            let deleteQueuedRequestAndComplete = {
                database.write({ session in
                    session.deleteQueuedRequest(id: id)
                }, completion: { _ in leave() })
            }

            log.info("Executing queued offline request for /\(endpoint.path)", subsystems: .offlineSupport)
            apiClient.recoveryRequest(endpoint: endpoint) { [weak self] result in
                log.info("Completed queued offline request /\(endpoint.path)", subsystems: .offlineSupport)
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
                case let .failure(error):
                    log.info(
                        "Request for /\(endpoint.path) failed: \(error)",
                        subsystems: .offlineSupport
                    )
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
        func decodeTo<T: Decodable>(_ type: T.Type) -> T? {
            try? JSONDecoder.stream.decode(T.self, from: data)
        }

        switch endpoint.path {
        case let .sendMessage(channelId):
            guard let message = decodeTo(MessagePayload.Boxed.self) else {
                completion()
                return
            }
            messageRepository.saveSuccessfullySentMessage(cid: channelId, message: message.message) { _ in completion() }
        case let .editMessage(messageId):
            messageRepository.saveSuccessfullyEditedMessage(for: messageId, completion: completion)
        case .deleteMessage:
            guard let message = decodeTo(MessagePayload.Boxed.self) else {
                completion()
                return
            }
            messageRepository.saveSuccessfullyDeletedMessage(message: message.message) { _ in completion() }
        case .addReaction, .deleteReaction:
            // No further action
            completion()
        default:
            log.assertionFailure("Should not reach here, request should not require action")
            completion()
        }
    }

    func queueOfflineRequest(endpoint: DataEndpoint, completion: (() -> Void)? = nil) {
        guard endpoint.shouldBeQueuedOffline else {
            completion?()
            return
        }

        let date = Date()
        retryQueue.async { [database] in
            guard let data = try? JSONEncoder.stream.encode(endpoint) else {
                log.error("Could not encode queued request for /\(endpoint.path)", subsystems: .offlineSupport)
                completion?()
                return
            }

            database.write { _ in
                QueuedRequestDTO.createRequest(date: date, endpoint: data, context: database.writableContext)
                log.info("Queued request for /\(endpoint.path)", subsystems: .offlineSupport)
            } completion: { _ in
                completion?()
            }
        }
    }
}

private extension OfflineRequestsRepository {
    struct Request {
        let id: String
        let date: Date
        let endpoint: DataEndpoint
        let sendMessageId: MessageId?
     
        init(id: String, date: Date, endpoint: DataEndpoint) {
            self.id = id
            self.date = date
            self.endpoint = endpoint
            
            sendMessageId = {
                switch endpoint.path {
                case .sendMessage:
                    guard let bodyData = endpoint.body as? Data else { return nil }
                    guard let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] else { return nil }
                    guard let message = json["message"] as? [String: Any] else { return nil }
                    return message["id"] as? String
                default:
                    return nil
                }
            }()
        }
    }
}
