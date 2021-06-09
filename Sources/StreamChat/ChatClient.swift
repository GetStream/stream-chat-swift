//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// A protocol defining extra data types used by `ChatClient`.
///
/// You can add additional (extra) data to entities in the chat system. For now, you can add extra data to `ChatUser`,
/// `ChatChannel`, and `ChatMessage`.
///
/// Example usage:
/// ```
///   enum CustomDataTypes: ExtraDataTypes {
///     typealias Channel = MyCustomChannelExtraData
///     typealias Message = MyCustomMessageExtraData
///   }
///
///   let client = Client<CustomDataTypes>(currentUser: user, config: config)
/// ```
///
public protocol ExtraDataTypes {
    /// An extra data type for `ChatUser`.
    associatedtype User: UserExtraData = NoExtraData
    
    /// An extra data type for `ChatMessage`.
    associatedtype Message: MessageExtraData = NoExtraData
    
    /// An extra data type for `ChatChannel`.
    associatedtype Channel: ChannelExtraData = NoExtraData
    
    /// An extra data type for `ChatMessageReaction`.
    associatedtype MessageReaction: MessageReactionExtraData = NoExtraData
}

/// The root object representing a Stream Chat.
///
/// Typically, an app contains just one instance of `ChatClient`. However, it's possible to have multiple instances if your use
/// case requires it (i.e. more than one window with different workspaces in a Slack-like app).
///
/// - Note: `ChatClient` is a typealias of `_ChatClient` with the default extra data types. If you want to use your custom extra
/// data types, you should create your own `ChatClient` typealias for `_ChatClient`. Learn more about using custom extra data in our
/// [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatClient = _ChatClient<NoExtraData>

/// The root object representing a Stream Chat.
///
/// Typically, an app contains just one instance of `ChatClient`. However, it's possible to have multiple instances if your use
/// case requires it (i.e. more than one window with different workspaces in a Slack-like app).
///
/// - Note: `_ChatClient` type is not meant to be used directly. If you don't use custom extra data types, use `ChatClient`
/// typealias instead. When using custom extra data types, you should create your own `ChatClient` typealias for `_ChatClient`.
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _ChatClient<ExtraData: ExtraDataTypes> {
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
            EventDataProcessorMiddleware<ExtraData>(),
            TypingStartCleanupMiddleware<ExtraData>(
                excludedUserIds: { [weak self] in Set([self?.currentUserId].compactMap { $0 }) },
                emitEvent: { [weak center] in center?.process($0) }
            ),
            ChannelReadUpdaterMiddleware<ExtraData>(),
            ChannelMemberTypingStateUpdaterMiddleware<ExtraData>(),
            MessageReactionsMiddleware<ExtraData>(),
            ChannelTruncatedEventMiddleware<ExtraData>(),
            MemberEventMiddleware<ExtraData>(),
            UserChannelBanEventsMiddleware<ExtraData>(),
            UserWatchingEventMiddleware<ExtraData>(),
            ChannelVisibilityEventMiddleware<ExtraData>()
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
            )
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
            EventDecoder<ExtraData>(),
            eventNotificationCenter,
            internetConnection
        )

        if let currentUserId = currentUserId {
            webSocketClient?.connectEndpoint = .webSocketConnect(userId: currentUserId)
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
                    config.localCaching
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
                config.localCaching
            )
        } catch {
            fatalError("Failed to initialize the in-memory storage with error: \(error). This is a non-recoverable error.")
        }
    }()
    
    private(set) lazy var internetConnection = environment.internetConnection()
    private(set) lazy var clientUpdater = environment.clientUpdaterBuilder(self)
    /// Used for starting and ending background tasks. Hides platform specific logic.
    private lazy var backgroundTaskScheduler = environment.backgroundTaskSchedulerBuilder()
    
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
        "X-Stream-Client": "stream-chat-swift-client-v\(SystemEnvironment.version)"
    ]
    
    /// The current connection id
    @Atomic var connectionId: String?
    
    /// An array of requests waiting for the connection id
    @Atomic var connectionIdWaiters: [(String?) -> Void] = []

    /// An array of requests waiting for the token
    @Atomic var tokenWaiters: [(Token?) -> Void] = []
    
    /// The token of the current user. If the current user is anonymous, the token is `nil`.
    @Atomic var currentToken: Token?

    public var tokenProvider: _TokenProvider<ExtraData>
    
    /// Creates a new instance of `ChatClient`.
    /// - Parameters:
    ///   - config: The config object for the `Client`. See `ChatClientConfig` for all configuration options.
    ///   - tokenProvider: The `_TokenProvider<ExtraData>` instance that incapsulates the logic of obtaining a JWT
    ///   token used to communicate with REST-API.
    ///   - completion: The completion that will be called once the **first** user session for the given token is setup.
    public convenience init(
        config: ChatClientConfig,
        tokenProvider: _TokenProvider<ExtraData>,
        completion: ((Error?) -> Void)? = nil
    ) {
        let workerBuilders: [WorkerBuilder]
        let eventWorkerBuilders: [EventWorkerBuilder]
        var environment = Environment()
        
        if config.isClientInActiveMode {
            // All production workers
            workerBuilders = [
                MessageSender<ExtraData>.init,
                NewChannelQueryUpdater<ExtraData>.init,
                NewUserQueryUpdater<ExtraData.User>.init,
                MessageEditor<ExtraData>.init,
                AttachmentUploader.init
            ]
            
            // All production event workers
            eventWorkerBuilders = [
                ChannelWatchStateUpdater<ExtraData>.init,
                MissingEventsPublisher<ExtraData>.init
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
            environment: environment,
            completion: completion
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
        tokenProvider: _TokenProvider<ExtraData>,
        workerBuilders: [WorkerBuilder],
        eventWorkerBuilders: [EventWorkerBuilder],
        environment: Environment,
        completion: ((Error?) -> Void)? = nil
    ) {
        self.config = config
        self.tokenProvider = tokenProvider
        self.environment = environment
        self.workerBuilders = workerBuilders
        self.eventWorkerBuilders = eventWorkerBuilders

        currentUserId = fetchCurrentUserIdFromDatabase()

        clientUpdater.reloadUserIfNeeded(completion: completion)
        
        backgroundTaskScheduler?.startListeningForAppStateUpdates(
            onEnteringBackground: { [weak self] in self?.handleAppDidEnterBackground() },
            onEnteringForeground: { [weak self] in self?.handleAppDidBecomeActive() }
        )
    }
    
    deinit {
        completeConnectionIdWaiters(connectionId: nil)
        completeTokenWaiters(token: nil)
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
    
    private func handleAppDidEnterBackground() {
        // If user wants to manage connection manaully, we don't handle
        guard config.shouldConnectAutomatically else { return }
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
            // We need to call `endBackgroundTask` else our app will be killed
            self?.cancelBackgroundTaskIfNeeded()
        }
        
        if !succeed {
            // Can't initiate a background task, close the connection
            clientUpdater.disconnect(source: .systemInitiated)
        }
    }
    
    private func handleAppDidBecomeActive() {
        cancelBackgroundTaskIfNeeded()
        
        // If user wants to manage connection manaully, we don't handle reconnection
        guard config.shouldConnectAutomatically else { return }
        guard connectionStatus != .connected && connectionStatus != .connecting else {
            // We are connected or connecting anyway
            return
        }
        clientUpdater.connect()
    }
    
    private func cancelBackgroundTaskIfNeeded() {
        backgroundTaskScheduler?.endTask()
    }
}

extension _ChatClient {
    /// An object containing all dependencies of `Client`
    struct Environment {
        var apiClientBuilder: (
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ requestDecoder: RequestDecoder,
            _ CDNClient: CDNClient
        ) -> APIClient = {
            APIClient(
                sessionConfiguration: $0,
                requestEncoder: $1,
                requestDecoder: $2,
                CDNClient: $3
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
            _ localCachingSettings: ChatClientConfig.LocalCaching?
        ) throws -> DatabaseContainer = {
            try DatabaseContainer(kind: $0, shouldFlushOnStart: $1, shouldResetEphemeralValuesOnStart: $2, localCachingSettings: $3)
        }
        
        var requestEncoderBuilder: (_ baseURL: URL, _ apiKey: APIKey) -> RequestEncoder = DefaultRequestEncoder.init
        var requestDecoderBuilder: () -> RequestDecoder = DefaultRequestDecoder.init
        
        var eventDecoderBuilder: () -> EventDecoder<ExtraData> = EventDecoder<ExtraData>.init
        
        var notificationCenterBuilder = EventNotificationCenter.init
        
        var internetConnection: () -> InternetConnection = { InternetConnection() }

        var clientUpdaterBuilder = ChatClientUpdater<ExtraData>.init
        
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
}

/// `APIClient` listens for `WebSocketClient` connection updates so it can forward the current connection id to
/// its `RequestEncoder`.
extension _ChatClient: ConnectionStateDelegate {
    func webSocketClient(_ client: WebSocketClient, didUpdateConectionState state: WebSocketConnectionState) {
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
                clientUpdater.reloadUserIfNeeded()
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
    
    /// Update connectionId and notify waiters if needed
    /// - Parameters:
    ///   - connectionId: new connectionId (if present)
    ///   - shouldFailWaiters: Whether it's necessary to notify waiters or not
    private func updateConnectionId(
        connectionId: String?,
        shouldNotifyWaiters: Bool
    ) {
        _connectionId.mutate { mutableConnectionId in
            _connectionIdWaiters.mutate { connectionIdWaiters in
                mutableConnectionId = connectionId
                if shouldNotifyWaiters {
                    connectionIdWaiters.forEach { $0(connectionId) }
                    connectionIdWaiters.removeAll()
                }
            }
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
extension _ChatClient: ConnectionDetailsProviderDelegate {
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
