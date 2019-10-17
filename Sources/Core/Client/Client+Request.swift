//
//  Client+Request.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 20/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Client {
    /// A Stream Chat version.
    public static let version: String = Bundle(for: Client.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    
    func setupURLSession(token: Token) -> URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        
        var headers = ["X-Stream-Client": "stream-chat-swift-client-\(Client.version)"]
        
        if token.isBlank {
            headers["Stream-Auth-Type"] = "anonymous"
        } else {
            headers["Stream-Auth-Type"] = "jwt"
            headers["Authorization"] = token
        }
        
        config.httpAdditionalHeaders = headers
        
        return URLSession(configuration: config, delegate: urlSessionTaskDelegate, delegateQueue: nil)
    }
    
    /// Send a request.
    ///
    /// - Parameters:
    ///   - endpoint: an endpoint (see `Endpoint`).
    ///   - completion: a completion block.
    /// - Returns: an URLSessionDataTask that can be canncelled.
    @discardableResult
    public func request<T: Decodable>(endpoint: Endpoint, _ completion: @escaping Completion<T>) -> URLSessionDataTask {
        if let logger = logger {
            let endpointDescription = String(describing: endpoint).prefix(while: { $0 != "(" }).uppercased()
            logger.timing("Prepare for request: \(endpointDescription)", reset: true)
            logger.log(urlSession.configuration)
        }
        
        func retryRequestForExpiredToken() {
            connection.connected()
                .take(1)
                .subscribe(onNext: { [unowned self] in self.request(endpoint: endpoint, completion) })
                .disposed(by: expiredTokenDisposeBag)
        }
        
        if isExpiredTokenInProgress {
            retryRequestForExpiredToken()
            return URLSessionDataTask()
        }
        
        do {
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
            
            task = urlSession.dataTask(with: urlRequest) { [unowned self] in
                self.parse(data: $0, response: $1, error: $2, completion: completion)
                
                if self.isExpiredTokenInProgress {
                    retryRequestForExpiredToken()
                }
            }
            
            logger?.log(task.currentRequest ?? urlRequest)
            task.resume()
            
            return task
            
        } catch let error as ClientError {
            completion(.failure(error))
        } catch {
            completion(.failure(.unexpectedError(description: "\(error)")))
        }
        
        return URLSessionDataTask()
    }
    
    private func requestURL(for endpoint: Endpoint, queryItems: [URLQueryItem]) -> Result<URL, ClientError> {
        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.baseURL.scheme
        urlComponents.host = baseURL.baseURL.host
        urlComponents.path = baseURL.baseURL.path
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url?.appendingPathComponent(endpoint.path) else {
            return .failure(.invalidURL("For \(urlComponents) with appending path \(endpoint.path)"))
        }
        
        return .success(url)
    }
    
    private func queryItems(for endpoint: Endpoint) -> Result<[URLQueryItem], ClientError> {
        guard let user = user else {
            return .failure(.emptyUser)
        }
        
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey),
                          URLQueryItem(name: "user_id", value: user.id)]
        
        if let connectionId = webSocket.lastConnectionId {
            queryItems.append(URLQueryItem(name: "client_id", value: connectionId))
        } else if case .guestToken = endpoint {} else {
            return .failure(.emptyConnectionId)
        }
        
        guard !queryItems.isEmpty else {
            return .failure(.invalidURL(nil))
        }
        
        if let endpointQueryItems = endpoint.jsonQueryItems {
            endpointQueryItems.forEach { (key: String, value: Encodable) in
                do {
                    let data = try JSONEncoder.stream.encode(AnyEncodable(value))
                    
                    if let json = String(data: data, encoding: .utf8) {
                        queryItems.append(URLQueryItem(name: key, value: json))
                    }
                } catch {
                    ClientLogger.log("🐴", error, message: "Encode jsonQueryItems")
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
    
    private func encodeRequest(for endpoint: Endpoint, url: URL) -> Result<URLRequest, ClientError> {
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
    private func encodeRequestForUpload(for endpoint: Endpoint, url: URL) -> Result<URLRequest, ClientError> {
        let multipartFormData: MultipartFormData
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        
        switch endpoint {
        case .sendImage(let fileName, let mimeType, let data, _),
             .sendFile(let fileName, let mimeType, let data, _):
            multipartFormData = MultipartFormData(data, fileName: fileName, mimeType: mimeType)
        default:
            return .failure(.unexpectedError(description: "Encoding unexpected endpoint \(endpoint) for a file uploading."))
        }
        
        let data = multipartFormData.multipartFormData
        logger?.log("⏫ Uploading \(data.description)")
        urlRequest.addValue("multipart/form-data; boundary=\(multipartFormData.boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = data
        
        return .success(urlRequest)
    }
}

// MARK: - Parsing response

extension Client {
    
    private func parse<T: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping Completion<T>) {
        logger?.timing("Response received")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger?.log(response, data: data, forceToShowData: true)
            let errorDescription = "Expecting HTTPURLResponse, but got \(response?.description ?? "nil")"
            performInCallbackQueue { completion(.failure(.unexpectedError(description: errorDescription))) }
            return
        }

        logger?.log(response, data: data, forceToShowData: httpResponse.statusCode >= 400)
        
        if let error = error {
            if (error as NSError).code == NSURLErrorCancelled {
                logger?.log("A request was cancelled: \(error)")
            } else {
                ClientLogger.log("🐴", error)
            }
            
            performInCallbackQueue { completion(.failure(.requestFailed(error))) }
            return
        }
        
        guard let data = data, !data.isEmpty else {
            performInCallbackQueue {
                completion(.failure(.emptyBody(description: "Request to \(response?.url?.absoluteString ?? "<unknown URL>")")))
            }
            return
        }
        
        guard httpResponse.statusCode < 400 else {
            if let errorResponse = try? JSONDecoder.stream.decode(ClientErrorResponse.self, from: data) {
                if errorResponse.message.contains("was deactivated") {
                    webSocket.disconnect()
                }
                
                if errorResponse.code == ClientErrorResponse.tokenExpiredErrorCode {
                    logger?.log("🀄️", "The Token is expired")
                    touchTokenProvider()
                    return
                }
                
                performInCallbackQueue { completion(.failure(.responseError(errorResponse))) }
            } else {
                performInCallbackQueue { completion(.failure(.requestFailed(error))) }
            }
            return
        }
        
        do {
            logger?.timing("Prepare for decoding")
            let response = try JSONDecoder.stream.decode(T.self, from: data)
            logger?.timing("Response decoded")
            performInCallbackQueue { completion(.success(response)) }
        } catch {
            ClientLogger.log("🐴", error)
            performInCallbackQueue { completion(.failure(.decodingFailure(error))) }
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
