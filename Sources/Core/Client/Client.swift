//
//  Client.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

/// A network client.
public final class Client {
    /// A request completion block.
    public typealias Completion<T: Decodable> = (Result<T, ClientError>) -> Void
    
    /// A client config (see `Config`).
    public static var config = Config(apiKey: "")
    /// A shared client.
    public static let shared = Client()
    
    let apiKey: String
    let baseURL: BaseURL
    let stayConnectedInBackground: Bool
    
    /// A databse for an offline mode.
    public let database: Database?
    
    var token: Token? {
        didSet { tokenSubject.onNext(token) }
    }
    
    let tokenSubject = BehaviorSubject<Token?>(value: nil)
    
    /// A web socket client.
    public internal(set) lazy var webSocket = WebSocket()
    
    lazy var urlSession = setupURLSession(token: "")
    private(set) lazy var urlSessionTaskDelegate = ClientURLSessionTaskDelegate()
    let callbackQueue: DispatchQueue?
    private let uuid = UUID()
    let logOptions: ClientLogger.Options
    
    /// A log manager.
    public let logger: ClientLogger?
    /// The current user.
    public var user: User?
    
    /// An observable client web socket connection.
    /// 
    /// The connection is responsible for:
    /// * Checking the Internet connection.
    /// * Checking the app state, e.g. active, background.
    /// * Connecting and reconnecting to the web sockets.
    ///
    /// Example of usage:
    /// ```
    /// // Start observing connection statuses.
    /// Client.shared.connection
    ///     // Filter connection statuses only for connected.
    ///     .connected()
    ///     // Send a message request to a channel.
    ///     .flatMapLatest {
    ///         // Make a request here.
    ///     }
    ///     // Subscribe for a result.
    ///     .subscribe(onNext: { response in
    ///         // Handle the reponse.
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    ///
    /// All requests from the client or a channel are wrapped with connection events.
    /// You can do requests directly.
    ///
    /// For example:
    /// ```
    /// // Find all channels with type `messaging`.
    /// let channelsQuery = ChannelsQuery(filter: .key("type", .equal(to: "messaging")))
    /// Client.shared.channels(query: channelsQuery)
    ///     // Here we will get channels when web socket will be connected.
    ///     // Select the first channel.
    ///     .map { $0.first }
    ///     .unwrap()
    ///     // Send a message to the first channel.
    ///     .flatMapLatest { $0.send(message: Message(text: "Hi!")) }
    ///     .subscribe(onNext: { result in
    ///         print(result)
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    ///
    public private(set) lazy var connection = createObservableConnection()
    
    /// Init a network client.
    ///
    /// - Parameters:
    ///     - apiKey: a Stream Chat API key.
    ///     - baseURL: a base URL (see `BaseURL`).
    ///     - callbackQueue: a request callback queue, default nil (some background thread).
    ///     - stayConnectedInBackground: when the app will go to the background,
    ///                                  start a background task to stay connected for 5 min
    ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
    public init(apiKey: String = Client.config.apiKey,
                baseURL: BaseURL = Client.config.baseURL,
                callbackQueue: DispatchQueue? = Client.config.callbackQueue,
                stayConnectedInBackground: Bool = Client.config.stayConnectedInBackground,
                database: Database? = Client.config.database,
                logOptions: ClientLogger.Options = Client.config.logOptions) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.callbackQueue = callbackQueue
        self.stayConnectedInBackground = stayConnectedInBackground
        self.database = database
        self.logOptions = logOptions
        
        if logOptions == .all || logOptions == .requests || logOptions == .requestsHeaders {
            logger = ClientLogger(icon: "🐴", options: logOptions)
        } else {
            logger = nil
        }
    }
    
    func reset() {
        guard user != nil else {
            return
        }
        
        logger?.log("Reset Client User, Token, URLSession and WebSocket.")
        user = nil
        urlSession = setupURLSession(token: "")
        webSocket.disconnect()
        webSocket = WebSocket()
        token = nil
    }
}

extension Client {
    /// A config for a shread `Client`.
    public struct Config {
        /// A Stream Chat API key.
        public let apiKey: String
        /// A base URL (see `BaseURL`).
        public let baseURL: BaseURL
        /// A request callback queue, default nil (some background thread).
        public let callbackQueue: DispatchQueue?
        /// When the app will go to the background, start a background task to stay connected for 5 min.
        public let stayConnectedInBackground: Bool
        /// A local database.
        public let database: Database?
        /// Enable logs (see `ClientLogger.Options`), e.g. `.all`.
        public let logOptions: ClientLogger.Options
        
        /// Init a config for a shread `Client`.
        ///
        /// - Parameters:
        ///     - apiKey: a Stream Chat API key.
        ///     - baseURL: a base URL (see `BaseURL`).
        ///     - callbackQueue: a request callback queue, default nil (some background thread).
        ///     - stayConnectedInBackground: when the app will go to the background,
        ///                                  start a background task to stay connected for 5 min
        ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
        public init(apiKey: String,
                    baseURL: BaseURL = BaseURL(),
                    callbackQueue: DispatchQueue? = nil,
                    stayConnectedInBackground: Bool = true,
                    database: Database? = nil,
                    logOptions: ClientLogger.Options = .none) {
            self.apiKey = apiKey
            self.baseURL = baseURL
            self.callbackQueue = callbackQueue
            self.stayConnectedInBackground = stayConnectedInBackground
            self.database = database
            self.logOptions = logOptions
        }
    }
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }
}
