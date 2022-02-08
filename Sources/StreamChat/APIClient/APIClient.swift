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
    let tokenRefresher: (@escaping () -> Void) -> Void

    /// Client that handles the work related to content (e.g. attachments)
    let cdnClient: CDNClient

    /// Queue in charge of handling incoming requests
    private let operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "com.stream.api-client"
        return operationQueue
    }()

    /// Shows whether the token is being refreshed at the moment
    @Atomic private var isRefreshingToken: Bool = false
    
    /// Amount of consecutive token refresh attempts
    @Atomic private var tokenRefreshConsecutiveFailures: Int = 0

    /// Maximum amount of consecutive token refresh attempts before failing
    let maximumTokenRefreshAttempts = 10

    /// Maximum amount of times a request can be retried
    private let maximumRequestRetries = 3

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
        tokenRefresher: @escaping (@escaping () -> Void) -> Void
    ) {
        encoder = requestEncoder
        decoder = requestDecoder
        session = URLSession(configuration: sessionConfiguration)
        cdnClient = CDNClient
        self.tokenRefresher = tokenRefresher
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
        let requestOperation = operation(endpoint: endpoint, completion: completion)
        operationQueue.addOperation(requestOperation)
    }

    private func operation<Response: Decodable>(
        endpoint: Endpoint<Response>,
        completion: @escaping (Result<Response, Error>) -> Void
    ) -> AsyncOperation {
        AsyncOperation(maxRetries: maximumRequestRetries) { [weak self] operation, done in
            self?.executeRequest(endpoint: endpoint) { result in
                switch result {
                case .failure(_ as ClientError.RefreshingToken):
                    // Requeue request
                    self?.request(endpoint: endpoint, completion: completion)
                    done(.continue)
                case let .failure(error) where self?.shouldRetry(error, operation: operation) == true:
                    done(.retry)
                case .success, .failure:
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

        guard !isRefreshingToken else {
            completion(.failure(ClientError.RefreshingToken()))
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
                    + "Body:\n\(urlRequest.httpBody?.debugPrettyPrintedJSON ?? "<Empty>")\n"
                    + "Query items:\n\(urlRequest.queryItems.prettyPrinted)", subsystems: .httpRequests
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
                        self.refreshToken {
                            log.info("Token Refreshed", subsystems: .httpRequests)
                        }
                        completion(.failure(ClientError.RefreshingToken()))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
            task.resume()
        }
    }

    private func refreshToken(completion: @escaping () -> Void) {
        guard _isRefreshingToken.compareAndSwap(old: false, new: true) else {
            completion()
            return
        }

        // We stop the queue so no more operations are triggered
        operationQueue.isSuspended = true

        // Increase the amount of consecutive failures
        _tokenRefreshConsecutiveFailures.mutate { $0 += 1 }

        tokenRefresher { [weak self] in
            self?.isRefreshingToken = false
            // We restart the queue now that token refresh is completed
            self?.operationQueue.isSuspended = false
            completion()
        }
    }

    private func shouldRetry(_ error: Error, operation: AsyncOperation) -> Bool {
        // We only retry transient errors like connectivity stuff or HTTP 5xx errors
        guard ClientError.isEphemeral(error: error) else {
            return false
        }

        let offlineErrorCodes: Set<Int> = [NSURLErrorDataNotAllowed, NSURLErrorNotConnectedToInternet]
        let isConnectionError = offlineErrorCodes.contains((error as NSError).code)

        // Do not retry unless its a connection problem
        guard !isConnectionError else { return true }
        return operation.canRetry
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
                case let .failure(error) where self?.shouldRetry(error, operation: operation) == true:
                    done(.retry)
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
}

private extension URLRequest {
    var queryItems: [URLQueryItem] {
        if let url = url,
           let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            return queryItems
        }
        return []
    }
}

private extension Array where Element == URLQueryItem {
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
