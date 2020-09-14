//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// If you want to use your custom extra data types to extend `UserModel`, `MessageModel`, or `ChannelModel`,
/// you can use this protocol to set up `Client` with it.
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
/// Additionally, you can introduce the following type aliases in your module to make the work with generic
/// models more convenient:
/// ```
///  typealias Channel = ChannelModel<CustomDataTypes>
///  typealias Message = MessageModel<CustomDataTypes>
/// ```
///
public protocol ExtraDataTypes {
    associatedtype User: UserExtraData = NameAndImageExtraData
    associatedtype Message: MessageExtraData = NoExtraData
    associatedtype Channel: ChannelExtraData = NameAndImageExtraData
}

/// A concrete implementation of `ExtraDataTypes` with the default values.
public struct DefaultDataTypes: ExtraDataTypes {}

/// A convenience typealias for `Client` with the default data types.
public typealias ChatClient = Client<DefaultDataTypes>

/// The root object representing a Stream Chat.
///
/// If you don't need to specify your custom extra data types for `User`, `Channel`, or `Message`, use the convenient non-generic
/// typealias `ChatClient` which specifies the default extra data types.
public class Client<ExtraData: ExtraDataTypes> {
    /// The id of the currently logged in user.
    @Atomic public var currentUserId: UserId = .anonymous
    
    /// The current connection status of the client.
    public var connectionStatus: ConnectionStatus {
        ConnectionStatus(webSocketConnectionState: webSocketClient.connectionState)
    }
    
    /// The config object of the `Client` instance. This can't be mutated and can only be set when initializing a `Client` instance.
    public let config: ChatClientConfig
    
    /// A `Worker` represents a single atomic piece of functionality.`Client` initializes a set of background workers that keep
    /// observing the current state of the system and perform work if needed (i.e. when a new message pending sent appears in the
    /// database, a worker tries to send it.)
    private(set) var backgroundWorkers: [Worker]!
    
    /// Builder blocks used for creating `backgroundWorker`s when needed.
    private let workerBuilders: [WorkerBuilder]
            
    /// The notification center used to send and receive notifications about incoming events.
    private(set) lazy var eventNotificationCenter = environment.notificationCenterBuilder([
        EventDataProcessorMiddleware<ExtraData>(database: databaseContainer),
        TypingStartCleanupMiddleware<ExtraData>(
            excludedUserIds: { [weak self] in Set([self?.currentUserId].compactMap { $0 }) }
        ),
        ChannelReadUpdaterMiddleware<ExtraData>(database: databaseContainer)
    ])
    
    /// The `APIClient` instance `Client` uses to communicate with Stream REST API.
    lazy var apiClient: APIClient = {
        var encoder = environment.requestEncoderBuilder(config.baseURL.restAPIBaseURL, config.apiKey)
        encoder.connectionDetailsProviderDelegate = self
        
        let decoder = environment.requestDecoderBuilder()
        
        let apiClient = environment.apiClientBuilder(urlSessionConfiguration, encoder, decoder)
        return apiClient
    }()
    
    /// The `WebSocketClient` instance `Client` uses to communicate with Stream WS servers.
    lazy var webSocketClient: WebSocketClient = {
        // Create a connection request
        let webSocketEndpoint: Endpoint<EmptyResponse> = .webSocketConnect(
            userId: self.currentUserId,
            extraData: nil as ExtraData.User?
        )
        
        var encoder = environment.requestEncoderBuilder(config.baseURL.webSocketBaseURL, config.apiKey)
        encoder.connectionDetailsProviderDelegate = self
                
        // Create a WebSocketClient.
        let webSocketClient = environment.webSocketClientBuilder(
            webSocketEndpoint,
            urlSessionConfiguration,
            encoder,
            EventDecoder<ExtraData>(),
            eventNotificationCenter,
            internetConnection
        )
        
        webSocketClient.connectionStateDelegate = self
        
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
                return try environment.databaseContainerBuilder(.onDisk(databaseFileURL: dbFileURL))
            }
            
        } catch is ClientError.MissingLocalStorageURL {
            log.assert(false, "The URL provided in ChatClientConfig can't be `nil`. Falling back to the in-memory option.")
            
        } catch {
            log.error("Failed to initalized the local storage with error: \(error). Falling back to the in-memory option.")
        }
        
        do {
            return try environment.databaseContainerBuilder(.inMemory)
        } catch {
            fatalError("Failed to initialize the in-memory storage with erorr: \(error). This is a non-recoverable error.")
        }
    }()
    
    private(set) lazy var internetConnection = environment.internetConnection()
    
    /// The environment object containing all dependencies of this `Client` instance.
    private let environment: Environment
    
    /// The default configuration of URLSession to be used for both the `APIClient` and `WebSocketClient`. It contains all
    /// required header auth parameters to make a successful request.
    private var urlSessionConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.httpAdditionalHeaders = sessionHeaders
        return config
    }
    
    /// Stream-specific request headers.
    private let sessionHeaders: [String: String] = [
        "X-Stream-Client": "stream-chat-swift-client-\(SystemEnvironment.version)"
            + "|\(SystemEnvironment.deviceModelName)" // Device
            + "|\(SystemEnvironment.systemName)" // OS version
            + "|\(SystemEnvironment.name)" // Environment name: development X production
    ]
    
    /// The current connection id
    @Atomic var connectionId: String?
    
    /// An array of requests waiting for the connection id
    @Atomic var connectionIdWaiters: [(String?) -> Void] = []
    
    /// The token of the current user. If the current user is anonymous, the token is `nil`.
    @Atomic var currentToken: Token?
    
    /// Creates a new instance of Stream Chat `Client`.
    ///
    /// - Parameters:
    ///   - config: The config object for the `Client`. See `ChatClientConfig` for all configuration options.
    public convenience init(config: ChatClientConfig) {
        // All production workers
        let workerBuilders: [WorkerBuilder] = [
            MessageSender<ExtraData>.init,
            NewChannelQueryUpdater<ExtraData>.init,
            ChannelWatchStateUpdater<ExtraData>.init,
            MessageEditor<ExtraData>.init,
            MissingEventsPublisher<ExtraData>.init
        ]
        
        self.init(
            config: config,
            workerBuilders: workerBuilders,
            environment: .init()
        )
    }
    
    /// Creates a new instance of Stream Chat `Client`.
    ///
    /// - Parameters:
    ///   - config: The config object for the `Client`.
    ///   - workerBuilders: An array of worker builders the `Client` instance will instantiate and run in the background
    ///   for the whole duration of its lifetime.
    ///   - environment: An object with all external dependencies the new `Client` instance should use.
    init(
        config: ChatClientConfig,
        workerBuilders: [WorkerBuilder],
        environment: Environment
    ) {
        self.config = config
        self.environment = environment
        self.workerBuilders = workerBuilders
        
        createBackgroundWorkers()
    }
    
    deinit {
        connectionIdWaiters.forEach { $0(nil) }
        connectionIdWaiters.removeAll()
    }
    
    // TODO: Not used & tested yet -> CIS-224
    func refreshToken(completion: @escaping (Error?) -> Void) {
        log.assert(config.tokenProvider != nil, "You can't call `refreshToken` when `Config.tokenProvider` is nil.")
        
        config.tokenProvider?(config.apiKey, currentUserId, { [weak self] (token) in
            guard let token = token else {
                completion(ClientError.MissingToken("Can't connect because `TokenProvider` didn't return a valid token."))
                return
            }
            self?.currentToken = token
            completion(nil)
        })
    }
    
    func createBackgroundWorkers() {
        backgroundWorkers = workerBuilders.map { builder in
            builder(self.databaseContainer, self.webSocketClient, self.apiClient)
        }
    }
}

extension Client {
    /// An object containing all dependencies of `Client`
    struct Environment {
        var apiClientBuilder: (
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ requestDecoder: RequestDecoder
        ) -> APIClient = { APIClient(sessionConfiguration: $0, requestEncoder: $1, requestDecoder: $2) }
        
        var webSocketClientBuilder: (
            _ connectEndpoint: Endpoint<EmptyResponse>,
            _ sessionConfiguration: URLSessionConfiguration,
            _ requestEncoder: RequestEncoder,
            _ eventDecoder: AnyEventDecoder,
            _ notificationCenter: EventNotificationCenter,
            _ internetConnection: InternetConnection
        ) -> WebSocketClient = {
            WebSocketClient(
                connectEndpoint: $0,
                sessionConfiguration: $1,
                requestEncoder: $2,
                eventDecoder: $3,
                eventNotificationCenter: $4,
                internetConnection: $5
            )
        }
        
        var databaseContainerBuilder: (_ kind: DatabaseContainer.Kind) throws -> DatabaseContainer = {
            try DatabaseContainer(kind: $0)
        }
        
        var requestEncoderBuilder: (_ baseURL: URL, _ apiKey: APIKey) -> RequestEncoder = DefaultRequestEncoder.init
        var requestDecoderBuilder: () -> RequestDecoder = DefaultRequestDecoder.init
        
        var eventDecoderBuilder: () -> EventDecoder<ExtraData> = EventDecoder<ExtraData>.init
        
        var notificationCenterBuilder: ([EventMiddleware]) -> EventNotificationCenter = EventNotificationCenter.init
        
        var internetConnection: () -> InternetConnection = { InternetConnection() }
    }
}

extension ClientError {
    // An example of a simple error
    public class MissingLocalStorageURL: ClientError {
        override public var localizedDescription: String { "The URL provided in ChatClientConfig is `nil`." }
    }
    
    public class ConnectionNotSuccessfull: ClientError {
        override public var localizedDescription: String {
            "Connecting to the chat servers wasn't successfull. Please check the console log for additional info."
        }
    }
    
    public class MissingToken: ClientError {}
}

/// `APIClient` listens for `WebSocketClient` connection updates so it can forward the current connection id to
/// its `RequestEncoder`.
extension Client: ConnectionStateDelegate {
    func webSocketClient(_ client: WebSocketClient, didUpdateConectionState state: WebSocketConnectionState) {
        if case let .connected(connectionId) = state {
            self.connectionId = connectionId
            connectionIdWaiters.forEach { $0(connectionId) }
            connectionIdWaiters.removeAll()
        } else {
            connectionId = nil
        }
    }
}

/// `Client` provides connection details for the `RequestEncoder`s it creates.
extension Client: ConnectionDetailsProviderDelegate {
    func provideToken() -> Token? {
        currentToken
    }
    
    func provideConnectionId(completion: @escaping (String?) -> Void) {
        if let connectionId = connectionId {
            completion(connectionId)
        } else {
            connectionIdWaiters.append(completion)
        }
    }
}
