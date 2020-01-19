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
            "X-Stream-Client": "stream-chat-swift-client-\(Environment.version)",
            "X-Stream-Device": Environment.deviceModelName,
            "X-Stream-OS": Environment.systemName,
            "X-Stream-App-Environment": Environment.name]
        
        if token.isBlank {
            headers["Stream-Auth-Type"] = "anonymous"
        } else {
            headers["Stream-Auth-Type"] = "jwt"
            headers["Authorization"] = token
        }
        
        if let bundleId = Bundle.main.id {
            headers["X-Stream-BundleId"] = bundleId
        }
        
        return headers
    }
    
    func checkLatestVersion() {
        // Check latest pod version and log warning if there's a new version
        guard let podUrl = URL(string: "https://trunk.cocoapods.org/api/v1/pods/StreamChat") else { return }
        
        // swiftlint:disable nesting
        struct PodTrunk: Codable {
            struct Version: Codable {
                let name: String
            }
            
            let versions: [Version]
        }
        // swiftlint:enable nesting
        
        let versionTask = URLSession(configuration: .default).dataTask(with: podUrl) { data, _, error in
            guard let data = data, error == nil else {
                return
            }
            do {
                let podTrunk = try JSONDecoder().decode(PodTrunk.self, from: data)
                if let latestVersion = podTrunk.versions.last?.name, latestVersion > Environment.version {
                    ClientLogger.logger("📢", "", "StreamChat \(latestVersion) is released (you are on \(Environment.version)). "
                        + "It's recommended to update to the latest version.")
                }
            } catch {}
        }
        versionTask.resume()
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
            completion(.failure(.unexpectedError(description: error.localizedDescription, error: error)))
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
            let errorDescription = "Encoding unexpected endpoint \(endpoint) for a file uploading."
            return .failure(.unexpectedError(description: errorDescription, error: nil))
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
            performInCallbackQueue { completion(.failure(.unexpectedError(description: errorDescription, error: nil))) }
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

// MARK: - Client Completion Side Effects

extension Client {
    
    /// Performs side effect works for a success result before of an original completion block.
    /// - Parameters:
    ///   - completion: an original completion block.
    ///   - before: a side effect will be executed before the original completion block.
    func beforeCompletion<T: Decodable>(_ completion: @escaping Client.Completion<T>, _ before: @escaping (T) -> Void) -> Client.Completion<T> {
        return addSideEffect(for: completion, before: before)
    }
    
    /// Performs side effect works for a success result after of an original completion block.
    /// - Parameters:
    ///   - completion: an original completion block.
    ///   - after: a side effect will be executed after the original completion block.
    func afterCompletion<T: Decodable>(_ completion: @escaping Client.Completion<T>, _ after: @escaping (T) -> Void) -> Client.Completion<T> {
        return addSideEffect(for: completion, after: after)
    }
    
    /// Performs side effect works for a success result before and after of an original completion block.
    /// - Parameters:
    ///   - completion: an original completion block.
    ///   - before: a side effect will be executed before the original completion block.
    ///   - after: a side effect will be executed after the original completion block.
    func addSideEffect<T: Decodable>(for completion: @escaping Client.Completion<T>,
                                     before: @escaping (T) -> Void = { _ in },
                                     after: @escaping (T) -> Void = { _ in }) -> Client.Completion<T> {
        return { result in
            guard let value = try? result.get() else {
                completion(result)
                return
            }
            
            before(value)
            completion(result)
            after(value)
        }
    }
}

extension URLSessionTask {
    static let empty = URLSessionTask()
}
