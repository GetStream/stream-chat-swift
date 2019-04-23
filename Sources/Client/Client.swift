//
//  Client.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias Token = String

public final class Client {
    public typealias Completion<T: Decodable> = (Result<T, ClientError>) -> Void
    
    public static var config = Config(apiKey: "")
    public static let shared = Client()

    let apiKey: String
    let baseURL: BaseURL
    var token: Token?
    private(set) lazy var webSocket: WebSocket? = setupWebSocket()
    private(set) lazy var urlSession: URLSession = setupURLSession()
    let callbackQueue: DispatchQueue?
    private let uuid = UUID()
    let logOptions: LogOptions
    let logger: ClientLogger?
    var user: User?
    
    public init(apiKey: String = Client.config.apiKey,
                baseURL: BaseURL = Client.config.baseURL,
                callbackQueue: DispatchQueue? = Client.config.callbackQueue,
                logOptions: LogOptions = Client.config.logOptions) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.callbackQueue = callbackQueue
        self.logOptions = logOptions
        
        if logOptions == .all || logOptions == .requests {
            logger = ClientLogger(icon: "🐴")
        } else {
            logger = nil
        }
    }
    
    public func set(user: User, token: Token) {
        self.user = user
        self.token = token
        webSocket?.connect()
    }
}

extension Client {
    public struct Config {
        public let apiKey: String
        public let baseURL: BaseURL
        public let callbackQueue: DispatchQueue?
        public let logOptions: LogOptions
        
        public init(apiKey: String,
                    baseURL: BaseURL = BaseURL(),
                    callbackQueue: DispatchQueue? = nil,
                    logOptions: LogOptions = .none) {
            self.apiKey = apiKey
            self.baseURL = baseURL
            self.callbackQueue = callbackQueue
            self.logOptions = logOptions
        }
    }
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }
}

extension Client {
    public enum LogOptions {
        case none
        case requests
        case webSocket
        case all
    }
}
