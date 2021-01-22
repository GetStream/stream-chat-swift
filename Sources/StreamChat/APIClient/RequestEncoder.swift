//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// On object responsible for creating a `URLRequest`, and encoding all required and `Endpoint` specific data to it.
protocol RequestEncoder {
    /// A delegate the encoder uses for obtaining the current `connectionId`.
    ///
    /// Trying to encode an `Endpoint` with the `requiresConnectionId` set to `true` without setting the delegate
    var connectionDetailsProviderDelegate: ConnectionDetailsProviderDelegate? { get set }
    
    /// Asynchronously creates a new `URLRequest` with the data from the `Endpoint`. It also adds all required data
    /// like an api key, etc.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` to be encoded.
    ///   - completion: Called when the encoded `URLRequest` is ready. Called with en `Error` if the encoding fails.
    func encodeRequest<ResponsePayload: Decodable>(
        for endpoint: Endpoint<ResponsePayload>,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    )
    
    /// Creates a new `RequestEncoder`.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all requests.
    ///   - apiKey: The app specific API key.
    init(baseURL: URL, apiKey: APIKey)
}

extension RequestEncoder {
    /// Synchronously creates a new `URLRequest` with the data from the `Endpoint`. It also adds all required data
    /// like an api key, etc.
    ///
    /// - Warning: ⚠️ This method shouldn't be called for endpoints with `requiresConnectionId == true` because they
    /// require an async call to obtain `connectionId`. Use the asynchronous variant of this function instead.
    ///
    /// - Parameter endpoint: The `Endpoint` to be encoded.
    func encodeRequest<ResponsePayload: Decodable>(for endpoint: Endpoint<ResponsePayload>) throws -> URLRequest {
        log.assert(
            !endpoint.requiresConnectionId,
            "Use the asynchronous version of `encodeRequest` for endpoints with `requiresConnectionId` set to `true.`"
        )
        
        var result: Result<URLRequest, Error>?
        encodeRequest(for: endpoint) { result = $0 }
        
        log.assert(result != nil, "`encodeRequest` with `requiresConnectionId == false` should return immediatelly.")
        
        return try result!.get()
    }
}

/// The default implementation of `RequestEncoder`.
struct DefaultRequestEncoder: RequestEncoder {
    let baseURL: URL
    let apiKey: APIKey
    
    weak var connectionDetailsProviderDelegate: ConnectionDetailsProviderDelegate?
    
    func encodeRequest<ResponsePayload: Decodable>(
        for endpoint: Endpoint<ResponsePayload>,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var request: URLRequest
        
        do {
            // Prepare the URL
            var url = try encodeRequestURL(for: endpoint)
            url = try url.appendingQueryItems(["api_key": apiKey.apiKeyString])
            
            // Create a request
            request = URLRequest(url: url)
            request.httpMethod = endpoint.method.rawValue
            
            // Encode endpoint-specific query items
            if let queryItems = endpoint.queryItems {
                try encodeJSONToQueryItems(request: &request, data: queryItems)
            }
            
            try encodeRequestBody(request: &request, endpoint: endpoint)
        } catch {
            completion(.failure(error))
            return
        }

        addAuthorizationHeader(request: request, endpoint: endpoint) {
            switch $0 {
            case let .success(requestWithAuth):
                self.addConnectionIdIfNeeded(
                    request: requestWithAuth,
                    endpoint: endpoint,
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    init(baseURL: URL, apiKey: APIKey) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - Private

    private func addAuthorizationHeader<T: Decodable>(
        request: URLRequest,
        endpoint: Endpoint<T>,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        guard endpoint.requiresToken else {
            var updatedRequest = request
            updatedRequest.setHTTPHeaders(.anonymousStreamAuth)
            completion(.success(updatedRequest))
            return
        }

        log.assert(
            connectionDetailsProviderDelegate != nil,
            "The endpoint requires `token` but `connectionDetailsProviderDelegate` is not set."
        )

        connectionDetailsProviderDelegate?.provideToken {
            if let token = $0 {
                var updatedRequest = request

                if token.userId.isAnonymousUser {
                    updatedRequest.setHTTPHeaders(.anonymousStreamAuth)
                } else {
                    updatedRequest.setHTTPHeaders(.jwtStreamAuth, .authorization(token.rawValue))
                }

                completion(.success(updatedRequest))
            } else {
                let error = ClientError.MissingToken("Failed to get `token`, request can't be created.")
                completion(.failure(error))
            }
        }
    }

    private func addConnectionIdIfNeeded<T: Decodable>(
        request: URLRequest,
        endpoint: Endpoint<T>,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        guard endpoint.requiresConnectionId else {
            completion(.success(request))
            return
        }

        log.assert(
            connectionDetailsProviderDelegate != nil,
            "The endpoint requires `connectionId` but `connectionDetailsProviderDelegate` is not set."
        )

        connectionDetailsProviderDelegate?.provideConnectionId {
            do {
                if let connectionId = $0 {
                    var updatedRequest = request
                    updatedRequest.url = try updatedRequest.url?.appendingQueryItems(["connection_id": connectionId])
                    completion(.success(updatedRequest))
                } else {
                    throw ClientError.MissingConnectionId("Failed to get `connectionId`, request can't be created.")
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func encodeRequestURL<T: Decodable>(for endpoint: Endpoint<T>) throws -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.scheme
        urlComponents.host = baseURL.host
        urlComponents.path = baseURL.path
        
        guard var url = urlComponents.url else {
            throw ClientError.InvalidURL("URL can't be created using components: \(urlComponents)")
        }
        
        url = url.appendingPathComponent(endpoint.path)
        return url
    }
    
    private func encodeRequestBody<T: Decodable>(request: inout URLRequest, endpoint: Endpoint<T>) throws {
        switch endpoint.method {
        case .get, .delete:
            guard let body = endpoint.body else { return }
            try encodeJSONToQueryItems(request: &request, data: body)
        case .post, .patch:
            let body = try JSONEncoder.stream.encode(AnyEncodable(endpoint.body ?? EmptyBody()))
            request.httpBody = body
        }
    }
    
    private func encodeJSONToQueryItems(request: inout URLRequest, data: Encodable) throws {
        let data = try JSONEncoder.stream.encode(AnyEncodable(data))
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClientError.InvalidJSON("Data is not a valid JSON: \(String(data: data, encoding: .utf8) ?? "nil")")
        }
        
        let bodyQueryItems = json.compactMap { (key, value) -> URLQueryItem? in
            // If the `value` is a JSON, encode it like that
            if let jsonValue = value as? [String: Any] {
                do {
                    let jsonStringValue = try JSONSerialization.data(withJSONObject: jsonValue)
                    return URLQueryItem(name: key, value: String(data: jsonStringValue, encoding: .utf8))
                } catch {
                    log.error(
                        "Skipping encoding data for key:`\(key)` because it's not a valid JSON: "
                            + "\(String(data: data, encoding: .utf8) ?? "nil")"
                    )
                }
            }
            
            return URLQueryItem(name: key, value: String(describing: value))
        }
        
        log.assert(request.url != nil, "Request URL must not be `nil`.")
        
        request.url = try request.url!.appendingQueryItems(bodyQueryItems)
    }
}

private extension URL {
    func appendingQueryItems(_ items: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            throw ClientError.InvalidURL("Can't create `URLComponents` from the url: \(self).")
        }
        let existingQueryItems = components.queryItems ?? []
        components.queryItems = existingQueryItems + items
        
        // Manually replace all occurrences of "+" in the query because it can be understood as a placeholder
        // value for a space. We want to keep it as "+" so we have to manually percent-encode it.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        
        guard let newURL = components.url else {
            throw ClientError.InvalidURL("Can't create a new `URL` after appending query items: \(items).")
        }
        return newURL
    }
}

protocol ConnectionDetailsProviderDelegate: AnyObject {
    func provideConnectionId(completion: @escaping (_ connectionId: ConnectionId?) -> Void)
    func provideToken(completion: @escaping (Token?) -> Void)
}

extension ClientError {
    class InvalidURL: ClientError {}
    class InvalidJSON: ClientError {}
    class MissingConnectionId: ClientError {}
}

/// A helper extension allowing to create `URLQueryItems` using a dictionary literal like:
/// ```
/// let queryItems = ["item1": "Luke", "item2": nil, "item3": "Leia"]
/// ```
extension Array: ExpressibleByDictionaryLiteral where Element == URLQueryItem {
    public init(dictionaryLiteral elements: (String, String?)...) {
        self = elements.map(URLQueryItem.init)
    }
}
