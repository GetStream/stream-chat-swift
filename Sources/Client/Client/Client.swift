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
    public typealias OnTokenChange = (Token?) -> Void
    /// A WebSocket connection callback type.
    public typealias OnConnect = (Connection) -> Void
    /// A WebSocket events callback type.
    public typealias OnEvent = (Event) -> Void
    
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
    
    public let baseURL: BaseURL
    let stayConnectedInBackground: Bool
    
    /// A database for an offline mode.
    public internal(set) var database: Database?
    
    public internal(set) var token: Token? {
        didSet { onTokenChange?(token) }
    }
    
    /// A token callback. This should only be used when you only use the Low-Level Client.
    public var onTokenChange: OnTokenChange?
    var tokenProvider: TokenProvider?
    public internal(set) var isExpiredTokenInProgress = false
    var waitingRequests = [WaitingRequest]()
    
    /// A web socket client.
    lazy var webSocket = WebSocket()
    
    public var connection: Connection { webSocket.connection }
    
    /// A WebSocket connection callback. This should only be used when you only use the Low-Level Client.
    public var onConnect: Client.OnConnect = { _ in } {
        didSet { webSocket.onConnect = setupWebSocketOnConnect }
    }
    
    /// A WebSocket events callback. This should only be used when you only use the Low-Level Client.
    public var onEvent: Client.OnEvent = { _ in } {
        didSet { webSocket.onEvent = setupWebSocketOnEvent }
    }
    
    lazy var urlSession = URLSession(configuration: .default)
    lazy var urlSessionTaskDelegate = ClientURLSessionTaskDelegate()
    let callbackQueue: DispatchQueue?
    private let uuid = UUID()
    
    /// A log manager.
    public let logger: ClientLogger?
    public let logOptions: ClientLogger.Options
    
    /// An observable user. This should only be used when you only use the Low-Level Client.
    public var onUserUpdate: OnUpdate<User>?
    
    private(set) lazy var userAtomic = Atomic<User> { [unowned self] newUser, _ in
        if let user = newUser {
            self.onUserUpdate?(user)
        }
    }
    
    /// Weak references to channels by cid.
    let channelsAtomic = Atomic<[ChannelId: [WeakRef<Channel>]]>([:])
    
    /// The current user.
    public internal(set) var user: User {
        get { return userAtomic.get() ?? .unknown }
        set { userAtomic.set(newValue) }
    }
    
    /// Check if API key and token are valid and the web socket is connected.
    public var isConnected: Bool { !apiKey.isEmpty && webSocket.isConnected }
    
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
        self.callbackQueue = callbackQueue ?? .global(qos: .userInitiated)
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
    /// - Parameter completion: Completion closure called once connection is established. Only called once.
    public func connect(completion: Client.OnConnect? = nil) {
        if let completion = completion {
            let oldOnConnect = onConnect
            
            onConnect = { [weak self] connection in
                if connection.isConnected {
                    oldOnConnect(connection)
                    completion(connection)
                    self?.onConnect = oldOnConnect
                } else {
                    oldOnConnect(connection)
                }
            }
        }
        
        webSocket.connect()
    }
    
    /// Disconnect from the web socket.
    public func disconnect() {
        logger?.log("Disconnecting...")
        webSocket.disconnect()
        Message.flaggedIds.removeAll()
        User.flaggedUsers.removeAll()
        isExpiredTokenInProgress = false
        
        performInCallbackQueue { [unowned self] in
            self.waitingRequests.forEach { $0.cancel() }
            self.waitingRequests = []
        }
    }
    
    /// Handle a connection with an application state.
    ///
    /// Application State:
    /// - `.active`
    ///   - `cancelBackgroundWork()`
    ///   - `connect()`
    /// - `.background` and `isConnected`
    ///   - `disconnectInBackground()`
    /// - Parameter appState: an application state.
    public func handleConnection(appState: UIApplication.State, isInternetAvailable: Bool) {
        guard isInternetAvailable else {
            disconnect()
            return
        }
        
        if appState == .active {
            webSocket.cancelBackgroundWork()
            connect()
        } else if appState == .background, webSocket.isConnected {
            webSocket.disconnectInBackground()
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
        
        /// Init a config for the shared `Client`.
        ///
        /// - Parameters:
        ///     - apiKey: a Stream Chat API key.
        ///     - baseURL: a base URL (see `BaseURL`).
        ///     - callbackQueue: a request callback queue, default nil (some background thread).
        ///     - stayConnectedInBackground: when the app will go to the background,
        ///                                  start a background task to stay connected for 5 min
        ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
        public init(apiKey: String,
                    baseURL: BaseURL = .usEast,
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
        
        /// Init a config for the shared `Client`.
        ///
        /// - Parameters:
        ///     - apiKey: a Stream Chat API key.
        ///     - baseURL: a base URL.
        ///     - callbackQueue: a request callback queue, default nil (some background thread).
        ///     - stayConnectedInBackground: when the app will go to the background,
        ///                                  start a background task to stay connected for 5 min
        ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
        public init(apiKey: String,
                    baseURL: URL,
                    callbackQueue: DispatchQueue? = nil,
                    stayConnectedInBackground: Bool = true,
                    database: Database? = nil,
                    logOptions: ClientLogger.Options = []) {
            self.init(apiKey: apiKey,
                      baseURL: .init(url: baseURL),
                      callbackQueue: callbackQueue,
                      stayConnectedInBackground: stayConnectedInBackground,
                      database: database,
                      logOptions: logOptions)
        }
        
        /// Init a config for the shared `Client`.
        ///
        /// - Parameters:
        ///     - apiKey: a Stream Chat API key.
        ///     - baseURL: a base URL string.
        ///     - callbackQueue: a request callback queue, default nil (some background thread).
        ///     - stayConnectedInBackground: when the app will go to the background,
        ///                                  start a background task to stay connected for 5 min
        ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
        public init?(apiKey: String,
                    baseURL: String,
                    callbackQueue: DispatchQueue? = nil,
                    stayConnectedInBackground: Bool = true,
                    database: Database? = nil,
                    logOptions: ClientLogger.Options = []) {
            guard let url = URL(string: baseURL) else { return nil }
            self.init(apiKey: apiKey,
                      baseURL: .init(url: url),
                      callbackQueue: callbackQueue,
                      stayConnectedInBackground: stayConnectedInBackground,
                      database: database,
                      logOptions: logOptions)
        }
    }
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }
}

// MARK: - Waiting Request

extension Client {
    final class WaitingRequest {
        typealias Request = () -> URLSessionTask
        
        var urlSessionTask: URLSessionTask?
        let request: Request
        
        init(request: @escaping Request) {
            self.request = request
        }
        
        func perform() {
            if urlSessionTask == nil {
                urlSessionTask = request()
            }
        }
        
        func cancel() {
            urlSessionTask?.cancel()
        }
    }
}
