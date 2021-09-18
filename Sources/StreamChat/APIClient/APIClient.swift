//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object allowing making request to Stream Chat servers.
class APIClient {
    private struct RequestsQueueItem {
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
                log.error(error)
                completion(.failure(error))
                return
            }

            log.debug(
                "Making URL request: \(endpoint.method.rawValue.uppercased()) \(endpoint.path)\n"
                    + "Body:\n\(urlRequest.httpBody?.debugPrettyPrintedJSON ?? "<Empty>")\n"
                    + "Query items:\n\(urlRequest.queryItems.prettyPrinted)"
            )

            guard let self = self else {
                log.warning("Callback called while self is nil")
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
            self.requestsAccessQueue.asyncAfter(deadline: .now() + timeout) {
                self.requestsQueue.forEach { $0.failureAction() }
                self.requestsQueue = []
            }
            
            self.tokenRefresher(ClientError.ExpiredToken()) { [weak self] in
                guard let self = self else {
                    return
                }

                self.isRefreshingToken = false
                let queue = self.requestsQueue
                self.requestsQueue = []
                queue.forEach { $0.requestAction() }
            }
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
