//
//  Client+Request.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 20/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Client {
    static let version: String = Bundle(for: Client.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    
    func setupURLSession(token: Token) -> URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        
        config.httpAdditionalHeaders = ["Authorization": token,
                                        "Content-Type": "application/json",
                                        "Stream-Auth-Type": "jwt",
                                        "X-Stream-Client": "stream-chat-swift-client-\(Client.version)"]
        
        return URLSession(configuration: config)
    }
    
    @discardableResult
    func request<T: Decodable>(endpoint: EndpointProtocol,
                               connectionId: String,
                               _ completion: @escaping Completion<T>) -> URLSessionDataTask {
        guard let user = user else {
            completion(.failure(.emptyUser))
            return URLSessionDataTask()
        }
        
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey),
                          URLQueryItem(name: "user_id", value: user.id),
                          URLQueryItem(name: "client_id", value: connectionId)]
        
        guard !queryItems.isEmpty else {
            completion(.failure(.invalidURL(nil)))
            return URLSessionDataTask()
        }
        
        if let parameters = endpoint.parameters {
            queryItems.append(contentsOf: parameters.map { URLQueryItem(name: $0, value: $1) })
        }
        
        let baseURL = self.baseURL.url(.https)
        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.scheme
        urlComponents.host = baseURL.host
        urlComponents.path = baseURL.path
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url?.appendingPathComponent(endpoint.path) else {
            completion(.failure(.invalidURL(endpoint.path)))
            return URLSessionDataTask()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        
        if let body = endpoint.body {
            let encodable = AnyEncodable(body)
            
            do {
                if let httpBody = try? JSONEncoder.streamGzip.encode(encodable) {
                   urlRequest.httpBody = httpBody
                   urlRequest.addValue("gzip", forHTTPHeaderField: "Content-Encoding")
                } else {
                   urlRequest.httpBody = try JSONEncoder.stream.encode(encodable)
                }
            } catch {
                completion(.failure(.encodingFailure(error, object: body)))
            }
        }
        
        let task = urlSession.dataTask(with: urlRequest) { [weak self] in
            self?.parse(data: $0, response: $1, error: $2, completion: completion)
        }
        
        logger?.log(urlSession.configuration)
        logger?.log(urlRequest)
        task.resume()
        
        return task
    }
    
    private func parse<T: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping Completion<T>) {
        let httpResponse = response as? HTTPURLResponse
        logger?.log(response, data: (logOptions != .requestsHeaders || (httpResponse?.statusCode ?? 400) >= 400) ? data : nil)
        
        if let error = error {
            logger?.log(error)
            performInCallbackQueue { completion(.failure(.requestFailed(error))) }
            return
        }
        
        guard let data = data, !data.isEmpty else {
            performInCallbackQueue { completion(.failure(.emptyBody)) }
            return
        }
        
        do {
            let response = try JSONDecoder.stream.decode(T.self, from: data)
            performInCallbackQueue { completion(.success(response)) }
        } catch {
            logger?.log(error)
            
            if let errorResponse = try? JSONDecoder.stream.decode(ClientErrorResponse.self, from: data) {
                performInCallbackQueue { completion(.failure(.responseError(errorResponse))) }
            } else {
                performInCallbackQueue { completion(.failure(.decodingFailure(error))) }
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
