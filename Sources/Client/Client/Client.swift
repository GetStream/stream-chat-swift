//
//  Client.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A network client.
public final class Client {
    /// A client completion block type.
    public typealias Completion<T: Decodable> = (Result<T, ClientError>) -> Void
    /// A client progress block type.
    public typealias Progress = (Float) -> Void
    /// A token block type.
    public typealias OnToken = (Token?) -> Void
    /// A WebSocket connection callback type.
    public typealias OnConnect = (Connection) -> Void
    /// A WebSocket events callback type.
    public typealias OnEvent = (Event) -> Void
    /// A user did update block type.
    public typealias UserDidUpdate = (User) -> Void
    
    /// A client config (see `Config`).
    public static var config = Config(apiKey: "")
    /// A shared client.
    public static let shared = Client()
    
    /// Stream API key.
    /// - Note: If you will change API key the Client will be disconnected and the current user will be logged out.
    ///         You have to setup another user after that.
    public var apiKey: String {
        didSet {
            checkAPIKey()
            disconnect()
        }
    }
    
    let baseURL: BaseURL
    let stayConnectedInBackground: Bool
    
    /// A database for an offline mode.
    public internal(set) var database: Database?
    
    var token: Token? {
        didSet { onToken?(token) }
    }
    
    /// A token callback.
    public var onToken: OnToken?
    var tokenProvider: TokenProvider?
    var isExpiredTokenInProgress = false
    /// A retry requester.
    public var retryRequester: ClientRetryRequester?
    
    /// A web socket client.
    public internal(set) lazy var webSocket = WebSocket()
    
    /// A WebSocket connection callback.
    var onConnect: Client.OnConnect = { _ in } {
        didSet {
            webSocket.onConnect = { [unowned self] connection in
                if case .disconnected(let error) = connection,
                    let clientError = error as? ClientError,
                    case .expiredToken = clientError,
                    self.touchTokenProvider() {
                    return
                }
                
                self.onConnect(connection)
            }
        }
    }
    
    /// A WebSocket events callback.
    var onEvent: Client.OnEvent = { _ in } {
        didSet {
            webSocket.onEvent = { [unowned self] event in
                if case let .healthCheck(_, user) = event {
                    self.user = user
                    return
                }
                
                self.onEvent(event)
            }
        }
    }
    
    lazy var urlSession = setupURLSession(token: "")
    lazy var urlSessionTaskDelegate = ClientURLSessionTaskDelegate()
    let callbackQueue: DispatchQueue?
    private let uuid = UUID()
    
    /// A log manager.
    public let logger: ClientLogger?
    let logOptions: ClientLogger.Options
    
    /// An observable user.
    public var userDidUpdate: UserDidUpdate?
    
    private let userAtomic = Atomic<User>()
    
    /// The current user.
    public internal(set) var user: User {
        get {
            return userAtomic.get() ?? .unknown
        }
        set {
            unreadCountAtomic.set((newValue.channelsUnreadCount, newValue.messagesUnreadCount))
            userAtomic.set(newValue)
            userDidUpdate?(newValue)
        }
    }
    
    /// Check if API key and token are valid and the web socket is connected.
    public var isConnected: Bool { !apiKey.isEmpty && webSocket.isConnected }
    
    var unreadCountAtomic = Atomic<UnreadCount>((0, 0))
    
    /// Init a network client.
    /// - Parameters:
    ///     - apiKey: a Stream Chat API key.
    ///     - baseURL: a base URL (see `BaseURL`).
    ///     - callbackQueue: a request callback queue, default nil (some background thread).
    ///     - stayConnectedInBackground: when the app will go to the background,
    ///                                  start a background task to stay connected for 5 min
    ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
    init(apiKey: String = Client.config.apiKey,
         baseURL: BaseURL = Client.config.baseURL,
         callbackQueue: DispatchQueue? = Client.config.callbackQueue,
         stayConnectedInBackground: Bool = Client.config.stayConnectedInBackground,
         database: Database? = Client.config.database,
         logOptions: ClientLogger.Options = Client.config.logOptions) {
        if !apiKey.isEmpty, logOptions.isEnabled {
            ClientLogger.logger("💬", "", "Stream Chat v.\(Client.version)")
            ClientLogger.logger("🔑", "", apiKey)
            ClientLogger.logger("🔗", "", baseURL.description)
            
            if let database = database {
                ClientLogger.logger("💽", "", "\(database.self)")
            }
        }
        
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.callbackQueue = callbackQueue
        self.stayConnectedInBackground = stayConnectedInBackground
        self.database = database
        self.logOptions = logOptions
        logger = logOptions.logger(icon: "🐴", for: [.requestsError, .requests, .requestsInfo])
        checkAPIKey()
    }
    
    private func checkAPIKey() {
        if apiKey.isEmpty {
            ClientLogger.logger("❌❌❌", "", "The Stream Chat Client didn't setup properly. "
                + "You are trying to use it before setup the API Key.")
            Thread.callStackSymbols.forEach { ClientLogger.logger("", "", $0) }
        }
    }
    /// Connect to websocket.
    /// - Note:
    ///   - Skip if the Internet is not available.
    ///   - Skip if it's already connected.
    ///   - Skip if it's reconnecting.
    public func connect() {
        webSocket.connect()
    }
    
    /// Disconnect from Stream and reset the current user.
    ///
    /// Resets and removes the user/token pair as well as relevant network connections.
    ///
    /// - Note: To restore the connection, use `Client.set(user:, token:)` to set a valid user/token pair.
    public func disconnect() {
        logger?.log("🧹 Reset Client User, Token, URLSession and WebSocket.")
        urlSession = setupURLSession(token: "")
        webSocket.disconnect()
        webSocket = WebSocket()
        Message.flaggedIds.removeAll()
        User.flaggedUsers.removeAll()
        token = nil
        user = .unknown
        
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .background {
                InternetConnection.shared.stopObserving()
            }
        }
    }
}

// MARK: - Config

extension Client {
    /// A config for a shread `Client`.
    public struct Config {
        /// A Stream Chat API key.
        public let apiKey: String
        /// A base URL (see `BaseURL`).
        public let baseURL: BaseURL
        /// A request callback queue, default nil (some background thread).
        public let callbackQueue: DispatchQueue?
        /// When the app will go to the background, start a background task to stay connected for 5 min.
        public let stayConnectedInBackground: Bool
        /// A local database.
        public let database: Database?
        /// Enable logs (see `ClientLogger.Options`), e.g. `.all`.
        public let logOptions: ClientLogger.Options
        
        /// Init a config for a shread `Client`.
        ///
        /// - Parameters:
        ///     - apiKey: a Stream Chat API key.
        ///     - baseURL: a base URL (see `BaseURL`).
        ///     - callbackQueue: a request callback queue, default nil (some background thread).
        ///     - stayConnectedInBackground: when the app will go to the background,
        ///                                  start a background task to stay connected for 5 min
        ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
        public init(apiKey: String,
                    baseURL: BaseURL = BaseURL(),
                    callbackQueue: DispatchQueue? = nil,
                    stayConnectedInBackground: Bool = true,
                    database: Database? = nil,
                    logOptions: ClientLogger.Options = []) {
            self.apiKey = apiKey
            self.baseURL = baseURL
            self.callbackQueue = callbackQueue
            self.stayConnectedInBackground = stayConnectedInBackground
            self.database = database
            self.logOptions = logOptions
        }
    }
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }
}

// MARK: - Retry Requester

/// A retry requester is a helper protocol for implementing retry request logic.
public protocol ClientRetryRequester {
    /// You need to reconnect with a new token and retry a request with a given endpoint and completion block.
    /// When you reconnection was success call `connectedWithNewToken()`.
    ///
    /// For example:
    /// ```
    /// final class RetryRequester: ClientRetryRequester {
    ///     func reconnectForExpiredToken<T: Decodable>(endpoint: Endpoint, _ completion: @escaping Client.Completion<T>) {
    ///         myReconnect {
    ///           self.connectedWithNewToken()
    ///           Client.shared.request(endpoint: endpoint, completion)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - endpoint: an endpoint.
    ///   - completion: a completion block with `<T: Decodable>`.
    func reconnectForExpiredToken<T: Decodable>(endpoint: Endpoint, _ completion: @escaping Client.Completion<T>)
}

public extension ClientRetryRequester {
    /// You have to call this function in success reconnect completion block to clear the state of `isExpiredTokenInProgress`.
    func connectedWithNewToken() {
        Client.shared.isExpiredTokenInProgress = false
    }
}
