//
// RequestEncoder.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// On object responsible for creating a `URLRequest`, and encoding all required and `Endpoint` specific data to it.
protocol RequestEncoder {
    /// A delegate the encoder uses for obtaining the current `connectionId`.
    ///
    /// Trying to encode an `Endpoint` with the `requiresConnectionId` set to `true` without setting the delegate
    var connectionIdProviderDelegate: ConnectionIdProviderDelegate? { get set }
    
    /// Asynchronously creates a new `URLRequest` with the data from the `Endpoint`. It also adds all required data
    /// like an api key, etc.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` to be encoded.
    ///   - completion: Called when the encoded `URLRequest` is ready. Called with en `Error` if the encoding fails.
    func encodeRequest<ResponsePayload: Decodable>(for endpoint: Endpoint<ResponsePayload>,
                                                   completion: @escaping (Result<URLRequest, Error>) -> Void)
    
    /// Creates a new `RequestEncoder`.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all requests.
    ///   - apiKey: The app specific API key.
    init(baseURL: URL, apiKey: APIKey)
}

/// The default implementation of `RequestEncoder`.
struct DefaultRequestEncoder: RequestEncoder {
    let baseURL: URL
    let apiKey: APIKey
    
    weak var connectionIdProviderDelegate: ConnectionIdProviderDelegate?
    
    func encodeRequest<ResponsePayload: Decodable>(for endpoint: Endpoint<ResponsePayload>,
                                                   completion: @escaping (Result<URLRequest, Error>) -> Void) {
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
        
        if endpoint.requiresConnectionId {
            log.assert(connectionIdProviderDelegate != nil,
                       "The endpoind requiers `connectionId` but `connectionIdProviderDelegate` is not set.")
            
            connectionIdProviderDelegate?.provideConnectionId { (connectionId) in
                guard let connectionId = connectionId else {
                    completion(.failure(ClientError.MissingConnectionId("Failed to get `connectionId`, request can't be created.")))
                    return
                }
                
                do {
                    request.url = try request.url?.appendingQueryItems(["connection_id": connectionId])
                } catch {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(request))
            }
            
        } else {
            completion(.success(request))
        }
    }
    
    init(baseURL: URL, apiKey: APIKey) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - Private
    
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
            try encodeGETRequestBody(request: &request, endpoint: endpoint)
        case .post:
            try encodePOSTRequestBody(request: &request, endpoint: endpoint)
        }
    }
    
    private func encodeGETRequestBody<T: Decodable>(request: inout URLRequest, endpoint: Endpoint<T>) throws {
        log.assert(endpoint.method == .get, "Endpoint method is \(endpoint.method) but must be GET.")
        log.assert(request.url != nil, "Request URL must not be `nil`.")
        
        guard let body = endpoint.body else { return }
        try encodeJSONToQueryItems(request: &request, data: body)
    }
    
    private func encodePOSTRequestBody<T: Decodable>(request: inout URLRequest, endpoint: Endpoint<T>) throws {
        log.assert(endpoint.method == .post, "Request method is \(endpoint.method) but must be POST.")
        guard let body = endpoint.body else { return }
        
        request.httpBody = try JSONEncoder.stream.encode(AnyEncodable(body))
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
                    log.error("Skipping encoding data for key:`\(key)` because it's not a valid JSON: "
                        + "\(String(data: data, encoding: .utf8) ?? "nil")")
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
        guard let newURL = components.url else {
            throw ClientError.InvalidURL("Can't create a new `URL` after appending query items: \(items).")
        }
        return newURL
    }
}

protocol ConnectionIdProviderDelegate: AnyObject {
    func provideConnectionId(completion: @escaping (_ connectionId: ConnectionId?) -> Void)
}

extension ClientError {
    class InvalidURL: CustomMessageError {}
    class InvalidJSON: CustomMessageError {}
    class MissingConnectionId: CustomMessageError {}
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
