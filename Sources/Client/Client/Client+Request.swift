//
//  Client+Request.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 20/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

extension Client {
    /// A Stream Chat version.
    public static let version: String = Bundle(for: Client.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    
    func setupURLSession(token: Token) -> URLSession {
        let headers = authHeaders(token: token)
        logger?.log(headers: headers)
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.httpAdditionalHeaders = headers
        return URLSession(configuration: config, delegate: urlSessionTaskDelegate, delegateQueue: nil)
    }
    
    func authHeaders(token: Token) -> [String: String] {
        var headers = [
            "X-Stream-Client": "stream-chat-swift-client-\(Client.version)",
            "X-Stream-Device": deviceModelName,
            "X-Stream-OS": "\(UIDevice.current.systemName)\(UIDevice.current.systemVersion)"]
        
        if token.isBlank {
            headers["Stream-Auth-Type"] = "anonymous"
        } else {
            headers["Stream-Auth-Type"] = "jwt"
            headers["Authorization"] = token
        }
        
        if let bundleId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
            headers["X-Stream-BundleId"] = bundleId
        }
        
        return headers
    }
    
    private var deviceModelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    /// Send a request.
    ///
    /// - Parameters:
    ///   - endpoint: an endpoint (see `Endpoint`).
    ///   - completion: a completion block.
    /// - Returns: an URLSessionTask that can be canncelled.
    @discardableResult
    public func request<T: Decodable>(endpoint: Endpoint, _ completion: @escaping Completion<T>) -> URLSessionTask {
        if let logger = logger {
            logger.log("Request: \(String(describing: endpoint).prefix(100))...", level: .debug)
        }
        
        if isExpiredTokenInProgress {
            retryRequester?.reconnectForExpiredToken(endpoint: endpoint, completion)
            return .empty
        }
        
        do {
            let task: URLSessionDataTask
            let queryItems = try self.queryItems(for: endpoint).get()
            let url = try requestURL(for: endpoint, queryItems: queryItems).get()
            let urlRequest: URLRequest
            
            if endpoint.isUploading {
                urlRequest = try encodeRequestForUpload(for: endpoint, url: url).get()
                logger?.timing("Uploading...", reset: true)
            } else {
                urlRequest = try encodeRequest(for: endpoint, url: url).get()
                logger?.timing("Sending request...", reset: true)
            }
            
            task = urlSession.dataTask(with: urlRequest) { [unowned self] in
                self.parse(data: $0, response: $1, error: $2, completion: completion)
                
                if self.isExpiredTokenInProgress {
                    self.logger?.log("Reconnect and retry a request when the token was expired...", level: .debug)
                    self.retryRequester?.reconnectForExpiredToken(endpoint: endpoint, completion)
                }
            }
            
            logger?.log(task.currentRequest ?? urlRequest)
            task.resume()
            
            return task
            
        } catch let error as ClientError {
            performInCallbackQueue { completion(.failure(error)) }
        } catch {
            performInCallbackQueue {  completion(.failure(.unexpectedError(nil, error))) }
        }
        
        return .empty
    }
    
    /// Send a progress request.
    ///
    /// - Parameters:
    ///   - endpoint: an endpoint (see `Endpoint`).
    ///   - completion: a completion block.
    /// - Returns: an URLSessionTask that can be canncelled.
    @discardableResult
    public func request<T: Decodable>(endpoint: Endpoint,
                                      _ progress: @escaping Progress,
                                      _ completion: @escaping Completion<T>) -> URLSessionTask {
        let task = request(endpoint: endpoint, completion)
        urlSessionTaskDelegate.addProgessHandler(id: task.taskIdentifier, progress)
        return task
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
        if apiKey.isEmpty {
            return .failure(.emptyAPIKey)
        }
        
        guard let connectionId = webSocket.lastConnectionId  else {
            return .failure(.emptyConnectionId)
        }
        
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey),
                          URLQueryItem(name: "client_id", value: connectionId)]
        
        if let endpointQueryItems = endpoint.jsonQueryItems {
            endpointQueryItems.forEach { (key: String, value: Encodable) in
                do {
                    let data = try JSONEncoder.default.encode(AnyEncodable(value))
                    
                    if let json = String(data: data, encoding: .utf8) {
                        queryItems.append(URLQueryItem(name: key, value: json))
                    }
                } catch {
                    logger?.log(error, message: "Encode jsonQueryItems")
                }
            }
        }
        
        if let endpointQueryItem = endpoint.queryItem {
            if let data = try? JSONEncoder.default.encode(AnyEncodable(endpointQueryItem)),
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
        
        return .success(queryItems)
    }
    
    private func encodeRequest(for endpoint: Endpoint, url: URL) -> Result<URLRequest, ClientError> {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = endpoint.body {
            let encodable = AnyEncodable(body)
            
            do {
                if let httpBody = try? JSONEncoder.defaultGzip.encode(encodable) {
                    urlRequest.httpBody = httpBody
                    urlRequest.addValue("gzip", forHTTPHeaderField: "Content-Encoding")
                } else {
                    urlRequest.httpBody = try JSONEncoder.default.encode(encodable)
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
            return .failure(.unexpectedError("Encoding unexpected endpoint \(endpoint) for a file uploading.", nil))
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
        
        if let error = error {
            if (error as NSError).code == NSURLErrorCancelled {
                logger?.log("🙅‍♂️ A request was cancelled. NSError \(NSURLErrorCancelled)")
            } else if (error as NSError).code == NSURLErrorNetworkConnectionLost {
                logger?.log("🤷‍♂️ The network connection was lost. NSError \(NSURLErrorNetworkConnectionLost)")
                logger?.log(error)
            } else {
                logger?.log(error)
            }
            
            performInCallbackQueue { completion(.failure(.requestFailed(error))) }
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger?.log(response, data: data, forceToShowData: true)
            let errorDescription = "Expecting HTTPURLResponse, but got \(response?.description ?? "nil")"
            performInCallbackQueue { completion(.failure(.unexpectedError(errorDescription, nil))) }
            return
        }

        logger?.log(response, data: data, forceToShowData: httpResponse.statusCode >= 400)
        
        guard let data = data, !data.isEmpty else {
            performInCallbackQueue {
                completion(.failure(.emptyBody(description: "Request to \(response?.url?.absoluteString ?? "<unknown URL>")")))
            }
            return
        }
        
        guard httpResponse.statusCode < 400 else {
            if let errorResponse = try? JSONDecoder.default.decode(ClientErrorResponse.self, from: data) {
                if errorResponse.message.contains("was deactivated") {
                    webSocket.disconnect()
                }
                
                if errorResponse.code == ClientErrorResponse.tokenExpiredErrorCode {
                    logger?.log("🀄️ Token is expired")
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
            let response = try JSONDecoder.default.decode(T.self, from: data)
            logger?.timing("Response decoded")
            performInCallbackQueue { completion(.success(response)) }
        } catch {
            logger?.log(error)
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

extension URLSessionTask {
    static let empty = URLSessionTask()
}
