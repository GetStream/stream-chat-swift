//
// APIClient.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object allowing making request to Stream Chat servers.
class APIClient {
    /// An object encapsulating all dependencies of `APIClient`.
    struct Environment {
        var requestEncoderBuilder: (_ baseURL: URL, _ apiKey: APIKey) -> RequestEncoder = DefaultRequestEncoder.init
        var requestDecoderBuilder: () -> RequestDecoder = DefaultRequestDecoder.init
    }
    
    /// The base URL for all requests.
    let baseURL: URL
    
    /// The app specific API key.
    let apiKey: APIKey
    
    /// The URL session used for all requests.
    let session: URLSession
    
    /// `APIClient` uses this object to encode `Endpoint` objects into `URLRequest`s.
    private(set) lazy var encoder: RequestEncoder = {
        var encoder = self.environment.requestEncoderBuilder(baseURL, apiKey)
        encoder.connectionIdProviderDelegate = self
        return encoder
    }()
    
    /// `APIClient` uses this object to decode the results of network requests.
    private(set) lazy var decoder: RequestDecoder = self.environment.requestDecoderBuilder()
    
    private let environment: Environment
    
    /// The current connection id
    @Atomic private var connectionId: String?
    
    /// An array of requests waiting for the connection id
    @Atomic private var connectionIdWaiters: [(String?) -> Void] = []
    
    /// Creates a new `APIClient`.
    ///
    /// - Parameters:
    ///   - apiKey: The app specific API key.
    ///   - baseURL: The base URL used for all outgoing requests.
    ///   - sessionConfiguration: The session configuration `APIClient` uses to create its `URLSession`.
    ///   - environment: An object specifying `APIClient` dependencies.
    init(apiKey: APIKey, baseURL: URL, sessionConfiguration: URLSessionConfiguration, environment: Environment = .init()) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        session = URLSession(configuration: sessionConfiguration)
        self.environment = environment
    }
    
    deinit {
        connectionIdWaiters.forEach { $0(nil) }
        connectionIdWaiters.removeAll()
    }
    
    /// Performs a network request.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` used to create the network request.
    ///   - completion: Called when the networking request is finished.
    func request<Response: Decodable>(endpoint: Endpoint<Response>, completion: @escaping (Result<Response, Error>) -> Void) {
        encoder.encodeRequest(for: endpoint) { [unowned self] (requestResult) in
            let urlRequest: URLRequest
            do {
                urlRequest = try requestResult.get()
            } catch {
                log.error(error)
                completion(.failure(error))
                return
            }
            
            let task = self.session.dataTask(with: urlRequest) { [decoder = self.decoder] (data, response, error) in
                do {
                    let decodedResponse: Response = try decoder.decodeRequestResponse(data: data, response: response,
                                                                                      error: error)
                    completion(.success(decodedResponse))
                } catch {
                    completion(.failure(error))
                }
            }
            
            task.resume()
        }
    }
}

/// `APIClient` listens for `WebSocketClient` connection updates so it can forward the current connection id to
/// its `RequestEncoder`.
extension APIClient: ConnectionStateDelegate {
    func webSocketClient(_ client: WebSocketClient, didUpdateConectionState state: ConnectionState) {
        if case let .connected(connectionId) = state {
            self.connectionId = connectionId
            connectionIdWaiters.forEach { $0(connectionId) }
            connectionIdWaiters.removeAll()
        } else {
            connectionId = nil
        }
    }
}

/// `APIClient` provides connection id to the `RequestEncoder` it uses.
extension APIClient: ConnectionIdProviderDelegate {
    func provideConnectionId(completion: @escaping (String?) -> Void) {
        if let connectionId = connectionId {
            completion(connectionId)
        } else {
            connectionIdWaiters.append(completion)
        }
    }
}
