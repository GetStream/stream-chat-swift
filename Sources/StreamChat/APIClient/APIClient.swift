//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object allowing making request to Stream Chat servers.
class APIClient {
    /// The URL session used for all requests.
    let session: URLSession

    /// `APIClient` uses this object to decode the results of network requests.
    let decoder: RequestDecoder

    /// Used for reobtaining tokens when they expire and API client receives token expiration error
    var tokenRefresher: ((@escaping () -> Void) -> Void)?

    /// Used to queue requests that happen while we are offline
    var queueOfflineRequest: QueueOfflineRequestBlock?

    /// The attachment uploader.
    let attachmentUploader: AttachmentUploader

    /// Queue in charge of handling incoming requests
    private let operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "com.stream.api-client"
        return operationQueue
    }()

    /// Queue in charge of handling recovery related requests. Handles operations in serial
    private let recoveryQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "com.stream.api-client.recovery"
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()

    /// Determines whether the APIClient is in recovery mode. During recovery period we limit the concurrent operations to 1, and we only allow recovery related
    /// requests to be run,
    @Atomic private var isInRecoveryMode: Bool = false

    /// Shows whether the token is being refreshed at the moment
    @Atomic private var isRefreshingToken: Bool = false

    /// Maximum amount of times a request can be retried
    private let maximumRequestRetries = 3

    deinit {
        operationQueue.cancelAllOperations()
        recoveryQueue.cancelAllOperations()
    }

    /// Creates a new `APIClient`.
    init(
        sessionConfiguration: URLSessionConfiguration,
        requestDecoder: RequestDecoder,
        attachmentUploader: AttachmentUploader
    ) {
        decoder = requestDecoder
        session = URLSession(configuration: sessionConfiguration)
        self.attachmentUploader = attachmentUploader
    }
    
    func request<Response: Decodable>(
        _ request: URLRequest,
        isRecoveryOperation: Bool,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        let requestOperation = operation(request: request, isRecoveryOperation: isRecoveryOperation, completion: completion)
        if isRecoveryOperation {
            recoveryQueue.addOperation(requestOperation)
        } else {
            operationQueue.addOperation(requestOperation)
        }
    }

    func unmanagedRequest<Response: Decodable>(
        _ request: URLRequest,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        OperationQueue.main.addOperation(
            unmanagedOperation(request: request, completion: completion)
        )
    }
    
    private func operation<Response: Decodable>(
        request: URLRequest,
        isRecoveryOperation: Bool,
        completion: @escaping (Result<Response, Error>) -> Void
    ) -> AsyncOperation {
        AsyncOperation(maxRetries: maximumRequestRetries) { [weak self] operation, done in
            guard let self = self else {
                done(.continue)
                return
            }

            guard !self.isRefreshingToken else {
                // Requeue request
                self.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
                done(.continue)
                return
            }

            self.execute(urlRequest: request) { [weak self] (result: Result<Response, Error>) -> Void in
                switch result {
                case .failure(_ as ClientError.RefreshingToken):
                    // Requeue request
                    self?.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
                    done(.continue)
                case .failure(_ as ClientError.TokenRefreshed):
                    // Retry request. Expired token has been refreshed
                    operation.resetRetries()
                    done(.retry)
                case .failure(_ as ClientError.WaiterTimeout):
                    // When waiters timeout, chances are that we are still connecting. We are going to retry until we reach max retries
                    if operation.canRetry {
                        done(.retry)
                    } else {
                        completion(result)
                        done(.continue)
                    }
                case let .failure(error) where self?.isConnectionError(error) == true:
                    // If a non recovery request comes in while we are in recovery mode, we want to queue if still has
                    // retries left
                    let inRecoveryMode = self?.isInRecoveryMode == true
                    if inRecoveryMode && !isRecoveryOperation && operation.canRetry {
                        self?.request(request, isRecoveryOperation: isRecoveryOperation, completion: completion)
                        done(.continue)
                        return
                    }

                    // Do not retry unless its a connection problem and we still have retries left
                    if operation.canRetry {
                        done(.retry)
                        return
                    }

                    if inRecoveryMode {
                        completion(.failure(ClientError.ConnectionError()))
                    } else {
                        // Offline Queuing
                        self?.queueOfflineRequest?(request, ResponseType(value: "\(Response.self)"))
                        completion(result)
                    }

                    done(.continue)
                case .success, .failure:
                    log.debug("Request completed for /\(request.url?.absoluteString ?? "")", subsystems: .offlineSupport)
                    completion(result)
                    done(.continue)
                }
            }
        }
    }

    private func unmanagedOperation<Response: Decodable>(
        request: URLRequest,
        completion: @escaping (Result<Response, Error>) -> Void
    ) -> AsyncOperation {
        AsyncOperation(maxRetries: maximumRequestRetries) { [weak self] operation, done in
            self?.execute(urlRequest: request) { [weak self] (result: Result<Response, Error>) in
                switch result {
                case let .failure(error) where self?.isConnectionError(error) == true:
                    // Do not retry unless its a connection problem and we still have retries left
                    if operation.canRetry {
                        done(.retry)
                        return
                    }

                    completion(result)
                    done(.continue)
                case .success, .failure:
                    log.debug("Request succeeded /\(request.url?.relativePath ?? "")", subsystems: .offlineSupport)
                    completion(result)
                    done(.continue)
                }
            }
        }
    }
    
    private func execute<Response: Decodable>(
        urlRequest: URLRequest,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        log.debug(
            "Making URL request: \(String(describing: urlRequest.httpMethod?.uppercased())) \(String(describing: urlRequest.url?.relativePath))\n"
                + "Headers:\n\(String(describing: urlRequest.allHTTPHeaderFields))\n"
                + "Body:\n\(urlRequest.httpBody?.debugPrettyPrintedJSON ?? "<Empty>")\n"
                + "Query items:\n\(urlRequest.queryItems.prettyPrinted)",
            subsystems: .httpRequests
        )

        let task = session.dataTask(with: urlRequest) { [decoder = self.decoder] (data, response, error) in
            do {
                let decodedResponse: Response = try decoder.decodeRequestResponse(
                    data: data,
                    response: response,
                    error: error
                )
                completion(.success(decodedResponse))
            } catch {
                if error is ClientError.ExpiredToken == false {
                    completion(.failure(error))
                    return
                }

                /// If the error is ExpiredToken, we need to refresh it. There are 2 possibilities here:
                /// 1. The token is not being refreshed, so we start the refresh, and we wait until it is completed. Then the request will be retried.
                /// 2. The token is already being refreshed, so we just put back the request to the queue (Cannot happen when running the queue in serial)
                ///
                /// This is done leveraging 2 error types. When ClientError.RefreshingToken is returned, we put back the request on the queue.
                /// But when ClientError.TokenRefreshed is returned, just retry the execution.
                /// This is done because we want to make sure that when the queue is running serial, there order is kept.
                self.refreshToken { refreshResult in
                    completion(.failure(refreshResult))
                }
            }
        }
        task.resume()
    }

    private func refreshToken(completion: @escaping (ClientError) -> Void) {
        guard !isRefreshingToken else {
            completion(ClientError.RefreshingToken())
            return
        }

        enterTokenFetchMode()

        tokenRefresher? { [weak self] in
            self?.exitTokenFetchMode()
            completion(ClientError.TokenRefreshed())
        }
    }

    private func isConnectionError(_ error: Error) -> Bool {
        // We only retry transient errors like connectivity stuff or HTTP 5xx errors
        ClientError.isEphemeral(error: error)
    }

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<UploadedAttachment, Error>) -> Void
    ) {
        let uploadOperation = AsyncOperation(maxRetries: maximumRequestRetries) { [weak self] operation, done in
            self?.attachmentUploader.upload(attachment, progress: progress) { result in
                switch result {
                case let .failure(error) where self?.isConnectionError(error) == true:
                    // Do not retry unless its a connection problem and we still have retries left
                    if operation.canRetry {
                        done(.retry)
                    } else {
                        completion(result)
                        done(.continue)
                    }
                case .success, .failure:
                    completion(result)
                    done(.continue)
                }
            }
        }
        operationQueue.addOperation(uploadOperation)
    }

    func flushRequestsQueue() {
        operationQueue.cancelAllOperations()
    }

    func enterRecoveryMode() {
        // Pauses all the regular requests until recovery is completed.
        log.debug("Entering recovery mode", subsystems: .offlineSupport)
        isInRecoveryMode = true
        operationQueue.isSuspended = true
    }

    func exitRecoveryMode() {
        // Once recovery is done, regular requests can go through again.
        log.debug("Leaving recovery mode", subsystems: .offlineSupport)
        isInRecoveryMode = false
        operationQueue.isSuspended = false
    }

    func enterTokenFetchMode() {
        // We stop the queue so no more operations are triggered during the refresh
        isRefreshingToken = true
        operationQueue.isSuspended = true
    }

    func exitTokenFetchMode() {
        // We restart the queue now that token refresh is completed
        isRefreshingToken = false
        operationQueue.isSuspended = false
    }
}

extension URLRequest {
    var queryItems: [URLQueryItem] {
        if let url = url,
           let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            return queryItems
        }
        return []
    }
}

extension Array where Element == URLQueryItem {
    var prettyPrinted: String {
        var message = ""

        forEach { item in
            if let value = item.value,
               value.hasPrefix("{"),
               let data = value.data(using: .utf8) {
                message += "- \(item.name)=\(data.debugPrettyPrintedJSON)\n"
            } else if item.name != "api_key" && item.name != "user_id" && item.name != "client_id" {
                message += "- \(item.description)\n"
            }
        }

        if message.isEmpty {
            message = "<Empty>"
        }

        return message
    }
}
