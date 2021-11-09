//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct RetryOptions {
    let MaxRetries: Int = 3
    let Backoff: (Int) -> Double = {
        min(max(Double($0) * Double($0), 0.5), 6.0)
    }
}

/// An object allowing making request to Stream Chat servers.
class APIClient {
    struct RequestsQueueItem {
        let requestAction: () -> Void
        let failureAction: () -> Void
    }
    
    /// The URL session used for all requests.
    var session: URLSession
    
    /// `APIClient` uses this object to encode `Endpoint` objects into `URLRequest`s.
    let encoder: RequestEncoder
    
    /// `APIClient` uses this object to decode the results of network requests.
    let decoder: RequestDecoder
    
    /// Used for reobtaining tokens when they expire and API client receives token expiration error
    let tokenRefresher: (ClientError, @escaping () -> Void) -> Void
    
    let cdnClient: CDNClient

    /// Used for synchronizing access to requestsQueue
    private let requestsAccessQueue = DispatchQueue(label: "io.getstream.requests")
    
    /// Used for request retries
    private let requestsRetriesQueue = DispatchQueue(label: "io.getstream.request-retries")

    /// Stores request failed with token expired error for retrying them later
    private var requestsQueue = [RequestsQueueItem]()
    
    /// Shows whether the token is being refreshed at the moment
    @Atomic private var isRefreshingToken: Bool = false
    
    /// How many times refreshing the token failed consecutively
    @Atomic private var tokenRefreshConsecutiveFailures: Int = 0

    /// How many times can the token refresh fail before giving up with an error
    let maxTokenRefreshAttempts = 10

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
        tokenRefresher: @escaping (ClientError, @escaping () -> Void) -> Void
    ) {
        encoder = requestEncoder
        decoder = requestDecoder
        session = URLSession(configuration: sessionConfiguration)
        cdnClient = CDNClient
        self.tokenRefresher = tokenRefresher
    }
    
    deinit {
        requestsQueue = []
    }

    /// Performs a network request and retries in case of network failures
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` used to create the network request.
    ///   - timeout: The timeout in seconds for the API request.
    ///   - retryOptions: The `RetryOptions` used to retry the request.
    ///   - completion: Called when the networking request is finished.
    func request<Response: Decodable>(
        endpoint: Endpoint<Response>,
        timeout: TimeInterval = 60,
        retryOptions: RetryOptions,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        requestsRetriesQueue.async { [weak self] in
            self?.request(attempt: 0, endpoint: endpoint, timeout: timeout, retryOptions: retryOptions, completion: completion)
        }
    }

    private func request<Response: Decodable>(
        attempt: Int,
        endpoint: Endpoint<Response>,
        timeout: TimeInterval,
        retryOptions: RetryOptions,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        request(endpoint: endpoint) {
            let backoff = retryOptions.Backoff(attempt)

            guard case let .failure(error) = $0 else {
                return completion($0)
            }

            // we only retry transient errors like connectivity stuff or HTTP 5xx errors
            guard ClientError.isEphemeral(error: error) else {
                return completion($0)
            }

            let offlineErrorCodes: Set<Int> = [NSURLErrorDataNotAllowed, NSURLErrorNotConnectedToInternet]
            let connectionError = offlineErrorCodes.contains((error as NSError).code)

            // give up after `retryOptions.MaxRetries` unless its a connection problem
            if attempt <= retryOptions.MaxRetries && !connectionError {
                return completion($0)
            }

            self.requestsRetriesQueue.asyncAfter(deadline: .now() + backoff) {
                self.request(
                    attempt: attempt + 1,
                    endpoint: endpoint,
                    timeout: timeout,
                    retryOptions: retryOptions,
                    completion: completion
                )
            }
        }
    }
    
    /// Performs a network request.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` used to create the network request.
    ///   - completion: Called when the networking request is finished.
    func request<Response: Decodable>(
        endpoint: Endpoint<Response>,
        timeout: TimeInterval = 60,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        if tokenRefreshConsecutiveFailures > maxTokenRefreshAttempts {
            return completion(.failure(ClientError.TooManyTokenRefreshAttempts()))
        }

        if isRefreshingToken {
            return requeueRequestOnTokenExpired(endpoint: endpoint, timeout: timeout, completion: completion)
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
                        self.requeueRequestOnTokenExpired(endpoint: endpoint, timeout: timeout, completion: completion)
                    } else {
                        completion(.failure(error))
                    }
                }
            }
            task.resume()
        }
    }
    
    func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        cdnClient.uploadAttachment(
            attachment,
            progress: progress,
            completion: completion
        )
    }
    
    /// Queues a failed request for executing later or failing after a timeout
    func requeueRequestOnTokenExpired<Response: Decodable>(
        endpoint: Endpoint<Response>,
        timeout: TimeInterval,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        requestsAccessQueue.async {
            let item = RequestsQueueItem(
                requestAction: { [weak self] in
                    self?.request(
                        endpoint: endpoint,
                        timeout: timeout,
                        completion: completion
                    )
                },
                failureAction: { completion(.failure(ClientError.ExpiredToken())) }
            )
            
            self.requestsQueue.append(item)
            
            // Only initiate token refreshing once
            guard self._isRefreshingToken.compareAndSwap(old: false, new: true) else { return }
            
            /// Increase the amount of consecutive failures
            self._tokenRefreshConsecutiveFailures.mutate { $0 += 1 }

            // The moment we queue a first request for execution later we also set a timeout for 60 seconds
            // after which we fail all the queued requests
            self.flushRequestsQueue(after: timeout) {
                $0.failureAction()
            }
            
            self.tokenRefresher(ClientError.ExpiredToken()) { [weak self] in
                guard let self = self else {
                    return
                }

                self.isRefreshingToken = false
                self.flushRequestsQueue {
                    $0.requestAction()
                }
            }
        }
    }
    
    /// Flushes the request queue after the given timeout.
    ///
    /// - Parameters:
    ///   - timeout: The timeout when the request queue has to be flushed.
    ///   - itemAction: The item action invoked for every request item when the queue is flushed.
    func flushRequestsQueue(
        after timeout: TimeInterval = 0,
        itemAction: ((RequestsQueueItem) -> Void)? = nil
    ) {
        requestsAccessQueue.asyncAfter(deadline: .now() + timeout) { [weak self] in
            guard let self = self else { return }
            
            let queue = self.requestsQueue
            self.requestsQueue = []
            queue.forEach { itemAction?($0) }
        }
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
