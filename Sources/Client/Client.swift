//
//  Client.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

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
    
    /// Setup the current user with a given token.
    ///
    /// - Parameters:
    ///     - user: the current user (see `User`).
    ///     - token: a Stream Chat API token.
    public func set(user: User, token: Token) {
        self.user = user
        setup(token: token)
    }
    
    /// Setup the current user with a token provider (see `TokenProvider`).
    ///
    /// A token provider is a function in which you send a request to your own backend to get a Stream Chat API token.
    /// Then you send it to the client to complete the setup with a callback function from the token provider.
    ///
    /// Example:
    /// ```
    /// Client.shared.set(user: user) { callback in
    ///    if let url = URL(string: "https://my.backend.io/token?user_id=\(user.id)") {
    ///        let task = URLSession.shared.dataTask(with: url) { data, response, error in
    ///            if error == nil,
    ///                let json = try? JSONSerialization.jsonObject(with: data),
    ///                let token = json["token"] as? String {
    ///                callback(token)
    ///            } else {
    ///                // Handle the error.
    ///                print("Token request failed", error)
    ///            }
    ///        }
    ///
    ///        task.resume()
    ///    }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - user: the current user (see `User`).
    ///   - tokenProvider: a token provider.
    public func set(user: User, _ tokenProvider: TokenProvider) {
        self.user = user
        tokenProvider { self.setup(token: $0) }
    }
    
    private func setup(token: Token) {
        guard let user = user else {
            return
        }
        
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
