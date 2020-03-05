//
//  Client.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// A network client.
public final class Client {
    /// A request completion block.
    public typealias Completion<T: Decodable> = (Result<T, ClientError>) -> Void
    
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
    
    let baseURL: BaseURL
    let stayConnectedInBackground: Bool
    
    /// A list of reaction types.
    public let reactionTypes: [ReactionType]

    /// A database for an offline mode.
    public internal(set) var database: Database?
    
    var token: Token? {
        didSet { tokenSubject.onNext(token) }
    }
    
    let tokenSubject = BehaviorSubject<Token?>(value: nil)
    var tokenProvider: TokenProvider?
    var expiredTokenDisposeBag = DisposeBag()
    var isExpiredTokenInProgress = false
    
    /// A web socket client.
    public internal(set) lazy var webSocket = WebSocket()
    
    lazy var urlSession = setupURLSession(token: "")
    private(set) lazy var urlSessionTaskDelegate = ClientURLSessionTaskDelegate() // swiftlint:disable:this weak_delegate
    let callbackQueue: DispatchQueue?
    private let uuid = UUID()
    
    /// A log manager.
    public let logger: ClientLogger?
    let logOptions: ClientLogger.Options

    /// An observable user.
    public internal(set) lazy var userDidUpdate: Driver<User?> = userPublishSubject.asDriver(onErrorJustReturn: nil)
    private let userPublishSubject = PublishSubject<User?>()
    
    /// The current user.
    public internal(set) var user: User? {
        didSet { userPublishSubject.onNext(user) }
    }
    
    var unreadCountAtomic = Atomic<UnreadCount>((0, 0))
    
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
    init(apiKey: String = Client.config.apiKey,
         baseURL: BaseURL = Client.config.baseURL,
         callbackQueue: DispatchQueue? = Client.config.callbackQueue,
         reactionTypes: [ReactionType] = Client.config.reactionTypes,
         stayConnectedInBackground: Bool = Client.config.stayConnectedInBackground,
         database: Database? = Client.config.database,
         logOptions: ClientLogger.Options = Client.config.logOptions) {
        if !apiKey.isEmpty, logOptions.isEnabled {
            ClientLogger.logger("💬", "", "StreamChat v\(Environment.version)")
            ClientLogger.logger("🔑", "", apiKey)
            ClientLogger.logger("🔗", "", baseURL.description)
            
            if let database = database {
                ClientLogger.logger("💽", "", "\(database.self)")
            }
        }
        
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.callbackQueue = callbackQueue
        self.reactionTypes = reactionTypes
        self.stayConnectedInBackground = stayConnectedInBackground
        self.database = database
        self.logOptions = logOptions
        logger = logOptions.logger(icon: "🐴", for: [.requestsError, .requests, .requestsInfo])
        
        #if DEBUG
        checkLatestVersion()
        #endif
        checkAPIKey()
    }
    
    private func checkAPIKey() {
        if apiKey.isEmpty {
            ClientLogger.logger("❌❌❌", "", "The Stream Chat Client didn't setup properly. "
                + "You are trying to use it before setup the API Key.")
            Thread.callStackSymbols.forEach { ClientLogger.logger("", "", $0) }
        }
    }

    /// Disconnect from Stream and reset the current user.
    ///
    /// Resets and removes the user/token pair as well as relevant network connections.
    ///
    /// - Note: To restore the connection, use `Client.set(user:, token:)` to set a valid user/token pair.
    public func disconnect() {
        guard user != nil else {
            return
        }
        
        logger?.log("🧹 Reset Client User, Token, URLSession and WebSocket.")
        user = nil
        urlSession = setupURLSession(token: "")
        webSocket.disconnect()
        webSocket = WebSocket()
        token = nil
        Message.flaggedIds = []
        User.flaggedUsers = []
    }
}
