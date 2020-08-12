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
    
    /// The currently logged-in user data.
    ///
    /// Returns `nil` if the user is not fully logged-in yet. Always wait for the `setUser` completion block before
    /// accessing this value.
    public var currentUser: CurrentUserModel<ExtraData.User>? {
        guard let user: CurrentUserModel<ExtraData.User> = databaseContainer.viewContext.loadCurrentUser() else {
            log.error("You're trying to access the current user but the connection is not fully estabilshed. " +
                "Wait for the completion block to be called before accessing the current user data.")
            return nil
        }
        return user
    }
    
    /// The config object of the `Client` instance. This can't be mutated and can only be set when initializing a `Client` instance.
    public let config: ChatClientConfig
    
    /// A `Worker` represents a single atomic piece of functionality.`Client` initializes a set of background workers that keep
    /// observing the current state of the system and perform work if needed (i.e. when a new message pending sent appears in the
    /// database, a worker tries to send it.)
    private(set) var backgroundWorkers: [Worker]!
    
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
        let webSocketEndpoint = webSocketConnectEndpoint(userId: self.currentUserId)
        
        var encoder = environment.requestEncoderBuilder(config.baseURL.webSocketBaseURL, config.apiKey)
        encoder.connectionDetailsProviderDelegate = self
        
        let connectEndpoint = webSocketConnectEndpoint(userId: currentUserId)
        
        // Create middlewares.
        let eventMiddlewares: [EventMiddleware] = [
            EventDataProcessorMiddleware<ExtraData>(database: databaseContainer)
        ]
        
        // Create a WebSocketClient.
        let webSocketClient = environment.webSocketClientBuilder(webSocketEndpoint,
                                                                 urlSessionConfiguration,
                                                                 encoder,
                                                                 EventDecoder<ExtraData>(),
                                                                 eventMiddlewares)
        
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
                try? FileManager.default.createDirectory(at: storeURL,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil)
                
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
    @Atomic private var connectionId: String?
    
    /// An array of requests waiting for the connection id
    @Atomic private var connectionIdWaiters: [(String?) -> Void] = []
    
    /// The token of the current user. If the current user is anonymous, the token is `nil`.
    @Atomic private var currentToken: Token?
    
    /// Creates a new instance of Stream Chat `Client`.
    ///
    /// - Parameters:
    ///   - config: The config object for the `Client`. See `ChatClientConfig` for all configuration options.
    public convenience init(config: ChatClientConfig) {
        // All production workers
        let workerBuilders: [WorkerBuilder] = [
            MessageSender.init
        ]
        
        self.init(config: config,
                  workerBuilders: workerBuilders,
                  environment: .init())
    }
    
    /// Creates a new instance of Stream Chat `Client`.
    ///
    /// - Parameters:
    ///   - config: The config object for the `Client`.
    ///   - workerBuilders: An array of worker builders the `Client` instance will instantiate and run in the background
    ///   for the whole duration of its lifetime.
    ///   - environment: An object with all external dependencies the new `Client` instance should use.
    init(config: ChatClientConfig,
         workerBuilders: [WorkerBuilder],
         environment: Environment) {
        self.config = config
        self.environment = environment
        
        backgroundWorkers = workerBuilders.map { builder in
            builder(self.databaseContainer, self.webSocketClient, self.apiClient)
        }
    }
    
    deinit {
        connectionIdWaiters.forEach { $0(nil) }
        connectionIdWaiters.removeAll()
    }
    
    /// Sets a new anonymous current user of the ChatClient.
    ///
    /// Anonymous users have limited set of permissions. A typical use case for anonymous users are livestream channels,
    /// where they are allowed to read the conversation.
    ///
    /// - Parameters:
    ///   - completion: Called when the new anonymous user is set. If setting up the new user fails, the completion
    /// is called with an error.
    public func setAnonymousUser(completion: ((Error?) -> Void)? = nil) {
        disconnect()
        prepareEnvironmentForNewUser(userId: .anonymous, role: .anonymous, extraData: nil) { error in
            guard error == nil else {
                completion?(error)
                return
            }
            
            self.connect(completion: completion)
        }
    }
    
    public func setGuestUser(userId: UserId, extraData: ExtraData.User? = nil, completion: ((Error?) -> Void)? = nil) {
        fatalError("not implemented")
    }
    
    /// Sets a new current user of the ChatClient.
    ///
    /// - Important: Setting a new user disconnects all the existing controllers. You should create new controllers
    /// if you want to keep receiving updates about the newly set user.
    ///
    /// - Parameters:
    ///   - userId: The id of the new current user.
    ///   - userExtraData: You can optionally provide additional data to be set for the user. This is an equivalent of
    ///   setting the current user detail data manually using `CurrentUserController`.
    ///   - token: You can provide a token which is used for user authentication. If the `token` is not explicitly provided,
    ///   the client uses `ChatClientConfig.tokenProvider` to obtain a token. If you haven't specified the token provider,
    ///   providing a token explicitly is required. In case both the `token` and `ChatClientConfig.tokenProvider` is specified,
    ///   the `token` value is used.
    ///   - completion: Called when the new user is successfully set.
    public func setUser(userId: UserId,
                        userExtraData: ExtraData.User? = nil,
                        token: Token? = nil,
                        completion: ((Error?) -> Void)? = nil) {
        guard token != nil || config.tokenProvider != nil else {
            log.assert(false,
                       "The provided token is `nil` and `ChatClientConfig.tokenProvider` is also `nil`. You must either provide " +
                           "a token explicitly or set `TokenProvider` in `ChatClientConfig`.")
            completion?(ClientError.MissingToken())
            return
        }
        
        guard userId != currentUserId else {
            log.warning("New user with id:<\(userId)> is not set because it's similar to the already logged-in user.")
            completion?(nil)
            return
        }
        
        disconnect()
        
        prepareEnvironmentForNewUser(userId: userId, role: .user, extraData: userExtraData) { error in
            guard error == nil else {
                completion?(error)
                return
            }
            
            if let token = token {
                self.currentToken = token
                self.connect(completion: completion)
                
            } else {
                // Use `tokenProvider` to get the token
                self.refreshToken { [weak self] (error) in
                    guard error != nil else {
                        completion?(error)
                        return
                    }
                    
                    self?.connect(completion: completion)
                }
            }
        }
    }
    
    /// Connects `Client` to the chat servers. When the connection is established, `Client` starts receiving chat updates.
    ///
    /// - Parameter completion: Called when the connection is established. If the connection fails, the completion is
    /// called with an error.
    public func connect(completion: ((Error?) -> Void)? = nil) {
        guard connectionId == nil else {
            log.warning("The client is already connected. Skipping the `connect` call.")
            completion?(nil)
            return
        }
        
        // Set up a waiter for the new connection id to know when the connection process is finished
        provideConnectionId { connectionId in
            if connectionId != nil {
                completion?(nil)
            } else {
                completion?(ClientError.ConnectionNotSuccessfull())
            }
        }
        
        webSocketClient.connect()
    }
    
    /// Disconnects `Client` from the chat servers. No further updates from the servers are received.
    public func disconnect() {
        // Disconnect the web socket
        webSocketClient.disconnect(source: .userInitiated)
        
        // Reset `connectionId`. This would happen asynchronously by the callback from WebSocketClient anyway, but it's
        // safer to do it here synchronously to immediately stop all API calls.
        connectionId = nil
        
        // Remove all waiters for connectionId
        connectionIdWaiters.removeAll()
    }
    
    // TODO: Not used & tested yet -> CIS-224
    private func refreshToken(completion: @escaping (Error?) -> Void) {
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
    
    private func prepareEnvironmentForNewUser(userId: UserId,
                                              role: UserRole,
                                              extraData: ExtraData.User? = nil,
                                              completion: @escaping (Error?) -> Void) {
        // Reset the current token
        currentToken = nil
        
        // Set up a new user id
        currentUserId = userId
        
        // Set a new WebSocketClient connect endpoint and refresh the middlewares.
        webSocketClient.connectEndpoint = webSocketConnectEndpoint(userId: userId, role: role, extraData: extraData)
        
        // Reset all existing data
        databaseContainer.removeAllData(force: true) { completion($0) }
    }
    
    private func webSocketConnectEndpoint(userId: UserId, role: UserRole = .user,
                                          extraData: ExtraData.User? = nil) -> Endpoint<EmptyResponse> {
        // Create a connection request
        let socketPayload = WebSocketConnectPayload<ExtraData.User>(userId: currentUserId, userRole: role, extraData: extraData)
        let webSocketEndpoint = Endpoint<EmptyResponse>(path: "connect",
                                                        method: .get,
                                                        queryItems: nil,
                                                        requiresConnectionId: false,
                                                        body: ["json": socketPayload])
        
        return webSocketEndpoint
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
            _ eventMiddlewares: [EventMiddleware]
        ) -> WebSocketClient = {
            WebSocketClient(connectEndpoint: $0,
                            sessionConfiguration: $1,
                            requestEncoder: $2,
                            eventDecoder: $3,
                            eventMiddlewares: $4)
        }
        
        var databaseContainerBuilder: (_ kind: DatabaseContainer.Kind) throws -> DatabaseContainer = {
            try DatabaseContainer(kind: $0)
        }
        
        var requestEncoderBuilder: (_ baseURL: URL, _ apiKey: APIKey) -> RequestEncoder = DefaultRequestEncoder.init
        var requestDecoderBuilder: () -> RequestDecoder = DefaultRequestDecoder.init
        
        var eventDecoderBuilder: () -> EventDecoder<ExtraData> = EventDecoder<ExtraData>.init
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
    func webSocketClient(_ client: WebSocketClient, didUpdateConectionState state: ConnectionState) {
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
