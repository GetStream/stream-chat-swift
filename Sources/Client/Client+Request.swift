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
                                        "Stream-Auth-Type": "jwt",
                                        "X-Stream-Client": "stream-chat-swift-client-\(Client.version)"]
        
        return URLSession(configuration: config, delegate: urlSessionTaskDelegate, delegateQueue: nil)
    }
    
    @discardableResult
    func request<T: Decodable>(endpoint: ChatEndpoint, _ completion: @escaping Completion<T>) -> URLSessionDataTask {
        do {
            logger?.timing("Prepare for request", reset: true)
            logger?.log(urlSession.configuration)
            let task: URLSessionDataTask
            let queryItems = try self.queryItems(for: endpoint).get()
            let url = try requestURL(for: endpoint, queryItems: queryItems).get()
            let urlRequest: URLRequest
            
            if endpoint.isUploading {
                urlRequest = try encodeRequestForUpload(for: endpoint, url: url).get()
                logger?.timing("Uploading...")
            } else {
                urlRequest = try encodeRequest(for: endpoint, url: url).get()
                logger?.timing("Sending request...")
            }
            
            task = urlSession.dataTask(with: urlRequest) { [weak self] in
                self?.parse(data: $0, response: $1, error: $2, completion: completion)
            }
            
            logger?.log(task.currentRequest ?? urlRequest)
            task.resume()
            
            return task
            
        } catch let error as ClientError {
            completion(.failure(error))
        } catch {
            completion(.failure(.unexpectedError))
        }
        
        return URLSessionDataTask()
    }
    
    private func requestURL(for endpoint: ChatEndpoint, queryItems: [URLQueryItem]) -> Result<URL, ClientError> {
        let baseURL = self.baseURL.url(.https)
        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.scheme
        urlComponents.host = baseURL.host
        urlComponents.path = baseURL.path
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url?.appendingPathComponent(endpoint.path) else {
            return .failure(.invalidURL(endpoint.path))
        }
        
        return .success(url)
    }
    
    private func queryItems(for endpoint: ChatEndpoint) -> Result<[URLQueryItem], ClientError> {
        guard let connectionId = webSocket.lastConnectionId else {
            return .failure(.emptyConnectionId)
        }
        
        guard let user = user else {
            return .failure(.emptyUser)
        }
        
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey),
                          URLQueryItem(name: "user_id", value: user.id),
                          URLQueryItem(name: "client_id", value: connectionId)]
        
        guard !queryItems.isEmpty else {
            return .failure(.invalidURL(nil))
        }
        
        if let endpointQueryItems = endpoint.queryItems {
            endpointQueryItems.forEach { (key: String, value: Encodable) in
                if let data = try? JSONEncoder.stream.encode(AnyEncodable(value)),
                    let json = String(data: data, encoding: .utf8) {
                    queryItems.append(URLQueryItem(name: key, value: json))
                }
            }
        }
        
        if let endpointQueryItem = endpoint.queryItem {
            if let data = try? JSONEncoder.stream.encode(AnyEncodable(endpointQueryItem)),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                json.forEach { key, value in
                    if let stringValue = value as? String {
                        queryItems.append(URLQueryItem(name: key, value: stringValue))
                    } else if let intValue = value as? Int {
                        queryItems.append(URLQueryItem(name: key, value: String(intValue)))
                    } else if let floatValue = value as? Float {
                        queryItems.append(URLQueryItem(name: key, value: String(floatValue)))
                    } else if let doubleValue = value as? Double {
                        queryItems.append(URLQueryItem(name: key, value: String(doubleValue)))
                    } else if let value = value as? CustomStringConvertible {
                        queryItems.append(URLQueryItem(name: key, value: value.description))
                    }
                }
            }
        }
        
        logger?.log(queryItems)
        
        return .success(queryItems)
    }
    
    private func encodeRequest(for endpoint: ChatEndpoint, url: URL) -> Result<URLRequest, ClientError> {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
                return .failure(.encodingFailure(error, object: body))
            }
        }
        
        return .success(urlRequest)
    }
}

// MARK: - Upload files

extension Client {
    private func encodeRequestForUpload(for endpoint: ChatEndpoint, url: URL) -> Result<URLRequest, ClientError> {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        
        switch endpoint {
        case let .sendImage(fileName, mimeType, data, _):
            logger?.log("Data size: \(data.description)")
            let multipartFormData = MultipartFormData(provider: .data(data), fileName: fileName, mimeType: mimeType)
            
            if let data = multipartFormData.data {
                urlRequest.addValue("multipart/form-data; boundary=\(multipartFormData.boundary)", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = data
            }
        default:
            return .failure(.unexpectedError)
        }
        
        return .success(urlRequest)
    }
}

// MARK: - Parsing response

extension Client {
    
    private func parse<T: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping Completion<T>) {
        let httpResponse = response as? HTTPURLResponse
        logger?.timing("Response received")
        logger?.log(response, data: data, forceToShowData: (httpResponse?.statusCode ?? 400) >= 400)
        
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
            logger?.timing("Prepare for decoding")
            let response = try JSONDecoder.stream.decode(T.self, from: data)
            logger?.timing("Response decoded")
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
