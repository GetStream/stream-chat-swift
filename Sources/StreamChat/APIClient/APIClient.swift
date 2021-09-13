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
    
    /// Used for reobtating tokens when they expire and API client receives token expiration error
    let tokenRefresher: (ClientError, @escaping () -> Void) -> Void
    
    let cdnClient: CDNClient

    /// Used for syncrhonizing access to requestsQueue
    private let requestsAccessQueue = DispatchQueue(label: "io.getstream.requests")
    
    /// Stores request failed with token expired error for retrying them later
    private var requestsQueue = [RequestsQueueItem]()
    
    /// Shows whether the token is being refreshed at the moment
    private var isRefreshingToken: Bool = false
    
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
            self.request(urlRequest: urlRequest, timeout: timeout, completion: completion)
        }
    }
    
    private func request<Response: Decodable>(
        urlRequest: URLRequest,
        timeout: TimeInterval,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        let task = session.dataTask(with: urlRequest) { [decoder = self.decoder] (data, response, error) in
            do {
                let decodedResponse: Response = try decoder.decodeRequestResponse(
                    data: data,
                    response: response,
                    error: error
                )
                completion(.success(decodedResponse))
            } catch {
                if error is ClientError.ExpiredToken {
                    self.handleTokenExpirationError(
                        urlRequest: urlRequest,
                        timeout: timeout,
                        completion: completion
                    )
                } else {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
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
    func handleTokenExpirationError<Response: Decodable>(
        urlRequest: URLRequest,
        timeout: TimeInterval,
        completion: @escaping (Result<Response, Error>) -> Void
    ) {
        requestsAccessQueue.async {
            let item = RequestsQueueItem(
                requestAction: { self.request(
                    urlRequest: urlRequest,
                    timeout: timeout,
                    completion: completion
                )
                },
                failureAction: { completion(.failure(ClientError.ExpiredToken())) }
            )
            
            // The moment we queue a first request for execution later we also set a timeout for 60 seconds
            // after which we fail all the queued requests
            if self.requestsQueue.isEmpty {
                self.requestsAccessQueue.asyncAfter(deadline: .now() + timeout) {
                    self.requestsQueue.forEach { $0.failureAction() }
                    self.requestsQueue = []
                }
            }
            
            self.requestsQueue.append(item)
            
            // Only initiate token refreshing once
            guard !self.isRefreshingToken else { return }
            
            self.isRefreshingToken = true
            self.tokenRefresher(ClientError.ExpiredToken()) {
                self.requestsQueue.forEach { $0.requestAction() }
                self.requestsQueue = []
                self.isRefreshingToken = false
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
