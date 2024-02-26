//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

typealias QueueOfflineRequestBlock = (URLRequest, ResponseType) -> Void
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
        let readContext = database.backgroundReadOnlyContext
        readContext.perform { [weak self] in
            let requests = QueuedRequestDTO.loadAllPendingRequests(context: readContext).map {
                ($0.id, $0.endpoint, $0.date as Date)
            }
            DispatchQueue.main.async {
                self?.executeRequests(requests, completion: completion)
            }
        }
    }
    
    private func executeRequests(_ requests: [(String, Data, Date)], completion: @escaping () -> Void) {
        log.info("\(requests.count) pending offline requests", subsystems: .offlineSupport)

        let database = self.database
        let currentDate = Date()
        let group = DispatchGroup()
        for (id, endpoint, date) in requests {
            group.enter()
            let leave = {
                group.leave()
            }
            let deleteQueuedRequestAndComplete = {
                database.write({ session in
                    session.deleteQueuedRequest(id: id)
                }, completion: { _ in leave() })
            }
            
            guard let queuedRequest = try? JSONDecoder.stream.decode(QueuedRequest.self, from: endpoint),
                  let url = queuedRequest.url else {
                log.error("Could not decode queued request \(id)", subsystems: .offlineSupport)
                deleteQueuedRequestAndComplete()
                continue
            }
            
            let hoursQueued = currentDate.timeIntervalSince(date) / Constants.secondsInHour
            let shouldBeDiscarded = hoursQueued > Double(maxHoursThreshold)
            
            let queryParams = queuedRequest.queryItems.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            var existingQueryItems = urlComponents.queryItems ?? []
            existingQueryItems.append(contentsOf: queryParams)
            urlComponents.queryItems = existingQueryItems
            
            var urlRequest = URLRequest(url: urlComponents.url ?? url)
            urlRequest.httpMethod = queuedRequest.method
            urlRequest.httpBody = queuedRequest.body
            urlRequest.allHTTPHeaderFields = queuedRequest.headers

            guard queuedRequest.shouldBeQueuedOffline && !shouldBeDiscarded else {
                log.error("Queued request for /\(queuedRequest.path) should not be queued", subsystems: .offlineSupport)
                deleteQueuedRequestAndComplete()
                continue
            }

            log.info("Executing queued offline request for /\(queuedRequest.path)", subsystems: .offlineSupport)
            apiClient.request(urlRequest, isRecoveryOperation: true) { [weak self] (result: Result<Data, Error>) in
                log.info("Completed queued offline request /\(queuedRequest.path)", subsystems: .offlineSupport)
                switch result {
                case let .success(data):
                    self?.performDatabaseRecoveryActionsUponSuccess(
                        for: queuedRequest,
                        data: data,
                        completion: deleteQueuedRequestAndComplete
                    )
                case .failure(_ as ClientError.ConnectionError):
                    // If we failed because there is still no successful connection, we don't remove it from the queue
                    log.info(
                        "Keeping offline request /\(queuedRequest.path) as there is no connection",
                        subsystems: .offlineSupport
                    )
                    leave()
                case let .failure(error):
                    log.info(
                        "Request for /\(queuedRequest.path) failed: \(error)",
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
        for queuedRequest: QueuedRequest,
        data: Data,
        completion: @escaping () -> Void
    ) {
        func decodeTo<T: Decodable>(_ type: T.Type) -> T? {
            try? JSONDecoder.stream.decode(T.self, from: data)
        }
        
        let responseType = queuedRequest.responseType
        
        if responseType.value == .sendMessageResponse {
            guard let messageResponse = decodeTo(SendMessageResponse.self),
                  let cid = try? ChannelId(cid: messageResponse.message.cid) else {
                completion()
                return
            }
            messageRepository.saveSuccessfullySentMessage(cid: cid, message: messageResponse.message) { _ in completion() }
        } else if responseType.value == .updateMessageResponse {
            guard let messageResponse = decodeTo(UpdateMessageResponse.self) else {
                completion()
                return
            }
            messageRepository.saveSuccessfullyEditedMessage(for: messageResponse.message.id) { completion() }
        } else if responseType.value == .messageResponse && queuedRequest.method == "DELETE" {
            guard let messageResponse = decodeTo(MessageResponse.self),
                  let message = messageResponse.message else {
                completion()
                return
            }
            messageRepository.saveSuccessfullyDeletedMessage(message: message) { _ in completion() }
        } else if responseType.value == .reactionResponse || responseType.value == .reactionRemovalResponse {
            completion()
        }
    }
    
    func queueOfflineRequest(_ request: URLRequest, responseType: ResponseType, completion: (() -> Void)? = nil) {
        guard responseType.shouldBeQueuedOffline else {
            completion?()
            return
        }
        
        var requiresToken = false
        var headers = request.allHTTPHeaderFields
        if headers?[HTTPHeader.Key.authorization.rawValue] != nil {
            requiresToken = true
            headers?[HTTPHeader.Key.authorization.rawValue] = nil
        }
        
        // TODO: constant
        let requiresConnectionId = request.queryItems.filter { $0.name == "connection_id" }.isEmpty == false
        
        let queuedRequest = QueuedRequest(
            baseURL: request.url?.baseURL?.absoluteString ?? "",
            path: request.url?.relativePath ?? "",
            method: request.httpMethod ?? "GET",
            queryItems: request.queryItems
                .filter { $0.name != "connection_id" }
                .map { QueryItem(key: $0.name, value: $0.value) },
            headers: request.allHTTPHeaderFields,
            body: request.httpBody,
            requiresConnectionId: requiresConnectionId,
            requiresToken: requiresToken,
            responseType: responseType
        )
        
        let date = Date()
        retryQueue.async { [database] in
            guard let data = try? JSONEncoder.stream.encode(queuedRequest) else {
                log.error("Could not encode queued request for /\(queuedRequest.path)", subsystems: .offlineSupport)
                completion?()
                return
            }

            database.write { _ in
                QueuedRequestDTO.createRequest(date: date, endpoint: data, context: database.writableContext)
                log.info("Queued request for /\(queuedRequest.path)", subsystems: .offlineSupport)
                completion?()
            }
        }
    }
}

struct QueuedRequest: Codable {
    let baseURL: String
    let path: String
    let method: String
    let queryItems: [QueryItem]
    let headers: [String: String]?
    let body: Data?
    let requiresConnectionId: Bool
    let requiresToken: Bool
    let responseType: ResponseType
    
    var url: URL? {
        URL(string: baseURL + path)
    }
    
    var shouldBeQueuedOffline: Bool {
        responseType.shouldBeQueuedOffline
    }
}

struct ResponseType: Codable {
    let value: String
    var shouldBeQueuedOffline: Bool {
        // TODO: revisit this.
        let queuedOffline: [String] = [
            .updateMessageResponse,
            .sendMessageResponse,
            .messageResponse,
            .reactionRemovalResponse,
            .reactionResponse
        ]
        return queuedOffline.contains(value)
    }
}

extension String {
    static let updateMessageResponse = "UpdateMessageResponse"
    static let sendMessageResponse = "SendMessageResponse"
    static let messageResponse = "MessageResponse"
    static let reactionRemovalResponse = "ReactionRemovalResponse"
    static let reactionResponse = "ReactionResponse"
}

struct QueryItem: Codable {
    let key: String
    let value: String?
}
