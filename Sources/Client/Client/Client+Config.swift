//
//  Client+Config.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 05/03/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Client Configuration

extension Client {

    /// A configuration object for `Client`.
    ///
    /// To create a new `Config` object a non-empty API key string has to be provided. After initializing,
    /// it's possible to change additional parameters:
    /// ```
    ///     var config = Client.Config(apiKey: "<API_KEY>")
    ///     config.baseURL = .dublin
    ///     config.logOptions = [.debug]
    /// ```
    public struct Config {
        /// WebSocket provider type to be used in Client
        public enum WebSocketProviderType { //swiftlint:disable:this nesting
            case starscream
            
            @available(iOS 13, *)
            case native
        }
        
        /// A Stream Chat API key.
        public let apiKey: String
        /// A base URL (see `BaseURL`).
        public var baseURL: BaseURL = .usEast
        /// A request callback queue, default nil (some background thread).
        public var callbackQueue: DispatchQueue?
        /// When the app will go to the background, start a background task to stay connected for 5 min.
        public var stayConnectedInBackground: Bool = true
        /// A local database.
        public var database: Database?
        /// Enable logs (see `ClientLogger.Options`), e.g. `.all`.
        public var logOptions: ClientLogger.Options = []
        /// WebSocket provider type to be used in Client. Defaults to `.starscream`
        public var webSocketProviderType: WebSocketProviderType = .starscream
        /// Hook for providing `URLRequest` from `URL` for attachments.
        public var attachmentImageURLRequestPrepare: (URL) -> URLRequest = { url in
            URLRequest(url: url)
        }
        /// Hook for providing `URLRequest` from `URL` for avatar images.
        public var avatarImageURLRequestPrepare: (URL) -> URLRequest = { url in
            URLRequest(url: url)
        }

        /// Creates a new config object.
        ///
        /// - Parameter apiKey: A StreamChat API key for your app. You can find it in the Dashboard on
        ///   https://getstream.io after logging in.
        public init(apiKey: String) {
            ClientLogger.logAssert(!apiKey.isEmpty, "Empty string is not a valid apiKey.")
            self.apiKey = apiKey
        }
    }
}

// MARK: - Backward compatibility:

extension Client.Config {
    /// Init a config for the shared `Client`.
    /// - Parameters:
    ///     - apiKey: a Stream Chat API key.
    ///     - baseURL: a base URL (see `BaseURL`).
    ///     - stayConnectedInBackground: when the app will go to the background,
    ///                                  start a background task to stay connected for 5 min.
    ///     - database: a database manager.
    ///     - callbackQueue: a request callback queue, default nil (some background thread).
    ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
    ///     - webSocketProviderType: WebSocket provider to be used in Client. Defaults to `.starscream`
    public init(apiKey: String,
                baseURL: BaseURL = .usEast,
                stayConnectedInBackground: Bool = true,
                database: Database? = nil,
                callbackQueue: DispatchQueue? = nil,
                webSocketProviderType: WebSocketProviderType = .starscream,
                logOptions: ClientLogger.Options = []) {

        self = .init(apiKey: apiKey)
        self.baseURL = baseURL
        self.stayConnectedInBackground = stayConnectedInBackground
        self.database = database
        self.callbackQueue = callbackQueue
        self.logOptions = logOptions
        self.webSocketProviderType = webSocketProviderType
    }

    /// Init a config for the shared `Client`.
    ///
    /// - Parameters:
    ///     - apiKey: a Stream Chat API key.
    ///     - baseURL: a base URL.
    ///     - stayConnectedInBackground: when the app will go to the background,
    ///                                  start a background task to stay connected for 5 min.
    ///     - database: a database manager.
    ///     - callbackQueue: a request callback queue, default nil (some background thread).
    ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.info`
    ///     - webSocketProviderType: WebSocket provider to be used in Client. Defaults to `.starscream`
    public init(apiKey: String,
                baseURL: URL,
                stayConnectedInBackground: Bool = true,
                database: Database? = nil,
                callbackQueue: DispatchQueue? = nil,
                webSocketProviderType: WebSocketProviderType = .starscream,
                logOptions: ClientLogger.Options = []) {
        self.init(apiKey: apiKey,
                  baseURL: .init(url: baseURL),
                  stayConnectedInBackground: stayConnectedInBackground,
                  database: database,
                  callbackQueue: callbackQueue,
                  webSocketProviderType: webSocketProviderType,
                  logOptions: logOptions)
    }

    /// Init a config for the shared `Client`.
    ///
    /// - Parameters:
    ///     - apiKey: a Stream Chat API key.
    ///     - baseURL: a base URL string.
    ///     - stayConnectedInBackground: when the app will go to the background,
    ///                                  start a background task to stay connected for 5 min
    ///     - database: a database manager.
    ///     - callbackQueue: a request callback queue, default nil (some background thread).
    ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
    ///     - webSocketProviderType: WebSocket provider to be used in Client. Defaults to `.starscream`
    public init?(apiKey: String,
                 baseURL: String,
                 stayConnectedInBackground: Bool = true,
                 database: Database? = nil,
                 callbackQueue: DispatchQueue? = nil,
                 webSocketProviderType: WebSocketProviderType = .starscream,
                 logOptions: ClientLogger.Options = []) {
        guard let url = URL(string: baseURL) else { return nil }

        self.init(apiKey: apiKey,
                  baseURL: .init(url: url),
                  stayConnectedInBackground: stayConnectedInBackground,
                  database: database,
                  callbackQueue: callbackQueue,
                  webSocketProviderType: webSocketProviderType,
                  logOptions: logOptions)
    }

}

extension Client.Config: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.apiKey == rhs.apiKey
            && lhs.baseURL == rhs.baseURL
            && lhs.callbackQueue == rhs.callbackQueue
            && lhs.database?.user == rhs.database?.user
            && lhs.logOptions == rhs.logOptions
            && lhs.stayConnectedInBackground == rhs.stayConnectedInBackground
    }
}
