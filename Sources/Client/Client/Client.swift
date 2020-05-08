//
//  Client.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A network client.
public final class Client: Uploader {
    /// A client completion block type.
    public typealias Completion<T: Decodable> = (Result<T, ClientError>) -> Void
    /// A client progress block type.
    public typealias Progress = (Float) -> Void
    /// A WebSocket events callback type.
    public typealias OnEvent = (Event) -> Void
    
    /// A client config (see `Config`).
    @available(*, deprecated, message: """
    Configuring the shared Client using the static `Client.config` variable has been deprecated. Please create an instance
    of the `Client.Config` struct and call `Client.configureShared(_:)` to set up the shared instance of Client.
    """)
    public static var config: Config = .init(apiKey: "_deprecated") {
        didSet {
            guard backingSharedClient == nil else {
                ClientLogger.logAssertionFailure(
                    "`Client.shared` instance was already used. It's not possible to change its configuration."
                )
                return
            }

            configForSharedClient = config
        }
    }

    /// The configuration object used for creating `Client.shared`.
    private static var configForSharedClient: Config?

    /// The shared client.
    public static var shared: Client {
        if let client = backingSharedClient {
            // Return the existing instance
            return client
        }

        ClientLogger.logAssert(
            configForSharedClient != nil,
            "The shared instance of the Stream chat client wasn't configured. " +
            "Create an instance of the `Client.Config` struct and call `Client.configureShared(_:)` to set it up."
        )

        backingSharedClient = Client(config: configForSharedClient ?? .init(apiKey: "__API_KEY_NOT_CONFIGURED__"))
        return backingSharedClient!
    }

    /// A backing variable for `Client.shared`. We need this to have finer control over its creation.
    private static var backingSharedClient: Client?

    /// Configures the shared instance of `Client`.
    ///
    /// - Parameter configuration: The configuration object with details of how the shared instance should be set up.
    public static func configureShared(_ config: Config) {
        guard backingSharedClient == nil else {
            ClientLogger.logAssertionFailure(
                "`Client.shared` instance was already used. It's not possible to change its configuration."
            )
            return
        }
        configForSharedClient = config
    }
    
    /// Stream API key.
    /// - Note: If you will change API key the Client will be disconnected and the current user will be logged out.
    ///         You have to setup another user after that.
    public var apiKey: String {
        didSet {
            ClientLogger.logAssert(!apiKey.isEmpty, "Empty string is not a valid apiKey.")
            disconnect()
        }
    }
    
    /// A base URL.
    public let baseURL: BaseURL
    let stayConnectedInBackground: Bool
    /// A database for an offline mode.
    public internal(set) var database: Database?
    
    /// A log manager.
    public let logger: ClientLogger?
    public let logOptions: ClientLogger.Options
    
    // MARK: Token
    
    var token: Token?
    var tokenProvider: TokenProvider?
    /// Checks if the expired Token is updating.
    public internal(set) var isExpiredTokenInProgress = false // FIXME: Should be internal.
    var waitingRequests = [WaitingRequest]()
    
    // MARK: WebSocket
    
    /// A web socket client.
    lazy var webSocket = WebSocket()
    /// The current connection state.
    public var connectionState: ConnectionState { webSocket.connectionState }
    /// Check if API key and token are valid and the web socket is connected.
    public var isConnected: Bool { !apiKey.isEmpty && webSocket.isConnected }
    var needsToRecoverConnection = false

    let defaultURLSessionConfiguration: URLSessionConfiguration
    lazy var urlSession = URLSession(configuration: self.defaultURLSessionConfiguration)

    lazy var urlSessionTaskDelegate = ClientURLSessionTaskDelegate() // swiftlint:disable:this weak_delegate
    let callbackQueue: DispatchQueue?
    
    private(set) lazy var eventsHandlingQueue = DispatchQueue(label: "io.getstream.Chat.clientEvents", qos: .userInteractive)
    let subscriptionBag = SubscriptionBag()
    
    // MARK: User Events
    
    /// The current user.
    public var user: User { userAtomic.get() }
    
    var onUserUpdateObservers = [String: OnUpdate<User>]()
    
    private(set) lazy var userAtomic = Atomic<User>(.unknown, callbackQueue: eventsHandlingQueue) { [unowned self] newUser, _ in
        self.onUserUpdateObservers.values.forEach({ $0(newUser) })
    }
    
    // MARK: Unread Count Events
    
    /// Channels and messages unread counts.
    public var unreadCount: UnreadCount { unreadCountAtomic.get() }
    var onUnreadCountUpdateObservers = [String: OnUpdate<UnreadCount>]()
    
    private(set) lazy var unreadCountAtomic =
        Atomic<UnreadCount>(.noUnread, callbackQueue: eventsHandlingQueue) { [unowned self] newUnreadCount, oldUnreadCount in
            if newUnreadCount != oldUnreadCount {
                self.onUnreadCountUpdateObservers.values.forEach({ $0(newUnreadCount) })
            }
        }
    
    /// Weak references to channels by cid.
    let watchingChannelsAtomic = Atomic<[ChannelId: [WeakRef<Channel>]]>([:])
    
    /// Creates a new instance of the network client.
    ///
    /// - Parameters:
    ///   - config: The configuration object with details of how the new instance should be set up.
    ///   - defaultURLSessionConfiguration: The base URLSession configuration `Client` uses for its
    ///     URL sessions. `Client` is allowed to override the configuration with its own settings.
    init(config: Client.Config, defaultURLSessionConfiguration: URLSessionConfiguration = .default) {
        self.apiKey = config.apiKey
        self.baseURL = config.baseURL
        self.callbackQueue = config.callbackQueue ?? .global(qos: .userInitiated)
        self.stayConnectedInBackground = config.stayConnectedInBackground
        self.database = config.database
        self.logOptions = config.logOptions
        logger = logOptions.logger(icon: "🐴", for: [.requestsError, .requests, .requestsInfo])

        self.defaultURLSessionConfiguration = defaultURLSessionConfiguration

        if !apiKey.isEmpty, logOptions.isEnabled {
            ClientLogger.logger("💬", "", "Stream Chat v.\(Environment.version)")
            ClientLogger.logger("🔑", "", apiKey)
            ClientLogger.logger("🔗", "", baseURL.description)
            
            if let database = database {
                ClientLogger.logger("💽", "", "\(database.self)")
            }
        }

        #if DEBUG
        checkLatestVersion()
        #endif
    }
    
    deinit {
        subscriptionBag.cancel()
    }
    
    /// Handle a connection with an application state.
    /// - Note:
    ///   - Skip if the Internet is not available.
    ///   - Skip if it's already connected.
    ///   - Skip if it's reconnecting.
    ///
    /// Application State:
    /// - `.active`
    ///   - `cancelBackgroundWork()`
    ///   - `connect()`
    /// - `.background` and `isConnected`
    ///   - `disconnectInBackground()`
    /// - Parameter appState: an application state.
    func connect(appState: UIApplication.State = UIApplication.shared.applicationState,
                 internetConnectionState: InternetConnection.State = InternetConnection.shared.state) {
        guard internetConnectionState == .available else {
            if internetConnectionState == .unavailable {
                reset()
            }
            
            return
        }
        
        if appState == .active {
            webSocket.connect()
        } else if appState == .background, webSocket.isConnected {
            webSocket.disconnectInBackground()
        }
    }
    
    /// Disconnect the web socket.
    public func disconnect() {
        logger?.log("Disconnecting deliberately...")
        reset()
        Application.shared.onStateChanged = nil
        InternetConnection.shared.stopNotifier()
    }
    
    /// Disconnect the websocket and reset states.
    func reset() {
        if webSocket.connectionId != nil {
            needsToRecoverConnection = true
        }
        
        webSocket.disconnect(reason: "Resetting connection")
        Message.flaggedIds.removeAll()
        User.flaggedUsers.removeAll()
        isExpiredTokenInProgress = false
        
        performInCallbackQueue { [unowned self] in
            self.waitingRequests.forEach { $0.cancel() }
            self.waitingRequests = []
        }
    }
    
    /// Checks if the given channel is watching.
    /// - Parameter channel: a channel.
    /// - Returns: returns true if the client is watching for the channel.
    public func isWatching(channel: Channel) -> Bool {
        let watchingChannels: [WeakRef<Channel>]? = watchingChannelsAtomic.get()[channel.cid]
        return watchingChannels?.first { $0.value === channel } != nil
    }
}

// MARK: - Waiting Request

extension Client {
    final class WaitingRequest: Cancellable {
        typealias Request = () -> Cancellable // swiftlint:disable:this nesting
        
        private var subscription: Cancellable?
        private let request: Request
        
        init(request: @escaping Request) {
            self.request = request
        }
        
        func perform() {
            if subscription == nil {
                subscription = request()
            }
        }
        
        func cancel() {
            subscription?.cancel()
        }
    }
}
