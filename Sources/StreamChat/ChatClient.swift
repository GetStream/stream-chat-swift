//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The root object representing a Stream Chat.
///
/// Typically, an app contains just one instance of `ChatClient`. However, it's possible to have multiple instances if your use
/// case requires it (i.e. more than one window with different workspaces in a Slack-like app).
public class ChatClient {
    /// The `UserId` of the currently logged in user.
    @Atomic public internal(set) var currentUserId: UserId?

    /// The current connection status of the client.
    ///
    /// To observe changes in the connection status, create an instance of `CurrentChatUserController`, and use it to receive
    /// callbacks when the connection status changes.
    ///
    public internal(set) var connectionStatus: ConnectionStatus = .initialized

    /// The config object of the `ChatClient` instance.
    ///
    /// This value can't be mutated and can only be set when initializing a new `ChatClient` instance.
    ///
    public let config: ChatClientConfig
    
    /// A `Worker` represents a single atomic piece of functionality.
    ///
    /// `ChatClient` initializes a set of background workers that keep observing the current state of the system and perform
    /// work if needed (i.e. when a new message pending sent appears in the database, a worker tries to send it.)
    private(set) var backgroundWorkers: [Worker] = []
    
    /// Builder blocks used for creating `backgroundWorker`s when needed.
    private let workerBuilders: [WorkerBuilder]
    
    /// Builder blocks used for creating `backgroundWorker`s dealing with events when needed.
    private let eventWorkerBuilders: [EventWorkerBuilder]

    /// The notification center used to send and receive notifications about incoming events.
    private(set) lazy var eventNotificationCenter: EventNotificationCenter = {
        let center = environment.notificationCenterBuilder(databaseContainer)

        let middlewares: [EventMiddleware] = [
            EventDataProcessorMiddleware(),
            TypingStartCleanupMiddleware(
                excludedUserIds: { [weak self] in Set([self?.currentUserId].compactMap { $0 }) },
                emitEvent: { [weak center] in center?.process($0) }
            ),
            ChannelReadUpdaterMiddleware(),
            UserTypingStateUpdaterMiddleware(),
            ChannelTruncatedEventMiddleware(),
            MemberEventMiddleware(),
            UserChannelBanEventsMiddleware(),
            UserWatchingEventMiddleware(),
            ChannelVisibilityEventMiddleware(),
            EventDTOConverterMiddleware()
        ]

        center.add(middlewares: middlewares)

        return center
    }()
    
    /// The `APIClient` instance `Client` uses to communicate with Stream REST API.
    lazy var apiClient: APIClient = {
        var encoder = environment.requestEncoderBuilder(config.baseURL.restAPIBaseURL, config.apiKey)
        encoder.connectionDetailsProviderDelegate = self
        
        let decoder = environment.requestDecoderBuilder()
        
        let apiClient = environment.apiClientBuilder(
            urlSessionConfiguration,
            encoder,
            decoder,
            config.customCDNClient ?? StreamCDNClient(
                encoder: encoder,
                decoder: decoder,
                sessionConfiguration: urlSessionConfiguration
            ),
            { [weak self] error, completion in
                guard let self = self else {
                    completion()
                    return
                }
                self.refreshToken(error: error, completion: { _ in completion() })
            }
        )
        return apiClient
    }()
    
    /// The `WebSocketClient` instance `Client` uses to communicate with Stream WS servers.
    lazy var webSocketClient: WebSocketClient? = {
        var encoder = environment.requestEncoderBuilder(config.baseURL.webSocketBaseURL, config.apiKey)
        encoder.connectionDetailsProviderDelegate = self
                
        // Create a WebSocketClient.
        let webSocketClient = environment.webSocketClientBuilder?(
            urlSessionConfiguration,
            encoder,
            EventDecoder(),
            eventNotificationCenter,
            internetConnection
        )

        if let currentUserId = currentUserId {
            webSocketClient?.connectEndpoint = Endpoint<EmptyResponse>.webSocketConnect(
                userInfo: UserInfo(id: currentUserId)
            )
        }
        
        webSocketClient?.connectionStateDelegate = self
        
        return webSocketClient
    }()
    
    /// The `DatabaseContainer` instance `Client` uses to store and cache data.
    private(set) lazy var databaseContainer: DatabaseContainer = {
        do {
            if config.isLocalStorageEnabled {
                guard let storeURL = config.localStorageFolderURL else {
                    throw ClientError.MissingLocalStorageURL()
                }
                
                // Create the folder if needed
                try? FileManager.default.createDirectory(
                    at: storeURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                
                let dbFileURL = config.localStorageFolderURL!.appendingPathComponent(config.apiKey.apiKeyString)
                return try environment.databaseContainerBuilder(
                    .onDisk(databaseFileURL: dbFileURL),
                    config.shouldFlushLocalStorageOnStart,
                    config.isClientInActiveMode, // Only reset Ephemeral values in active mode
                    config.localCaching,
                    config.deletedMessagesVisibility,
                    config.shouldShowShadowedMessages
                )
            }
            
        } catch is ClientError.MissingLocalStorageURL {
            log.assertionFailure("The URL provided in ChatClientConfig can't be `nil`. Falling back to the in-memory option.")
            
        } catch {
            log.error("Failed to initalized the local storage with error: \(error). Falling back to the in-memory option.")
        }
        
        do {
            return try environment.databaseContainerBuilder(
                .inMemory,
                config.shouldFlushLocalStorageOnStart,
                config.isClientInActiveMode, // Only reset Ephemeral values in active mode
                config.localCaching,
                config.deletedMessagesVisibility,
                config.shouldShowShadowedMessages
            )
        } catch {
            fatalError("Failed to initialize the in-memory storage with error: \(error). This is a non-recoverable error.")
        }
    }()
    
    private(set) lazy var internetConnection = environment.internetConnection(eventNotificationCenter)
    private(set) lazy var clientUpdater = environment.clientUpdaterBuilder(self)
    private(set) var userConnectionProvider: UserConnectionProvider?
    
    /// Used for starting and ending background tasks. Hides platform specific logic.
    private lazy var backgroundTaskScheduler = environment.backgroundTaskSchedulerBuilder()
    
    /// The environment object containing all dependencies of this `Client` instance.
    private let environment: Environment
    
    /// Retry timing strategy for refreshing an expiried token
    private var tokenExpirationRetryStrategy: WebSocketClientReconnectionStrategy
    
    /// A timer that runs token refreshing job
    private var tokenRetryTimer: TimerControl?
    
    /// The default configuration of URLSession to be used for both the `APIClient` and `WebSocketClient`. It contains all
    /// required header auth parameters to make a successful request.
    private var urlSessionConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        config.httpAdditionalHeaders = sessionHeaders
        return config
    }
    
    /// Stream-specific request headers.
    private let sessionHeaders: [String: String] = [
        "X-Stream-Client": "stream-chat-\(sdkIdentifier)-client-v\(SystemEnvironment.version)"
    ]
    
    /// Identifies which SDK is being used.
    private static var sdkIdentifier: String {
        #if canImport(StreamChatSwiftUI)
        return "swiftui"
        #elseif canImport(StreamChatUI)
        return "uikit"
        #else
        return "swift"
        #endif
    }
    
    /// The current connection id
    @Atomic var connectionId: String?
    
    /// An array of requests waiting for the connection id
    @Atomic var connectionIdWaiters: [(String?) -> Void] = []

    /// An array of requests waiting for the token
    @Atomic var tokenWaiters: [(Token?) -> Void] = []
    
    /// The token of the current user. If the current user is anonymous, the token is `nil`.
    @Atomic var currentToken: Token?

    /// In case of token expiration this property is used to obtain a new token
    public var tokenProvider: TokenProvider?

    /// Sets the user token to the client, this method is only needed to perform API calls
    /// without connecting as a user.
    /// You should only use this in special cases like a notification service or other background process
    public func setToken(token: Token) {
        _currentToken.wrappedValue = token
        completeTokenWaiters(token: token)
    }

    /// Creates a new instance of `ChatClient`.
    /// - Parameters:
    ///   - config: The config object for the `Client`. See `ChatClientConfig` for all configuration options.
    ///   - tokenProvider: In case of token expiration this closure is used to obtain a new token
    public convenience init(
        config: ChatClientConfig,
        tokenProvider: TokenProvider? = nil
    ) {
        let workerBuilders: [WorkerBuilder]
        let eventWorkerBuilders: [EventWorkerBuilder]
        var environment = Environment()
        
        if config.isClientInActiveMode {
            // All production workers
            workerBuilders = [
                MessageSender.init,
                NewUserQueryUpdater.init,
                MessageEditor.init,
                AttachmentUploader.init
            ]
            
            // All production event workers
            eventWorkerBuilders = [
                {
                    ConnectionRecoveryUpdater(
                        database: $0,
                        eventNotificationCenter: $1,
                        apiClient: $2,
                        useSyncEndpoint: config.isLocalStorageEnabled
                    )
                }
            ]
        } else {
            workerBuilders = []
            eventWorkerBuilders = []
            environment.webSocketClientBuilder = nil
        }
        
        self.init(
            config: config,
            tokenProvider: tokenProvider,
            workerBuilders: workerBuilders,
            eventWorkerBuilders: eventWorkerBuilders,
            environment: environment
        )
    }
    
    /// Creates a new instance of Stream Chat `Client`.
    ///
    /// - Parameters:
    ///   - config: The config object for the `Client`.
    ///   - workerBuilders: An array of worker builders the `Client` instance will instantiate and run in the background
    ///   for the whole duration of its lifetime.
    ///   - environment: An object with all external dependencies the new `Client` instance should use.
    ///
    init(
        config: ChatClientConfig,
        tokenProvider: TokenProvider? = nil,
        workerBuilders: [WorkerBuilder],
        eventWorkerBuilders: [EventWorkerBuilder],
        environment: Environment,
        tokenExpirationRetryStrategy: WebSocketClientReconnectionStrategy = DefaultReconnectionStrategy()
    ) {
        self.config = config
        self.tokenProvider = tokenProvider
        self.environment = environment
        self.workerBuilders = workerBuilders
        self.eventWorkerBuilders = eventWorkerBuilders
        self.tokenExpirationRetryStrategy = tokenExpirationRetryStrategy

        currentUserId = fetchCurrentUserIdFromDatabase()
    }
    
    deinit {
        completeConnectionIdWaiters(connectionId: nil)
        completeTokenWaiters(token: nil)
    }
    
    /// Connects authorized user
    /// - Parameters:
    ///   - userInfo: User info that is passed to the `connect` endpoint for user creation
    ///   - token: Authorization token for the user.
    ///   - completion: The completion that will be called once the **first** user session for the given token is setup.
    public func connectUser(
        userInfo: UserInfo,
        token: Token,
        completion: ((Error?) -> Void)? = nil
    ) {
        setConnectionInfoAndConnect(
            userInfo: userInfo,
            userConnectionProvider: .static(token),
            completion: completion
        )
    }

    /// Connects a guest user
    /// - Parameters:
    ///   - userInfo: User info that is passed to the `connect` endpoint for user creation
    ///   - extraData: Extra data for user that is passed to the `connect` endpoint for user creation.
    ///   - completion: The completion that will be called once the **first** user session for the given token is setup.
    public func connectGuestUser(
        userInfo: UserInfo,
        completion: ((Error?) -> Void)? = nil
    ) {
        setConnectionInfoAndConnect(
            userInfo: userInfo,
            userConnectionProvider: .guest(
                userId: userInfo.id,
                name: userInfo.name,
                imageURL: userInfo.imageURL,
                extraData: userInfo.extraData
            ),
            completion: completion
        )
    }
    
    /// Connects anonymous user
    /// - Parameter completion: The completion that will be called once the **first** user session for the given token is setup.
    public func connectAnonymousUser(completion: ((Error?) -> Void)? = nil) {
        setConnectionInfoAndConnect(
            userInfo: nil,
            userConnectionProvider: .anonymous,
            completion: completion
        )
    }
    
    /// Disconnects the chat client from the chat servers. No further updates from the servers
    /// are received.
    public func disconnect() {
        clientUpdater.disconnect()
        userConnectionProvider = nil
        unsubscribeFromNotifications()
        apiClient.flushRequestsQueue()
    }

    func fetchCurrentUserIdFromDatabase() -> UserId? {
        var currentUserId: UserId?

        let context = databaseContainer.viewContext
        if Thread.isMainThread {
            currentUserId = context.currentUser?.user.id
        } else {
            context.performAndWait {
                currentUserId = context.currentUser?.user.id
            }
        }

        return currentUserId
    }
    
    func createBackgroundWorkers() {
        backgroundWorkers = workerBuilders.map { builder in
            builder(self.databaseContainer, self.apiClient)
        } + eventWorkerBuilders.map { builder in
            builder(self.databaseContainer, self.eventNotificationCenter, self.apiClient)
        }
    }

    func completeConnectionIdWaiters(connectionId: String?) {
        _connectionIdWaiters.mutate { waiters in
            waiters.forEach { $0(connectionId) }
            waiters.removeAll()
        }
    }

    func completeTokenWaiters(token: Token?) {
        _tokenWaiters.mutate { waiters in
            waiters.forEach { $0(token) }
            waiters.removeAll()
        }
    }
    
    private func setConnectionInfoAndConnect(
        userInfo: UserInfo?,
        userConnectionProvider: UserConnectionProvider,
        completion: ((Error?) -> Void)? = nil
    ) {
        self.userConnectionProvider = userConnectionProvider
        clientUpdater.reloadUserIfNeeded(
            userInfo: userInfo,
            userConnectionProvider: userConnectionProvider
        ) { [weak self] error in
            if error == nil {
                self?.subscribeOnNotifications()
            }
            completion?(error)
        }
    }
    
    private func subscribeOnNotifications() {
        backgroundTaskScheduler?.startListeningForAppStateUpdates(
            onEnteringBackground: { [weak self] in self?.handleAppDidEnterBackground() },
            onEnteringForeground: { [weak self] in self?.handleAppDidBecomeActive() }
        )
        
        eventNotificationCenter.addObserver(
            self,
            selector: #selector(didChangeInternetConnectionStatus(_:)),
            name: .internetConnectionStatusDidChange,
            object: nil
        )
    }
    
    private func unsubscribeFromNotifications() {
        backgroundTaskScheduler?.stopListeningForAppStateUpdates()
        eventNotificationCenter.removeObserver(
            self,
            name: .internetConnectionStatusDidChange,
            object: nil
        )
    }
    
    private func handleAppDidEnterBackground() {
        // We can't disconnect if we're not connected
        guard connectionStatus == .connected else { return }
        
        guard config.staysConnectedInBackground else {
            // We immediately disconnect
            clientUpdater.disconnect(source: .systemInitiated)
            return
        }
        guard let scheduler = backgroundTaskScheduler else { return }
        
        let succeed = scheduler.beginTask { [weak self] in
            self?.clientUpdater.disconnect(source: .systemInitiated)
        }
        
        if !succeed {
            // Can't initiate a background task, close the connection
            clientUpdater.disconnect(source: .systemInitiated)
        }
    }
    
    private func handleAppDidBecomeActive() {
        cancelBackgroundTaskIfNeeded()
        reconnectIfNeeded()
    }
    
    private func cancelBackgroundTaskIfNeeded() {
        backgroundTaskScheduler?.endTask()
    }
    
    private func reconnectIfNeeded() {
        guard userConnectionProvider != nil else {
            // The client has not been connected yet during this session
            return
        }
        
        guard connectionStatus != .connected && connectionStatus != .connecting else {
            // We are connected or connecting anyway
            return
        }
        
        guard internetConnection.status.isAvailable else {
            // We are offline. Once the connection comes back we will try to reconnect again
            return
        }
        
        clientUpdater.connect()
    }

    @objc private func didChangeInternetConnectionStatus(_ notification: Notification) {
        switch (connectionStatus, notification.internetConnectionStatus?.isAvailable) {
        case (.connected, false):
            clientUpdater.disconnect(source: .systemInitiated)
        case (.disconnected, true):
            reconnectIfNeeded()
        default:
            return
        }
    }
}

extension ChatClient {
    /// An object containing all dependencies of `Client`
    struct Environment {
        var apiClientBuilder: (
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ requestDecoder: RequestDecoder,
            _ CDNClient: CDNClient,
            _ tokenRefresher: @escaping (ClientError, @escaping () -> Void) -> Void
        ) -> APIClient = {
            APIClient(
                sessionConfiguration: $0,
                requestEncoder: $1,
                requestDecoder: $2,
                CDNClient: $3,
                tokenRefresher: $4
            )
        }
        
        var webSocketClientBuilder: ((
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ eventDecoder: AnyEventDecoder,
            _ notificationCenter: EventNotificationCenter,
            _ internetConnection: InternetConnection
        ) -> WebSocketClient)? = {
            WebSocketClient(
                sessionConfiguration: $0,
                requestEncoder: $1,
                eventDecoder: $2,
                eventNotificationCenter: $3,
                internetConnection: $4
            )
        }
        
        var databaseContainerBuilder: (
            _ kind: DatabaseContainer.Kind,
            _ shouldFlushOnStart: Bool,
            _ shouldResetEphemeralValuesOnStart: Bool,
            _ localCachingSettings: ChatClientConfig.LocalCaching?,
            _ deletedMessageVisibility: ChatClientConfig.DeletedMessageVisibility?,
            _ shouldShowShadowedMessages: Bool?
        ) throws -> DatabaseContainer = {
            try DatabaseContainer(
                kind: $0,
                shouldFlushOnStart: $1,
                shouldResetEphemeralValuesOnStart: $2,
                localCachingSettings: $3,
                deletedMessagesVisibility: $4,
                shouldShowShadowedMessages: $5
            )
        }
        
        var requestEncoderBuilder: (_ baseURL: URL, _ apiKey: APIKey) -> RequestEncoder = DefaultRequestEncoder.init
        var requestDecoderBuilder: () -> RequestDecoder = DefaultRequestDecoder.init
        
        var eventDecoderBuilder: () -> EventDecoder = EventDecoder.init
        
        var notificationCenterBuilder = EventNotificationCenter.init
        
        var internetConnection: (_ center: NotificationCenter) -> InternetConnection = {
            InternetConnection(notificationCenter: $0)
        }

        var clientUpdaterBuilder = ChatClientUpdater.init
        
        var backgroundTaskSchedulerBuilder: () -> BackgroundTaskScheduler? = {
            if Bundle.main.isAppExtension {
                // No background task scheduler exists for app extensions.
                return nil
            } else {
                #if os(iOS)
                return IOSBackgroundTaskScheduler()
                #else
                // No need for background schedulers on macOS, app continues running when inactive.
                return nil
                #endif
            }
        }
        
        var timerType: Timer.Type = DefaultTimer.self
    }
}

extension ClientError {
    public class MissingLocalStorageURL: ClientError {
        override public var localizedDescription: String { "The URL provided in ChatClientConfig is `nil`." }
    }
    
    public class ConnectionNotSuccessful: ClientError {
        override public var localizedDescription: String {
            "Connecting to the chat servers wasn't successful. Please check the console log for additional info."
        }
    }
    
    public class MissingToken: ClientError {}
    
    public class ClientIsNotInActiveMode: ClientError {
        override public var localizedDescription: String {
            """
                ChatClient is in connectionless mode, it cannot connect to websocket.
                Please check `ChatClientConfig.isClientInActiveMode` for additional info.
            """
        }
    }
    
    public class ConnectionWasNotInitiated: ClientError {
        override public var localizedDescription: String {
            """
                Before performing any other actions on chat client it's required to connect by using \
                one of the available `connect` methods e.g. `connectUser`.
            """
        }
    }
}

/// `APIClient` listens for `WebSocketClient` connection updates so it can forward the current connection id to
/// its `RequestEncoder`.
extension ChatClient: ConnectionStateDelegate {
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        connectionStatus = .init(webSocketConnectionState: state)
        
        // We should notify waiters if connectionId was obtained (i.e. state is .connected)
        // or for .disconnected state except for disconnect caused by an expired token
        let shouldNotifyConnectionIdWaiters: Bool
        let connectionId: String?
        switch state {
        case let .connected(connectionId: id):
            shouldNotifyConnectionIdWaiters = true
            connectionId = id
        case let .disconnected(error: error):
            if let error = error,
               error.isTokenExpiredError {
                refreshToken(error: error, completion: nil)
                shouldNotifyConnectionIdWaiters = false
            } else {
                shouldNotifyConnectionIdWaiters = true
            }
            connectionId = nil
        case .connecting,
             .disconnecting,
             .waitingForConnectionId,
             .waitingForReconnect:
            shouldNotifyConnectionIdWaiters = false
            connectionId = nil
        }
        
        updateConnectionId(
            connectionId: connectionId,
            shouldNotifyWaiters: shouldNotifyConnectionIdWaiters
        )
    }
    
    private func refreshToken(
        error: ClientError,
        completion: ((Error?) -> Void)?
    ) {
        guard let tokenProvider = tokenProvider else {
            return log.assertionFailure(
                "In case if token expiration is enabled on backend you need to provide a way to reobtain it via `tokenProvider` on ChatClient"
            )
        }
        
        guard let reconnectionDelay = tokenExpirationRetryStrategy.reconnectionDelay(
            forConnectionError: error
        ) else { return }
        tokenRetryTimer = environment
            .timerType
            .schedule(
                timeInterval: reconnectionDelay,
                queue: .main
            ) { [clientUpdater] in
                clientUpdater.reloadUserIfNeeded(
                    userConnectionProvider: .closure { _, completion in
                        tokenProvider() { result in
                            if case .success = result {
                                self.tokenExpirationRetryStrategy.successfullyConnected()
                            }
                            completion(result)
                        }
                    },
                    completion: completion
                )
            }
    }
    
    /// Update connectionId and notify waiters if needed
    /// - Parameters:
    ///   - connectionId: new connectionId (if present)
    ///   - shouldFailWaiters: Whether it's necessary to notify waiters or not
    private func updateConnectionId(
        connectionId: String?,
        shouldNotifyWaiters: Bool
    ) {
        var connectionIdWaiters: [(String?) -> Void]!
        _connectionId.mutate { mutableConnectionId in
            mutableConnectionId = connectionId
            _connectionIdWaiters.mutate { _connectionIdWaiters in
                connectionIdWaiters = _connectionIdWaiters
                if shouldNotifyWaiters {
                    _connectionIdWaiters.removeAll()
                }
            }
        }
        if shouldNotifyWaiters {
            connectionIdWaiters.forEach { $0(connectionId) }
        }
    }
}

private extension ClientError {
    var isTokenExpiredError: Bool {
        if let error = underlyingError as? ErrorPayload,
           ErrorPayload.tokenInvadlidErrorCodes ~= error.code {
            return true
        }
        return false
    }
}

/// `Client` provides connection details for the `RequestEncoder`s it creates.
extension ChatClient: ConnectionDetailsProviderDelegate {
    func provideToken(completion: @escaping (_ token: Token?) -> Void) {
        if let token = currentToken {
            completion(token)
        } else {
            _tokenWaiters.mutate {
                $0.append(completion)
            }
        }
    }
    
    func provideConnectionId(completion: @escaping (String?) -> Void) {
        if let connectionId = connectionId {
            completion(connectionId)
        } else if !config.isClientInActiveMode {
            // We're in passive mode
            // We will never have connectionId
            completion(nil)
        } else {
            _connectionIdWaiters.mutate {
                $0.append(completion)
            }
        }
    }
}
