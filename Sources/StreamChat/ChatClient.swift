//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    /// Keeps a weak reference to the active channel list controllers to ensure a proper recovery when coming back online
    private(set) var activeChannelListControllers = ThreadSafeWeakCollection<ChatChannelListController>()
    private(set) var activeChannelControllers = ThreadSafeWeakCollection<ChatChannelController>()

    /// Background worker that takes care about client connection recovery when the Internet comes back OR app transitions from background to foreground.
    private(set) var connectionRecoveryHandler: ConnectionRecoveryHandler?

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

    // MARK: Repositories

    private(set) lazy var messageRepository = environment.messageRepositoryBuilder(
        databaseContainer,
        apiClient
    )
    
    private(set) lazy var offlineRequestsRepository = environment.offlineRequestsRepositoryBuilder(
        messageRepository,
        databaseContainer,
        apiClient
    )

    /// A repository that handles all the executions needed to keep the Database in sync with remote.
    private(set) lazy var syncRepository: SyncRepository = {
        let channelRepository = ChannelListUpdater(database: databaseContainer, apiClient: apiClient)
        return environment.syncRepositoryBuilder(
            config,
            activeChannelControllers,
            activeChannelListControllers,
            offlineRequestsRepository,
            eventNotificationCenter,
            databaseContainer,
            apiClient
        )
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
            { [weak self] serverError, completion in
                guard let self = self else {
                    completion(ClientError.ClientHasBeenDeallocated())
                    return
                }
                
                self.clientUpdater.handleExpiredTokenError(serverError, completion: completion)
            },
            { [weak self] endpoint in
                self?.syncRepository.queueOfflineRequest(endpoint: endpoint)
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
            eventNotificationCenter
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
                try FileManager.default.createDirectory(
                    at: storeURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                
                let dbFileURL = storeURL.appendingPathComponent(config.apiKey.apiKeyString)
                return environment.databaseContainerBuilder(
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
            log.error("Failed to initialize the local storage with error: \(error). Falling back to the in-memory option.")
        }
        
        return environment.databaseContainerBuilder(
            .inMemory,
            config.shouldFlushLocalStorageOnStart,
            config.isClientInActiveMode, // Only reset Ephemeral values in active mode
            config.localCaching,
            config.deletedMessagesVisibility,
            config.shouldShowShadowedMessages
        )
    }()
    
    private(set) lazy var tokenHandler = environment.tokenHandlerBuilder(
        currentUserId.map(UserConnectionProvider.notInitiated) ?? .noCurrentUser
    )
    
    private(set) lazy var clientUpdater = environment.clientUpdaterBuilder(self)
    
    /// The environment object containing all dependencies of this `Client` instance.
    private let environment: Environment
    
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
        "X-Stream-Client": SystemEnvironment.xStreamClientHeader
    ]
    
    /// The current connection id
    @Atomic var connectionId: String?
    
    /// An array of requests waiting for the connection id
    @Atomic private(set) var connectionIdWaiters: [WaiterToken: ConnectionIdWaiter] = [:]
    
    /// The token of the current user. If the current user is anonymous, the token is `nil`.
    var currentToken: Token? { tokenHandler.currentToken }
    
    /// Sets the user token to the client, this method is only needed to perform API calls
    /// without connecting as a user.
    /// You should only use this in special cases like a notification service or other background process
    public func setToken(token: Token, completion: ((Error?) -> Void)? = nil) {
        tokenHandler.set(token: token, completion: completion)
    }

    /// Creates a new instance of `ChatClient`.
    /// - Parameters:
    ///   - config: The config object for the `Client`. See `ChatClientConfig` for all configuration options.
    ///   - tokenProvider: In case of token expiration this closure is used to obtain a new token
    public convenience init(
        config: ChatClientConfig
    ) {
        var environment = Environment()
        
        if !config.isClientInActiveMode {
            environment.webSocketClientBuilder = nil
        }
        
        self.init(
            config: config,
            environment: environment
        )
    }
    
    /// Creates a new instance of Stream Chat `Client`.
    ///
    /// - Parameters:
    ///   - config: The config object for the `Client`.
    ///   - environment: An object with all external dependencies the new `Client` instance should use.
    ///
    init(
        config: ChatClientConfig,
        environment: Environment
    ) {
        self.config = config
        self.environment = environment

        currentUserId = fetchCurrentUserIdFromDatabase()
        setupConnectionRecoveryHandler(with: environment)
    }
    
    deinit {
        let error = ClientError.ClientHasBeenDeallocated()
        completeConnectionIdWaiters(result: .failure(error))
    }

    func setupConnectionRecoveryHandler(with environment: Environment) {
        guard let webSocketClient = webSocketClient else {
            return
        }

        connectionRecoveryHandler = nil
        connectionRecoveryHandler = environment.connectionRecoveryHandlerBuilder(
            webSocketClient,
            eventNotificationCenter,
            syncRepository,
            environment.backgroundTaskSchedulerBuilder(),
            environment.internetConnection(eventNotificationCenter, environment.internetMonitor),
            config.staysConnectedInBackground
        )
    }
    
    /// Connects the client with the given user.
    ///
    /// - Parameters:
    ///   - userInfo: The user info passed to `connect` endpoint.
    ///   - tokenProvider: The closure used to retreive a token. Token provider will be used to establish the initial connection and also to obtain the new token when the previous one expires.
    ///   - completion: The completion that will be called once the **first** user session for the given token is setup.
    ///
    /// - Note: Connect endpoint uses an upsert mechanism. If the user does not exist, it will be created with the given `userInfo`. If user already exists, it will get updated with non-nil fields from the `userInfo`.
    public func connectUser(
        userInfo: UserInfo,
        tokenProvider: @escaping TokenProvider,
        completion: ((Error?) -> Void)? = nil
    ) {
        setConnectionInfoAndConnect(
            userInfo: userInfo,
            userConnectionProvider: .initiated(userId: userInfo.id, tokenProvider: tokenProvider),
            completion: completion
        )
    }
    
    /// Connects the client with the given user.
    ///
    /// - Parameters:
    ///   - userInfo: User info that is passed to the `connect` endpoint for user creation
    ///   - token: Authorization token for the user.
    ///   - completion: The completion that will be called once the **first** user session for the given token is setup.
    ///
    /// - Note: Connect endpoint uses an upsert mechanism. If the user does not exist, it will be created with the given `userInfo`. If user already exists, it will get updated with non-nil fields from the `userInfo`.
    ///
    /// - Important: This method can only be used when `token` does not expire. If the token expores, the `connect` API with token provider has to be used.
    public func connectUser(
        userInfo: UserInfo,
        token: Token,
        completion: ((Error?) -> Void)? = nil
    ) {
        connectUser(
            userInfo: userInfo,
            tokenProvider: { $0(.success(token)) },
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
                client: self,
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
        let token = Token.anonymous
        setConnectionInfoAndConnect(
            userInfo: .init(id: token.userId),
            userConnectionProvider: .static(token),
            completion: completion
        )
    }
    
    /// Disconnects the chat client from the chat servers. No further updates from the servers
    /// are received.
    public func disconnect() {
        clientUpdater.disconnect(source: .userInitiated) {
            log.info("The `ChatClient` has been disconnected.", subsystems: .webSocket)
        }
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
        guard config.isClientInActiveMode else { return }

        // All production workers
        backgroundWorkers = [
            MessageSender(messageRepository: messageRepository, database: databaseContainer, apiClient: apiClient),
            NewUserQueryUpdater(database: databaseContainer, apiClient: apiClient),
            MessageEditor(messageRepository: messageRepository, database: databaseContainer, apiClient: apiClient),
            AttachmentUploader(database: databaseContainer, apiClient: apiClient)
        ]
    }

    func trackChannelController(_ channelController: ChatChannelController) {
        activeChannelControllers.add(channelController)
    }

    func trackChannelListController(_ channelListController: ChatChannelListController) {
        activeChannelListControllers.add(channelListController)
    }
    
    func completeConnectionIdWaiters(result: Result<ConnectionId, Error>) {
        var waiters: [ConnectionIdWaiter] = []
        
        _connectionIdWaiters.mutate {
            waiters = Array($0.values)
            $0.removeAll()
        }
        
        waiters.forEach { $0(result) }
    }
    
    private func setConnectionInfoAndConnect(
        userInfo: UserInfo,
        userConnectionProvider: UserConnectionProvider,
        completion: ((Error?) -> Void)? = nil
    ) {
        tokenHandler.connectionProvider = userConnectionProvider
        
        clientUpdater.reloadUserIfNeeded(
            userInfo: userInfo,
            completion: completion
        )
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
            _ tokenRefresher: @escaping RefreshTokenBlock,
            _ queueOfflineRequest: @escaping QueueOfflineRequestBlock
        ) -> APIClient = {
            APIClient(
                sessionConfiguration: $0,
                requestEncoder: $1,
                requestDecoder: $2,
                CDNClient: $3,
                tokenRefresher: $4,
                queueOfflineRequest: $5
            )
        }
        
        var webSocketClientBuilder: ((
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ eventDecoder: AnyEventDecoder,
            _ notificationCenter: EventNotificationCenter
        ) -> WebSocketClient)? = {
            WebSocketClient(
                sessionConfiguration: $0,
                requestEncoder: $1,
                eventDecoder: $2,
                eventNotificationCenter: $3
            )
        }
        
        var databaseContainerBuilder: (
            _ kind: DatabaseContainer.Kind,
            _ shouldFlushOnStart: Bool,
            _ shouldResetEphemeralValuesOnStart: Bool,
            _ localCachingSettings: ChatClientConfig.LocalCaching?,
            _ deletedMessageVisibility: ChatClientConfig.DeletedMessageVisibility?,
            _ shouldShowShadowedMessages: Bool?
        ) -> DatabaseContainer = {
            DatabaseContainer(
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
        
        var internetConnection: (_ center: NotificationCenter, _ monitor: InternetConnectionMonitor) -> InternetConnection = {
            InternetConnection(notificationCenter: $0, monitor: $1)
        }

        var internetMonitor: InternetConnectionMonitor {
            if let monitor = monitor {
                return monitor
            } else if #available(iOS 12, *) {
                return InternetConnection.Monitor()
            } else {
                return InternetConnection.LegacyMonitor()
            }
        }

        var monitor: InternetConnectionMonitor?

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
        
        var connectionRecoveryHandlerBuilder: (
            _ webSocketClient: WebSocketClient,
            _ eventNotificationCenter: EventNotificationCenter,
            _ syncRepository: SyncRepository,
            _ backgroundTaskScheduler: BackgroundTaskScheduler?,
            _ internetConnection: InternetConnection,
            _ keepConnectionAliveInBackground: Bool
        ) -> ConnectionRecoveryHandler = {
            DefaultConnectionRecoveryHandler(
                webSocketClient: $0,
                eventNotificationCenter: $1,
                syncRepository: $2,
                backgroundTaskScheduler: $3,
                internetConnection: $4,
                reconnectionStrategy: DefaultRetryStrategy(),
                reconnectionTimerType: DefaultTimer.self,
                keepConnectionAliveInBackground: $5
            )
        }
        
        var syncRepositoryBuilder: (
            _ config: ChatClientConfig,
            _ activeChannelControllers: ThreadSafeWeakCollection<ChatChannelController>,
            _ activeChannelListControllers: ThreadSafeWeakCollection<ChatChannelListController>,
            _ offlineRequestsRepository: OfflineRequestsRepository,
            _ eventNotificationCenter: EventNotificationCenter,
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> SyncRepository = {
            SyncRepository(
                config: $0,
                activeChannelControllers: $1,
                activeChannelListControllers: $2,
                offlineRequestsRepository: $3,
                eventNotificationCenter: $4,
                database: $5,
                apiClient: $6
            )
        }
        
        var messageRepositoryBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> MessageRepository = {
            MessageRepository(database: $0, apiClient: $1)
        }
        
        var offlineRequestsRepositoryBuilder: (
            _ messageRepository: MessageRepository,
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> OfflineRequestsRepository = {
            OfflineRequestsRepository(
                messageRepository: $0,
                database: $1,
                apiClient: $2
            )
        }
        
        var tokenHandlerBuilder: (
            _ connectionProvider: UserConnectionProvider
        ) -> TokenHandler = {
            DefaultTokenHandler(
                connectionProvider: $0,
                retryStrategy: DefaultRetryStrategy(),
                retryTimeoutInterval: 10,
                maximumTokenRefreshAttempts: 10,
                timerType: DefaultTimer.self
            )
        }
    }
}

extension ClientError {
    public class MissingLocalStorageURL: ClientError {
        override public var localizedDescription: String { "The URL provided in ChatClientConfig is `nil`." }
    }
    
    public class ConnectionNotSuccessful: ClientError {
        override public var localizedDescription: String {
            """
            Connection to the API has failed.
            You can read more about making a successful connection in our docs:
            https://getstream.io/chat/docs/sdk/ios/basics/getting-started/#your-first-app-with-stream-chat
            \n
            API Error: \(String(describing: errorDescription))
            """
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
    
    public class ClientHasBeenDeallocated: ClientError {
        override public var localizedDescription: String {
            "ChatClient has been deallocated, make sure to keep at least one strong reference to it."
        }
    }
    
    public class ClientHasBeenDisconnected: ClientError {
        override public var localizedDescription: String {
            "ChatClient has been disconnected."
        }
    }
}

/// `APIClient` listens for `WebSocketClient` connection updates so it can forward the current connection id to
/// its `RequestEncoder`.
extension ChatClient: ConnectionStateDelegate {
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        connectionStatus = .init(webSocketConnectionState: state)
        
        connectionRecoveryHandler?.webSocketClient(client, didUpdateConnectionState: state)
        
        switch state {
        case let .connected(connectionId: id):
            connectionId = id
            
            completeConnectionIdWaiters(result: .success(id))
            
        case let .disconnected(source):
            connectionId = nil
            
            if let error = source.serverError, error.isInvalidTokenError {
                clientUpdater.handleExpiredTokenError(error)
            } else {
                let error = source.serverError ?? ClientError.ConnectionNotSuccessful()
                completeConnectionIdWaiters(result: .failure(error))
            }
        case .initialized,
             .connecting,
             .disconnecting,
             .waitingForConnectionId:
            connectionId = nil
        }
    }
}

/// `Client` provides connection details for the `RequestEncoder`s it creates.
extension ChatClient: ConnectionDetailsProviderDelegate {
    @discardableResult
    func provideToken(completion: @escaping TokenWaiter) -> WaiterToken {
        tokenHandler.add(tokenWaiter: completion)
    }

    @discardableResult
    func provideConnectionId(completion: @escaping ConnectionIdWaiter) -> WaiterToken {
        let waiterToken = String.newUniqueId
        if let connectionId = connectionId {
            completion(.success(connectionId))
        } else if !config.isClientInActiveMode {
            // We're in passive mode
            // We will never have connectionId
            completion(.failure(ClientError.ClientIsNotInActiveMode()))
        } else {
            _connectionIdWaiters.mutate {
                $0[waiterToken] = completion
            }
        }
        return waiterToken
    }

    func invalidateTokenWaiter(_ token: WaiterToken) {
        tokenHandler.removeTokenWaiter(token)
    }

    func invalidateConnectionIdWaiter(_ waiter: WaiterToken) {
        _connectionIdWaiters.mutate {
            $0[waiter] = nil
        }
    }
}
