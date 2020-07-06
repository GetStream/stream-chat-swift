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
    /// An object containing all dependencies of `Client`
    struct Environment {
        var apiClientBuilder: (
            _ apiKey: APIKey,
            _ baseURL: URL,
            _ sessionConfiguration: URLSessionConfiguration
        ) -> APIClient = { APIClient(apiKey: $0, baseURL: $1, sessionConfiguration: $2) }
        
        var webSocketClientBuilder: (
            _ urlRequest: URLRequest,
            _ sessionConfiguration: URLSessionConfiguration,
            _ eventDecoder: AnyEventDecoder,
            _ eventMiddlewares: [EventMiddleware]
        ) -> WebSocketClient = { WebSocketClient(urlRequest: $0, sessionConfiguration: $1, eventDecoder: $2, eventMiddlewares: $3) }
        
        var databaseContainerBuilder: (_ kind: DatabaseContainer.Kind) throws
            -> DatabaseContainer = { try DatabaseContainer(kind: $0) }
    }
    
    /// The currently logged-in user.
    public let currentUser: UserModel<ExtraData.User>
    
    /// The config object of the `Client` instance. This can't be mutated and can only be set when initializing a `Client` instance.
    public let config: ChatClientConfig
    
    /// A `Worker` represents a single atomic piece of functionality.`Client` initializes a set of background workers that keep
    /// observing the current state of the system and perform work if needed (i.e. when a new message pending sent appears in the
    /// database, a worker tries to send it.)
    private(set) var backgroundWorkers: [Worker]!
    
    /// The `APIClient` instance `Client` uses to communicate with Stream REST API.
    private(set) lazy var apiClient: APIClient = {
        let apiClient = self.environment
            .apiClientBuilder(self.config.apiKey, config.baseURL.restAPIBaseURL, self.urlSessionConfiguration)
        self.webSocketClient.connectionStateDelegate = apiClient
        return apiClient
    }()
    
    /// The `WebSocketClient` instance `Client` uses to communicate with Stream WS servers.
    private(set) lazy var webSocketClient: WebSocketClient = {
        // Set up event middlewares
        let middlewares: [EventMiddleware] = [
            // TODO: Add more middlewares
            EventDataProcessorMiddleware<ExtraData>(database: self.persistentContainer),
            HealthCheckFilter()
        ]
        
        // Create a connection request
        let socketPayload = WebSocketPayload<ExtraData>(user: self.currentUser, token: token)
        let webSocketEndpoint = Endpoint<EmptyResponse>(path: "connect",
                                                        method: .get,
                                                        queryItems: nil,
                                                        requiresConnectionId: false,
                                                        body: ["json": socketPayload])
        
        let requestEncoder = DefaultRequestEncoder(baseURL: config.baseURL.webSocketBaseURL, apiKey: config.apiKey)
        
        do {
            let request = try requestEncoder.encodeRequest(for: webSocketEndpoint)
            
            let wsClient = environment.webSocketClientBuilder(request,
                                                              urlSessionConfiguration,
                                                              EventDecoder<ExtraData>(),
                                                              middlewares)
            return wsClient
            
        } catch {
            fatalError("Failed to initialize WebSocketClient with error: \(error)")
        }
    }()
    
    /// The `DatabaseContainer` instance `Client` uses to store and cache data.
    private(set) lazy var persistentContainer: DatabaseContainer = {
        do {
            if config.isLocalStorageEnabled {
                guard let storeURL = config.localStorageFolderURL else {
                    throw ClientError.MissingLocalStorageURL()
                }
                
                // Create the folder if needed
                try? FileManager.default.createDirectory(at: config.localStorageFolderURL!,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil)
                let dbFileURL = config.localStorageFolderURL!.appendingPathComponent(currentUser.id)
                return try environment.databaseContainerBuilder(.onDisk(databaseFileURL: dbFileURL))
            }
            
        } catch let error as ClientError.MissingLocalStorageURL {
            log.assert(false, "The URL provided in ChatClientConfig can't be `nil`.")
            
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
        config.httpAdditionalHeaders = authSessionHeaders
        return config
    }
    
    /// Stream-specific request auth headers.
    private var authSessionHeaders: [String: String] {
        var headers = [
            "X-Stream-Client": "stream-chat-swift-client-\(SystemEnvironment.version)",
            "X-Stream-Device": SystemEnvironment.deviceModelName,
            "X-Stream-OS": SystemEnvironment.systemName,
            "X-Stream-App-Environment": SystemEnvironment.name
        ]
        
        // TODO: CIS-164
        
        //      if token.isBlank || user.isAnonymous {
        //          headers["Stream-Auth-Type"] = "anonymous"
        //      } else {
        headers["Stream-Auth-Type"] = "jwt"
        headers["Authorization"] = token
        //      }
        
        if let bundleId = Bundle.main.id {
            headers["X-Stream-BundleId"] = bundleId
        }
        
        return headers
    }
    
    /// Creates a new instance of Stream Chat `Client`.
    ///
    /// - Parameters:
    ///   - currentUser: The user instance representing the current user of the chat.
    ///   - config: The config object for the `Client`. See `ChatClientConfig` for all configuration options.
    public convenience init(currentUser: UserModel<ExtraData.User>, config: ChatClientConfig) {
        // All production workers
        let workerBuilders: [WorkerBuilder] = [
            MessageSender.init,
            ChannelEventsHandler<ExtraData>.init
        ]
        
        self.init(currentUser: currentUser,
                  config: config,
                  workerBuilders: workerBuilders,
                  environment: .init())
    }
    
    /// Creates a new instance of Stream Chat `Client`.
    ///
    /// - Parameters:
    ///   - currentUser: The user instance representing the current user of the chat.
    ///   - config: The config object for the `Client`.
    ///   - workerBuilders: An array of worker builders the `Client` instance will instantiate and run in the background
    ///   for the whole duration of its lifetime.
    ///   - environment: An object with all external dependencies the new `Client` instance should use.
    init(currentUser: UserModel<ExtraData.User>,
         config: ChatClientConfig,
         workerBuilders: [WorkerBuilder],
         environment: Environment) {
        self.config = config
        self.currentUser = currentUser
        self.environment = environment
        
        backgroundWorkers = workerBuilders.map { builder in
            builder(self.persistentContainer, self.webSocketClient, self.apiClient)
        }
    }
}

// MARK: ========= TEMPORARY!

extension Client {
    var token: String {
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg"
    }
}

extension ClientError {
    // An example of a simple error
    public class MissingLocalStorageURL: ClientError {
        override public var localizedDescription: String { "The URL provided in ChatClientConfig is `nil`." }
    }
}
