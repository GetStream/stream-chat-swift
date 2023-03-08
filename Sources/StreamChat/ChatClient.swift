//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The root object representing a Stream Chat.
///
/// Typically, an app contains just one instance of `ChatClient`. However, it's possible to have multiple instances if your use
/// case requires it (i.e. more than one window with different workspaces in a Slack-like app).
public class ChatClient {
    /// The `UserId` of the currently logged in user.
    public var currentUserId: UserId? {
        authenticationRepository.currentUserId
    }

    /// The token of the current user.
    var currentToken: Token? {
        authenticationRepository.currentToken
    }

    /// The current connection status of the client.
    ///
    /// To observe changes in the connection status, create an instance of `CurrentChatUserController`, and use it to receive
    /// callbacks when the connection status changes.
    ///
    public var connectionStatus: ConnectionStatus {
        connectionRepository.connectionStatus
    }

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
            ChannelReadUpdaterMiddleware(
                newProcessedMessageIds: { [weak center] in center?.newMessageIds ?? [] }
            ),
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

    private(set) lazy var connectionRepository = environment.connectionRepositoryBuilder(
        config.isClientInActiveMode,
        syncRepository,
        webSocketClient,
        apiClient,
        environment.timerType
    )

    private(set) lazy var authenticationRepository: AuthenticationRepository = {
        let repository = environment.authenticationRepositoryBuilder(
            apiClient,
            databaseContainer,
            connectionRepository,
            environment.tokenExpirationRetryStrategy,
            environment.timerType
        )
        repository.delegate = self
        return repository
    }()

    private(set) lazy var channelRepository = environment.channelRepositoryBuilder(
        databaseContainer,
        apiClient
    )

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

    /// A repository that handles all the executions needed to keep the Database in sync with remote.
    private(set) lazy var callRepository: CallRepository = {
        environment.callRepositoryBuilder(apiClient)
    }()

    /// The `APIClient` instance `Client` uses to communicate with Stream REST API.
    lazy var apiClient: APIClient = {
        var encoder = environment.requestEncoderBuilder(config.baseURL.restAPIBaseURL, config.apiKey)
        encoder.connectionDetailsProviderDelegate = self

        let decoder = environment.requestDecoderBuilder()

        let attachmentUploader = config.customAttachmentUploader ?? StreamAttachmentUploader(
            cdnClient: config.customCDNClient ?? StreamCDNClient(
                encoder: encoder,
                decoder: decoder,
                sessionConfiguration: urlSessionConfiguration
            )
        )

        let apiClient = environment.apiClientBuilder(
            urlSessionConfiguration,
            encoder,
            decoder,
            attachmentUploader,
            { [weak self] completion in
                guard let self = self else {
                    completion()
                    return
                }
                self.refreshToken(
                    completion: { _ in completion() }
                )
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

    /// Used as a bridge to communicate between the host app and the notification extension. Holds the state for the app lifecycle.
    private(set) lazy var extensionLifecycle = environment.extensionLifecycleBuilder(config.applicationGroupIdentifier)

    /// The environment object containing all dependencies of this `Client` instance.
    private let environment: Environment

    /// The default configuration of URLSession to be used for both the `APIClient` and `WebSocketClient`. It contains all
    /// required header auth parameters to make a successful request.
    private var urlSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = false
        configuration.httpAdditionalHeaders = sessionHeaders
        configuration.timeoutIntervalForRequest = config.timeoutIntervalForRequest
        return configuration
    }

    /// Stream-specific request headers.
    private let sessionHeaders: [String: String] = [
        "X-Stream-Client": SystemEnvironment.xStreamClientHeader
    ]

    /// Creates a new instance of `ChatClient`.
    /// - Parameter config: The config object for the `Client`. See `ChatClientConfig` for all configuration options.
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

        setupConnectionRecoveryHandler(with: environment)
    }

    deinit {
        completeConnectionIdWaiters(connectionId: nil)
        completeTokenWaiters(token: nil)
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
            extensionLifecycle,
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
        authenticationRepository.connectUser(
            userInfo: userInfo,
            tokenProvider: tokenProvider,
            completion: { completion?($0) }
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
    /// - Important: This method can only be used when `token` does not expire. If the token expires, the `connect` API with token provider has to be used.
    public func connectUser(
        userInfo: UserInfo,
        token: Token,
        completion: ((Error?) -> Void)? = nil
    ) {
        guard token.expiration == nil else {
            let error = ClientError.MissingTokenProvider()
            log.error(error.localizedDescription, subsystems: .authentication)
            completion?(error)
            return
        }

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
        authenticationRepository.connectGuestUser(userInfo: userInfo, completion: { completion?($0) })
    }

    /// Connects anonymous user
    /// - Parameter completion: The completion that will be called once the **first** user session for the given token is setup.
    public func connectAnonymousUser(completion: ((Error?) -> Void)? = nil) {
        authenticationRepository.connectUser(
            userInfo: nil,
            tokenProvider: { $0(.success(.anonymous)) },
            completion: { completion?($0) }
        )
    }

    /// Disconnects the chat client from the chat servers. No further updates from the servers
    /// are received.
    @available(*, deprecated, message: "Use the asynchronous version of `disconnect` for increased safety")
    public func disconnect() {
        disconnect {}
    }

    /// Disconnects the chat client from the chat servers. No further updates from the servers
    /// are received.
    public func disconnect(completion: @escaping () -> Void) {
        connectionRepository.disconnect(source: .userInitiated) {
            log.info("The `ChatClient` has been disconnected.", subsystems: .webSocket)
            completion()
        }
        authenticationRepository.clearTokenProvider()
    }

    /// Disconnects the chat client form the chat servers and removes all the local data related.
    @available(*, deprecated, message: "Use the asynchronous version of `logout` for increased safety")
    public func logout() {
        logout {}
    }

    /// Disconnects the chat client form the chat servers and removes all the local data related.
    public func logout(completion: @escaping () -> Void) {
        authenticationRepository.logOutUser()

        let group = DispatchGroup()
        group.enter()
        disconnect {
            group.leave()
        }

        group.enter()
        databaseContainer.removeAllData(force: true) { error in
            if let error = error {
                log.error("Logging out current user failed with error \(error)", subsystems: .all)
            } else {
                log.debug("Logging out current user successfully.", subsystems: .all)
            }
            group.leave()
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    func createBackgroundWorkers() {
        guard config.isClientInActiveMode else { return }

        // All production workers
        backgroundWorkers = [
            MessageSender(messageRepository: messageRepository, database: databaseContainer, apiClient: apiClient),
            NewUserQueryUpdater(database: databaseContainer, apiClient: apiClient),
            MessageEditor(messageRepository: messageRepository, database: databaseContainer, apiClient: apiClient),
            AttachmentQueueUploader(
                database: databaseContainer,
                apiClient: apiClient,
                attachmentPostProcessor: config.uploadedAttachmentPostProcessor
            )
        ]
    }

    func trackChannelController(_ channelController: ChatChannelController) {
        activeChannelControllers.add(channelController)
    }

    func trackChannelListController(_ channelListController: ChatChannelListController) {
        activeChannelListControllers.add(channelListController)
    }

    func completeConnectionIdWaiters(connectionId: String?) {
        connectionRepository.completeConnectionIdWaiters(connectionId: connectionId)
    }

    func completeTokenWaiters(token: Token?) {
        authenticationRepository.completeTokenWaiters(token: token)
    }

    /// Sets the user token to the client, this method is only needed to perform API calls
    /// without connecting as a user.
    /// You should only use this in special cases like a notification service or other background process
    public func setToken(token: Token) {
        authenticationRepository.setToken(token: token, completeTokenWaiters: true)
    }

    /// Starts the process to  refresh the token
    /// - Parameter completion: A block to be executed when the process is completed. Contains an error if something went wrong
    private func refreshToken(completion: ((Error?) -> Void)?) {
        authenticationRepository.refreshToken {
            completion?($0)
        }
    }
}

extension ChatClient: AuthenticationRepositoryDelegate {
    /// Clears state related to the current user to leave the client ready for another user
    /// Will clear:
    ///     - Background workers
    ///     - References to active controllers
    ///     - Database
    /// - Parameter completion: A block to be executed when the process is completed. Contains an error if something went wrong
    func clearCurrentUserData(completion: @escaping (Error?) -> Void) {
        createBackgroundWorkers()

        // Stop tracking active components
        activeChannelControllers.removeAllObjects()
        activeChannelListControllers.removeAllObjects()

        // Reset all existing local data.
        databaseContainer.removeAllData(force: true, completion: completion)
    }

    func didFinishSettingUpAuthenticationEnvironment(for state: EnvironmentState) {
        switch state {
        case .firstConnection, .newUser:
            createBackgroundWorkers()
        case .newToken:
            if backgroundWorkers.isEmpty {
                createBackgroundWorkers()
            }
        }
    }
}

extension ChatClient: ConnectionStateDelegate {
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        connectionRepository.handleConnectionUpdate(state: state, onInvalidToken: { [weak self] in
            self?.refreshToken(completion: nil)
        })
        connectionRecoveryHandler?.webSocketClient(client, didUpdateConnectionState: state)
    }
}

/// `Client` provides connection details for the `RequestEncoder`s it creates.
extension ChatClient: ConnectionDetailsProviderDelegate {
    func provideToken(timeout: TimeInterval = 10, completion: @escaping (Result<Token, Error>) -> Void) {
        authenticationRepository.provideToken(timeout: timeout, completion: completion)
    }

    func provideConnectionId(timeout: TimeInterval = 10, completion: @escaping (Result<ConnectionId, Error>) -> Void) {
        connectionRepository.provideConnectionId(timeout: timeout, completion: completion)
    }
}

extension ChatClient {
    /// An object containing all dependencies of `Client`
    struct Environment {
        var apiClientBuilder: (
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ requestDecoder: RequestDecoder,
            _ attachmentUploader: AttachmentUploader,
            _ tokenRefresher: @escaping (@escaping () -> Void) -> Void,
            _ queueOfflineRequest: @escaping QueueOfflineRequestBlock
        ) -> APIClient = {
            APIClient(
                sessionConfiguration: $0,
                requestEncoder: $1,
                requestDecoder: $2,
                attachmentUploader: $3,
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

        var extensionLifecycleBuilder = NotificationExtensionLifecycle.init

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

        var connectionRepositoryBuilder = ConnectionRepository.init

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

        var tokenExpirationRetryStrategy: RetryStrategy = DefaultRetryStrategy()

        var connectionRecoveryHandlerBuilder: (
            _ webSocketClient: WebSocketClient,
            _ eventNotificationCenter: EventNotificationCenter,
            _ syncRepository: SyncRepository,
            _ extensionLifecycle: NotificationExtensionLifecycle,
            _ backgroundTaskScheduler: BackgroundTaskScheduler?,
            _ internetConnection: InternetConnection,
            _ keepConnectionAliveInBackground: Bool
        ) -> ConnectionRecoveryHandler = {
            DefaultConnectionRecoveryHandler(
                webSocketClient: $0,
                eventNotificationCenter: $1,
                syncRepository: $2,
                extensionLifecycle: $3,
                backgroundTaskScheduler: $4,
                internetConnection: $5,
                reconnectionStrategy: DefaultRetryStrategy(),
                reconnectionTimerType: DefaultTimer.self,
                keepConnectionAliveInBackground: $6
            )
        }

        var authenticationRepositoryBuilder = AuthenticationRepository.init

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

        var callRepositoryBuilder: (
            _ apiClient: APIClient
        ) -> CallRepository = {
            CallRepository(apiClient: $0)
        }

        var channelRepositoryBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelRepository = {
            ChannelRepository(database: $0, apiClient: $1)
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
            https://getstream.io/chat/docs/sdk/ios/uikit/getting-started/
            \n
            API Error: \(String(describing: errorDescription))
            """
        }
    }

    public class MissingToken: ClientError {}
    class WaiterTimeout: ClientError {}

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

    public class MissingTokenProvider: ClientError {
        override public var localizedDescription: String {
            """
                Missing token refresh provider to get a new token
                When using expiring tokens you need to provide a way to refresh it by passing `tokenProvider` when \
                calling `ChatClient.connectUser()`.
            """
        }
    }
}
