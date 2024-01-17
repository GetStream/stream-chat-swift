//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    /// To observe changes in the connection status, create an instance of `ChatConnectionController`, and use it to receive
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
    private(set) var eventNotificationCenter: EventNotificationCenter

    /// The registry that contains all the attachment payloads associated with their attachment types.
    /// For the meantime this is a static property to avoid breaking changes. On v5, this can be changed.
    private(set) static var attachmentTypesRegistry: [AttachmentType: AttachmentPayload.Type] = [
        .image: ImageAttachmentPayload.self,
        .video: VideoAttachmentPayload.self,
        .audio: AudioAttachmentPayload.self,
        .file: FileAttachmentPayload.self,
        .voiceRecording: VoiceRecordingAttachmentPayload.self
    ]

    let connectionRepository: ConnectionRepository

    let authenticationRepository: AuthenticationRepository

    let messageRepository: MessageRepository

    let offlineRequestsRepository: OfflineRequestsRepository

    let syncRepository: SyncRepository

    let callRepository: CallRepository

    let channelRepository: ChannelRepository

    func makeMessagesPaginationStateHandler() -> MessagesPaginationStateHandling {
        MessagesPaginationStateHandler()
    }

    /// The `APIClient` instance `Client` uses to communicate with Stream REST API.
    let apiClient: APIClient

    /// The `WebSocketClient` instance `Client` uses to communicate with Stream WS servers.
    let webSocketClient: WebSocketClient?

    /// The `DatabaseContainer` instance `Client` uses to store and cache data.
    let databaseContainer: DatabaseContainer

    /// Used as a bridge to communicate between the host app and the notification extension. Holds the state for the app lifecycle.
    let extensionLifecycle: NotificationExtensionLifecycle

    /// The environment object containing all dependencies of this `Client` instance.
    private let environment: Environment

    /// The default configuration of URLSession to be used for both the `APIClient` and `WebSocketClient`. It contains all
    /// required header auth parameters to make a successful request.
    private var urlSessionConfiguration: URLSessionConfiguration

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
            environment: environment,
            factory: .init(config: config, environment: environment)
        )
    }

    /// Creates a new instance `ChatClient`.
    ///
    /// - Parameters:
    ///   - config: The config object for the `ChatClient`.
    ///   - environment: An object with all external dependencies the new `ChatClient` instance should use.
    ///   - factory: A factory component to help creating all `ChatClient` dependencies.
    init(
        config: ChatClientConfig,
        environment: Environment,
        factory: ChatClientFactory
    ) {
        self.config = config
        self.environment = environment
        
        urlSessionConfiguration = factory.makeUrlSessionConfiguration()
        var apiClientEncoder = factory.makeApiClientRequestEncoder()
        var webSocketEncoder = factory.makeWebSocketRequestEncoder()
        let databaseContainer = factory.makeDatabaseContainer()
        let apiClient = factory.makeApiClient(
            encoder: apiClientEncoder,
            urlSessionConfiguration: urlSessionConfiguration
        )
        let eventNotificationCenter = factory.makeEventNotificationCenter(
            databaseContainer: databaseContainer,
            currentUserId: {
                nil
            }
        )
        let messageRepository = environment.messageRepositoryBuilder(
            databaseContainer,
            apiClient
        )
        let offlineRequestsRepository = environment.offlineRequestsRepositoryBuilder(
            messageRepository,
            databaseContainer,
            apiClient,
            config.queuedActionsMaxHoursThreshold
        )
        let syncRepository = environment.syncRepositoryBuilder(
            config,
            activeChannelControllers,
            activeChannelListControllers,
            offlineRequestsRepository,
            eventNotificationCenter,
            databaseContainer,
            apiClient
        )
        let webSocketClient = factory.makeWebSocketClient(
            requestEncoder: webSocketEncoder,
            urlSessionConfiguration: urlSessionConfiguration,
            eventNotificationCenter: eventNotificationCenter
        )
        let connectionRepository = environment.connectionRepositoryBuilder(
            config.isClientInActiveMode,
            syncRepository,
            webSocketClient,
            apiClient,
            environment.timerType
        )
        let authRepository = environment.authenticationRepositoryBuilder(
            apiClient,
            databaseContainer,
            connectionRepository,
            environment.tokenExpirationRetryStrategy,
            environment.timerType
        )

        self.databaseContainer = databaseContainer
        self.apiClient = apiClient
        self.webSocketClient = webSocketClient
        self.eventNotificationCenter = eventNotificationCenter
        self.offlineRequestsRepository = offlineRequestsRepository
        self.connectionRepository = connectionRepository
        self.messageRepository = messageRepository
        self.syncRepository = syncRepository
        authenticationRepository = authRepository
        extensionLifecycle = environment.extensionLifecycleBuilder(config.applicationGroupIdentifier)
        callRepository = environment.callRepositoryBuilder(apiClient)
        channelRepository = environment.channelRepositoryBuilder(
            databaseContainer,
            apiClient
        )

        authRepository.delegate = self
        apiClientEncoder.connectionDetailsProviderDelegate = self
        webSocketEncoder.connectionDetailsProviderDelegate = self
        webSocketClient?.connectionStateDelegate = self

        setupTokenRefresher()
        setupOfflineRequestQueue()
        setupConnectionRecoveryHandler(with: environment)
    }

    deinit {
        completeConnectionIdWaiters(connectionId: nil)
        completeTokenWaiters(token: nil)
    }

    func setupTokenRefresher() {
        apiClient.tokenRefresher = { [weak self] completion in
            self?.refreshToken { _ in
                completion()
            }
        }
    }

    func setupOfflineRequestQueue() {
        apiClient.queueOfflineRequest = { [weak self] endpoint in
            self?.syncRepository.queueOfflineRequest(endpoint: endpoint)
        }
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

    /// Register a custom attachment payload.
    ///
    /// Example:
    /// ```
    /// registerAttachment(CustomAttachmentPayload.self)
    /// ```
    ///
    /// - Parameter payloadType: The payload type of the attachment.
    public func registerAttachment<Payload: AttachmentPayload>(_ payloadType: Payload.Type) {
        Self.attachmentTypesRegistry[Payload.type] = payloadType
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
        authenticationRepository.connectAnonymousUser(
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

        // Stop tracking active components
        activeChannelControllers.removeAllObjects()
        activeChannelListControllers.removeAllObjects()

        let group = DispatchGroup()
        group.enter()
        disconnect {
            group.leave()
        }

        group.enter()
        databaseContainer.removeAllData { error in
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
            MessageSender(
                messageRepository: messageRepository,
                eventsNotificationCenter: eventNotificationCenter,
                database: databaseContainer,
                apiClient: apiClient
            ),
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
    func logOutUser(completion: @escaping () -> Void) {
        logout(completion: completion)
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
