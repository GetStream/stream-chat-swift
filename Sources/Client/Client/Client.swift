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
    /// Check if API key and token are valid and the web socket is connected.
    public var isConnected: Bool { !apiKey.isEmpty && webSocket.isConnected }
    var needsToRecoverConnection = false
    
    lazy var urlSession = URLSession(configuration: .default)
    lazy var urlSessionTaskDelegate = ClientURLSessionTaskDelegate() // swiftlint:disable:this weak_delegate
    let callbackQueue: DispatchQueue?
    
    private(set) lazy var eventsHandlingQueue = DispatchQueue(label: "io.getstream.Chat.clientEvents", qos: .userInteractive)
    let subscriptionBag = SubscriptionBag()
    
    // MARK: User Events
    
    /// The current user.
    public var user: User { userAtomic.get() ?? .unknown }
    
    var onUserUpdateObservers = [String: OnUpdate<User>]()
    
    private(set) lazy var userAtomic = Atomic<User>(callbackQueue: eventsHandlingQueue) { [unowned self] newUser, _ in
        if let user = newUser {
            self.onUserUpdateObservers.values.forEach({ $0(user) })
        }
    }
    
    // MARK: Unread Count Events
    
    /// Channels and messages unread counts.
    public var unreadCount: UnreadCount { unreadCountAtomic.get(default: .noUnread) }
    var onUnreadCountUpdateObservers = [String: OnUpdate<UnreadCount>]()
    
    private(set) lazy var unreadCountAtomic = Atomic<UnreadCount>(.noUnread, callbackQueue: eventsHandlingQueue) { [unowned self] in
        if let unreadCount = $0, unreadCount != $1 {
            self.onUnreadCountUpdateObservers.values.forEach({ $0(unreadCount) })
        }
    }
    
    /// Weak references to channels by cid.
    let watchingChannelsAtomic = Atomic<[ChannelId: [WeakRef<Channel>]]>([:])
    
    /// Init a network client.
    /// - Parameters:
    ///   - apiKey: a Stream Chat API key.
    ///   - baseURL: a base URL (see `BaseURL`).
    ///   - stayConnectedInBackground: when the app will go to the background,
    ///                                start a background task to stay connected for 5 min.
    ///   - database: a database manager (in development).
    ///   - callbackQueue: a request callback queue, default nil (some background thread).
    ///   - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.info`.
    init(apiKey: String = Client.config.apiKey,
         baseURL: BaseURL = Client.config.baseURL,
         stayConnectedInBackground: Bool = Client.config.stayConnectedInBackground,
         database: Database? = Client.config.database,
         callbackQueue: DispatchQueue? = Client.config.callbackQueue,
         logOptions: ClientLogger.Options = Client.config.logOptions) {
        if !apiKey.isEmpty, logOptions.isEnabled {
            ClientLogger.logger("💬", "", "Stream Chat v.\(Environment.version)")
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
        
        #if DEBUG
        checkLatestVersion()
        #endif
        checkAPIKey()
    }
    
    deinit {
        subscriptionBag.cancel()
    }
    
    private func checkAPIKey() {
        if apiKey.isEmpty {
            ClientLogger.logger("❌❌❌", "", "The Stream Chat Client didn't setup properly. "
                + "You are trying to use it before setting up the API Key. "
                + "Please use `Client.config = .init(apiKey:) to setup your api key. "
                + "You can debug this issue by putting a breakpoint in \(#file)\(#line)")
        }
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
        let watchingChannels: [WeakRef<Channel>]? = watchingChannelsAtomic.get(default: [:])[channel.cid]
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
