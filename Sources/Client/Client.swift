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
    private(set) lazy var webSocket = WebSocket(URLRequest(url: baseURL.url(.webSocket)))
    private(set) lazy var urlSession = URLSession.shared
    private(set) lazy var urlSessionTaskDelegate = ClientURLSessionTaskDelegate()
    let callbackQueue: DispatchQueue?
    private let uuid = UUID()
    let logOptions: ClientLogger.Options
    let logger: ClientLogger?
    var user: User?
    
    public init(apiKey: String = Client.config.apiKey,
                baseURL: BaseURL = Client.config.baseURL,
                callbackQueue: DispatchQueue? = Client.config.callbackQueue,
                logOptions: ClientLogger.Options = Client.config.logOptions) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.callbackQueue = callbackQueue
        self.logOptions = logOptions
        
        if logOptions == .all || logOptions == .requests || logOptions == .requestsHeaders {
            logger = ClientLogger(icon: "🐴", options: logOptions)
        } else {
            logger = nil
        }
    }
    
    public func set(user: User, token: Token) {
        self.user = user
        self.token = token
        urlSession = setupURLSession(token: token)
        webSocket = setupWebSocket(user: user, token: token)
    }
}

extension Client {
    public struct Config {
        public let apiKey: String
        public let baseURL: BaseURL
        public let callbackQueue: DispatchQueue?
        public let logOptions: ClientLogger.Options
        
        public init(apiKey: String,
                    baseURL: BaseURL = BaseURL(),
                    callbackQueue: DispatchQueue? = nil,
                    logOptions: ClientLogger.Options = .none) {
            self.apiKey = apiKey
            self.baseURL = baseURL
            self.callbackQueue = callbackQueue
            self.logOptions = logOptions
        }
    }
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }
}
