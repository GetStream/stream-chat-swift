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
        /// - Parameters:
        ///     - apiKey: a Stream Chat API key.
        ///     - baseURL: a base URL (see `BaseURL`).
        ///     - stayConnectedInBackground: when the app will go to the background,
        ///                                  start a background task to stay connected for 5 min.
        ///     - database: a database manager.
        ///     - callbackQueue: a request callback queue, default nil (some background thread).
        ///     - logOptions: enable logs (see `ClientLogger.Options`), e.g. `.all`
        public init(apiKey: String,
                    baseURL: BaseURL = .usEast,
                    stayConnectedInBackground: Bool = true,
                    database: Database? = nil,
                    callbackQueue: DispatchQueue? = nil,
                    logOptions: ClientLogger.Options = []) {
            self.apiKey = apiKey
            self.baseURL = baseURL
            self.stayConnectedInBackground = stayConnectedInBackground
            self.database = database
            self.callbackQueue = callbackQueue
            self.logOptions = logOptions
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
        public init(apiKey: String,
                    baseURL: URL,
                    stayConnectedInBackground: Bool = true,
                    database: Database? = nil,
                    callbackQueue: DispatchQueue? = nil,
                    logOptions: ClientLogger.Options = []) {
            self.init(apiKey: apiKey,
                      baseURL: .init(url: baseURL),
                      stayConnectedInBackground: stayConnectedInBackground,
                      database: database,
                      callbackQueue: callbackQueue,
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
        public init?(apiKey: String,
                     baseURL: String,
                     stayConnectedInBackground: Bool = true,
                     database: Database? = nil,
                     callbackQueue: DispatchQueue? = nil,
                     logOptions: ClientLogger.Options = []) {
            guard let url = URL(string: baseURL) else { return nil }
            
            self.init(apiKey: apiKey,
                      baseURL: .init(url: url),
                      stayConnectedInBackground: stayConnectedInBackground,
                      database: database,
                      callbackQueue: callbackQueue,
                      logOptions: logOptions)
        }
    }
}
