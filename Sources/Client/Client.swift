//
//  Client.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A token.
public typealias Token = String

/// A network client.
public final class Client {
    /// A request completion block.
    public typealias Completion<T: Decodable> = (Result<T, ClientError>) -> Void
    
    /// A client config (see `Config`).
    public static var config = Config(apiKey: "")
    /// A shared client.
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
    
    /// Init a network client.
    ///
    /// - Parameters:
    ///     - apiKey: a Stream Chat API key.
    ///     - baseURL: a base URL (see `BaseURL`).
    ///     - callbackQueue: a request callback queue, default nil (some background thread).
    ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
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
    
    /// Setup the current user.
    ///
    /// - Parameters:
    ///     - user: the current user (see `User`).
    ///     - token: a Stream Chat API token.
    public func set(user: User, token: Token) {
        self.user = user
        self.token = token
        urlSession = setupURLSession(token: token)
        webSocket = setupWebSocket(user: user, token: token)
    }
}

extension Client {
    /// A config for a shread `Client`.
    public struct Config {
        /// A Stream Chat API key.
        public let apiKey: String
        /// A base URL (see `BaseURL`).
        public let baseURL: BaseURL
        /// A request callback queue, default nil (some background thread).
        public let callbackQueue: DispatchQueue?
        /// Enable logs (see `ClientLogger.Options`), e.g. `.all`.
        public let logOptions: ClientLogger.Options
        
        /// Init a config for a shread `Client`.
        ///
        /// - Parameters:
        ///     - apiKey: a Stream Chat API key.
        ///     - baseURL: a base URL (see `BaseURL`).
        ///     - callbackQueue: a request callback queue, default nil (some background thread).
        ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
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
