//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object allowing making request to Stream Chat servers.
class APIClient {
    /// The URL session used for all requests.
    let session: URLSession
    
    /// `APIClient` uses this object to encode `Endpoint` objects into `URLRequest`s.
    let encoder: RequestEncoder
    
    /// `APIClient` uses this object to decode the results of network requests.
    let decoder: RequestDecoder
    
    /// Used for reobtaining tokens when they expire and API client receives token expiration error
    let tokenRefresher: TokenRefresher

    /// Used to queue requests that happen while we are offline
    let queueOfflineRequest: QueueOfflineRequestBlock

    /// Client that handles the work related to content (e.g. attachments)
    let cdnClient: CDNClient

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

    /// Amount of consecutive token refresh attempts
    @Atomic private var tokenRefreshConsecutiveFailures: Int = 0

    /// Maximum amount of consecutive token refresh attempts before failing
    let maximumTokenRefreshAttempts = 10

    /// Maximum amount of times a request can be retried
    private let maximumRequestRetries = 3

    deinit {
        operationQueue.cancelAllOperations()
        recoveryQueue.cancelAllOperations()
    }

    /// Creates a new `APIClient`.
    ///
    /// - Parameters:
    ///   - sessionConfiguration: The session configuration `APIClient` uses to create its `URLSession`.
    ///   - requestEncoder: `APIClient` uses this object to encode `Endpoint` objects into `URLRequest`s.
    ///   - requestDecoder: `APIClient` uses this object to decode the results of network requests.
    init(
        sessionConfiguration: URLSessionConfiguration,
        requestEncoder: RequestEncoder,
        requestDecoder: RequestDecoder,
        CDNClient: CDNClient,
        tokenRefresher: TokenRefresher,
        queueOfflineRequest: @escaping QueueOfflineRequestBlock
    ) {
        encoder = requestEncoder
        decoder = requestDecoder
        session = URLSession(configuration: sessionConfiguration)
        cdnClient = CDNClient
        self.tokenRefresher = tokenRefresher
        self.queueOfflineRequest = queueOfflineRequest
    }

    /// Performs a network request and retries in case of network failures
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` used to create the network request.
    ///   - completion: Called when the networking request is finished.
    func request<Response: Decodable>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        let requestOperation = operation(endpoint: endpoint, isRecoveryOperation: false, completion: completion)
        operationQueue.addOperation(requestOperation)
    }

    /// Performs a network request and retries in case of network failures
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` used to create the network request.
    ///   - completion: Called when the networking request is finished.
    func recoveryRequest<Response: Decodable>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        if !isInRecoveryMode {
            log.assertionFailure("We should not call this method if not in recovery mode")
        }

        let requestOperation = operation(endpoint: endpoint, isRecoveryOperation: true, completion: completion)
        recoveryQueue.addOperation(requestOperation)
    }

    private func operation<Response: Decodable>(
        endpoint: Endpoint<Response>,
        isRecoveryOperation: Bool,
        completion: @escaping (Result<Response, Error>) -> Void
    ) -> AsyncOperation {
        AsyncOperation(maxRetries: maximumRequestRetries) { [weak self] operation, done in
            self?.executeRequest(endpoint: endpoint) { [weak self] result in
                switch result {
                case .failure(_ as ClientError.RefreshingToken):
                    // Requeue request
                    print("⚠️. APIClient queuing request for \(endpoint.path)")
                    self?.request(endpoint: endpoint, completion: completion)
                    done(.continue)
                case .failure(_ as ClientError.TokenRefreshed):
                    // Retry request. Expired token has been refreshed
                    print("⚠️. APIClient - token refreshed. Retrying \(endpoint.path)")
                    operation.resetRetries()
                    done(.retry)
                case let .failure(error) where self?.isConnectionError(error) == true:
                    // If a non recovery request comes in while we are in recovery mode, we want to queue if still has
                    // retries left
                    let inRecoveryMode = self?.isInRecoveryMode == true
                    if inRecoveryMode && !isRecoveryOperation && operation.canRetry {
                        self?.request(endpoint: endpoint, completion: completion)
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
                        self?.queueOfflineRequest(endpoint.withDataResponse)
                        completion(result)
                    }

                    done(.continue)
                case .success, .failure:
                    log.debug("Request suceeded /\(endpoint.path)", subsystems: .offlineSupport)
                    completion(result)
                    done(.continue)
                }
            }
        }
    }

    /// Performs a network request.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` used to create the network request.
    ///   - completion: Called when the networking request is finished.
    private func executeRequest<Response: Decodable>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        if tokenRefreshConsecutiveFailures > maximumTokenRefreshAttempts {
            return completion(.failure(ClientError.TooManyTokenRefreshAttempts()))
        }

        guard !tokenRefresher.isRefreshingToken else {
            handleExpiredToken(completion: completion)
            return
        }

        encoder.encodeRequest(for: endpoint) { [weak self] (requestResult) in
            let urlRequest: URLRequest
            do {
                urlRequest = try requestResult.get()
            } catch {
                log.error(error, subsystems: .httpRequests)
                completion(.failure(error))
                return
            }

            log.debug(
                "Making URL request: \(endpoint.method.rawValue.uppercased()) \(endpoint.path)\n"
                    + "Headers:\n\(String(describing: urlRequest.allHTTPHeaderFields))\n"
                    + "Body:\n\(urlRequest.httpBody?.debugPrettyPrintedJSON ?? "<Empty>")\n"
                    + "Query items:\n\(urlRequest.queryItems.prettyPrinted)",
                subsystems: .httpRequests
            )

            guard let self = self else {
                log.warning("Callback called while self is nil", subsystems: .httpRequests)
                completion(.failure(ClientError("APIClient was deallocated")))
                return
            }

            let task = self.session.dataTask(with: urlRequest) { [decoder = self.decoder] (data, response, error) in
                do {
                    let decodedResponse: Response = try decoder.decodeRequestResponse(
                        data: data,
                        response: response,
                        error: error
                    )
                    self.tokenRefreshConsecutiveFailures = 0
                    completion(.success(decodedResponse))
                } catch {
                    if error is ClientError.ExpiredToken {
                        self.handleExpiredToken(completion: completion)
                    } else {
                        completion(.failure(error))
                    }
                }
            }
            task.resume()
        }
    }

    private func handleExpiredToken<Response: Decodable>(completion: @escaping (Result<Response, Error>) -> Void) {
        /// If the error is ExpiredToken, we need to refresh it. There are 2 possibilities here:
        /// 1. The token is not being refreshed, so we start the refresh, and we wait until it is completed. Then the request will be retried.
        /// 2. The token is already being refreshed, so we just put back the request to the queue (Cannot happen when running the queue in serial)
        ///
        /// This is done leveraging 2 error types. When ClientError.RefreshingToken is returned, we put back the request on the queue.
        /// But when ClientError.TokenRefreshed is returned, just retry the execution.
        /// This is done because we want to make sure that when the queue is running serial, there order is kept.
        refreshToken { refreshResult in
            completion(.failure(refreshResult))
        }
    }

    private func refreshToken(completion: @escaping (ClientError) -> Void) {
        guard !operationQueue.isSuspended || !tokenRefresher.isRefreshingToken else {
            completion(ClientError.RefreshingToken())
            return
        }

        // We stop the queue so no more operations are triggered during the refresh
        operationQueue.isSuspended = true

        // Increase the amount of consecutive failures
        _tokenRefreshConsecutiveFailures.mutate { $0 += 1 }

        print("⚠️. APIClient asking for a new token")
        tokenRefresher.refreshToken { [weak self] result in
            // We restart the queue now that token refresh is completed
            self?.operationQueue.isSuspended = false
            if case .failure = result {
                completion(ClientError.FailedRefreshingToken())
            } else {
                completion(ClientError.TokenRefreshed())
            }
        }
    }

    private func isConnectionError(_ error: Error) -> Bool {
        // We only retry transient errors like connectivity stuff or HTTP 5xx errors
        guard ClientError.isEphemeral(error: error) else {
            return false
        }

        let offlineErrorCodes: Set<Int> = [NSURLErrorDataNotAllowed, NSURLErrorNotConnectedToInternet]
        return offlineErrorCodes.contains((error as NSError).code)
    }

    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let cdnClient = self.cdnClient
        let uploadOperation = AsyncOperation(maxRetries: maximumRequestRetries) { [weak self] operation, done in
            cdnClient.uploadAttachment(attachment, progress: progress) { result in
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
