//
//  Client+Request.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 20/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Client {
    
    func setupURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        
        config.httpAdditionalHeaders = ["Authorization": token ?? "",
                                        "Content-Type": "application/json",
                                        "stream-auth-type": "jwt"]
        
        return URLSession(configuration: config)
    }
    
    func request<T: Decodable>(endpoint: EndpointProtocol, _ completion: @escaping Completion<T>) {
        if token == nil {
            completion(.failure(.emptyToken))
            return
        }
        
        guard let baseURL = baseURL.url(.https) else {
            completion(.failure(.invalidURL(self.baseURL.description)))
            return
        }
        
        guard let user = user, let clientId = clientId else {
            return
        }
        
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey),
                          URLQueryItem(name: "user_id", value: user.id),
                          URLQueryItem(name: "client_id", value: clientId)]
        
        guard !queryItems.isEmpty else {
            completion(.failure(.invalidURL(nil)))
            return
        }
        
        if let parameters = endpoint.parameters {
            queryItems.append(contentsOf: parameters.map { URLQueryItem(name: $0, value: $1) })
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.scheme
        urlComponents.host = baseURL.host
        urlComponents.path = baseURL.path
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url?.appendingPathComponent(endpoint.path) else {
            completion(.failure(.invalidURL(endpoint.path)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        
        if let body = endpoint.body {
            do {
                urlRequest.httpBody = try JSONEncoder.stream.encode(AnyEncodable(body))
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
