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
        /// A list of reaction types.
        public let reactionTypes: [ReactionType]
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
                    reactionTypes: [ReactionType] = ReactionType.defaultTypes,
                    stayConnectedInBackground: Bool = true,
                    database: Database? = nil,
                    logOptions: ClientLogger.Options = []) {
            self.apiKey = apiKey
            self.baseURL = baseURL
            self.callbackQueue = callbackQueue
            self.reactionTypes = reactionTypes
            self.stayConnectedInBackground = stayConnectedInBackground
            self.database = database
            self.logOptions = logOptions
        }
    }
}
