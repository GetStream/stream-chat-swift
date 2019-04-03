//
//  Client.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias Token = String

public final class Client {
    public typealias Completion<T: Decodable> = (Result<T, ClientError>) -> Void
    
    public static var config = Config(apiKey: "")
    public static let shared = Client()

    let apiKey: String
    let baseURL: BaseURL
    var token: Token?
    var clientId: String?
    let callbackQueue: DispatchQueue?
    
    var user: User? {
        didSet { clientId = user != nil ? "\(user?.id ?? "")--\(uuid.uuidString.lowercased())" : nil }
    }
    
    private let uuid = UUID()
    private let logger: ClientLogger?
    
    public init(apiKey: String = Client.config.apiKey,
                baseURL: BaseURL = Client.config.baseURL,
                callbackQueue: DispatchQueue? = Client.config.callbackQueue,
                logsEnabled: Bool = Client.config.logsEnabled) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.callbackQueue = callbackQueue
        logger = logsEnabled ? ClientLogger() : nil
    }
    
    public func set(user: User, token: Token) {
        self.user = user
        self.token = token
    }
}

extension Client {
    public struct Config {
        public let apiKey: String
        public let baseURL: BaseURL
        public let callbackQueue: DispatchQueue?
        public let logsEnabled: Bool
        
        public init(apiKey: String, baseURL: BaseURL = BaseURL(), callbackQueue: DispatchQueue? = nil, logsEnabled: Bool = false) {
            self.apiKey = apiKey
            self.baseURL = baseURL
            self.callbackQueue = callbackQueue
            self.logsEnabled = logsEnabled
        }
    }
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }
}

// MARK: - Request

extension Client {
    
    func request<T: Decodable>(endpoint: EndpointProtocol, _ completion: @escaping Completion<T>) {
        guard let baseURL = baseURL.url(.https), let token = token else {
            completion(.failure(.invalidURL(self.baseURL.description)))
            return
        }
        
        guard let user = user, let clientId = clientId else {
            completion(.failure(.invalidURL(nil)))
            return
        }

        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.scheme
        urlComponents.host = baseURL.host
        urlComponents.path = baseURL.path
        
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "api_key", value: apiKey),
                                          URLQueryItem(name: "user_id", value: user.id),
                                          URLQueryItem(name: "client_id", value: clientId)]
        
        if let parameters = endpoint.parameters {
            queryItems.append(contentsOf: parameters.map { URLQueryItem(name: $0, value: $1) })
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url?.appendingPathComponent(endpoint.path) else {
            completion(.failure(.invalidURL(endpoint.path)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        
        urlRequest.allHTTPHeaderFields = ["Authorization": token,
                                          "Content-Type": "application/json",
                                          "stream-auth-type": "jwt"]
        
        if let body = endpoint.body {
            do {
                urlRequest.httpBody = try endpoint.bodyEncoder.encode(AnyEncodable(body))
            } catch {
                completion(.failure(.encodingFailure(error, object: body)))
            }
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] in
            self?.parse(data: $0, response: $1, error: $2, completion: completion)
        }
        
        logger?.log(urlRequest)
        task.resume()
    }
    
    private func parse<T: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping Completion<T>) {
        logger?.log(response, data: data)
        
        if let error = error {
            performInCallbackQueue { completion(.failure(.requestFailed(error))) }
            return
        }
        
        logger?.log(error)
        
        guard let data = data else {
            performInCallbackQueue { completion(.failure(.emptyBody)) }
            return
        }
        
        do {
            let response = try JSONDecoder.stream.decode(T.self, from: data)
            performInCallbackQueue { completion(.success(response)) }
        } catch {
            if let errorResponse = try? JSONDecoder.stream.decode(ClientErrorResponse.self, from: data) {
                performInCallbackQueue { completion(.failure(.responseError(errorResponse))) }
            } else {
                let rawBody: String
                
                if data.isEmpty {
                    rawBody = "<Empty>"
                } else if let string = try? data.prettyPrintedJSONString() {
                    rawBody = string
                } else {
                    rawBody = data.description
                }
                
                performInCallbackQueue { completion(.failure(.decodingFailure(error, rawBody: rawBody))) }
            }
        }
    }
    
    private func performInCallbackQueue(execute block: @escaping () -> Void) {
        if let callbackQueue = callbackQueue {
            callbackQueue.async(execute: block)
        } else {
            block()
        }
    }
}
