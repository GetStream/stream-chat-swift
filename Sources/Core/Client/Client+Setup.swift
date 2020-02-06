//
//  Client+Setup.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

// MARK: - Setup

extension Client {
    
    /// Setup the current user with a given token.
    ///
    /// - Parameters:
    ///     - user: the current user (see `User`).
    ///     - token: a Stream Chat API token.
    public func set(user: User, token: Token) {
        disconnect()
        
        if apiKey.isEmpty || token.isEmpty {
            logger?.log("❌ API key or token is empty: \(apiKey), \(token)", level: .error)
            return
        }
        
        self.user = user
        setup(token: token)
    }
    
    /// Setup the current user with a token provider (see `TokenProvider`).
    ///
    /// A token provider is a function in which you send a request to your own backend to get a Stream Chat API token.
    /// Then you send it to the client to complete the setup with a callback function from the token provider.
    ///
    /// Example:
    /// ```
    /// Client.shared.set(user: user) { callback in
    ///    if let url = URL(string: "https://my.backend.io/token?user_id=\(user.id)") {
    ///        let task = URLSession.shared.dataTask(with: url) { data, response, error in
    ///            if error == nil,
    ///                let json = try? JSONSerialization.jsonObject(with: data),
    ///                let token = json["token"] as? String {
    ///                callback(token)
    ///            } else {
    ///                // Handle the error.
    ///                print("Token request failed", error)
    ///            }
    ///        }
    ///
    ///        task.resume()
    ///    }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - user: the current user (see `User`).
    ///   - tokenProvider: a token provider.
    public func set(user: User, _ tokenProvider: @escaping TokenProvider) {
        disconnect()
        
        if apiKey.isEmpty {
            logger?.log("❌ API key is empty.", level: .error)
            return
        }
        
        self.user = user
        self.tokenProvider = tokenProvider
        touchTokenProvider()
    }
    
    @discardableResult
    func touchTokenProvider() -> Bool {
        guard let tokenProvider = tokenProvider else {
            return false
        }
        
        if webSocket.isConnected {
            webSocket.disconnect()
        }
        
        expiredTokenDisposeBag = DisposeBag()
        isExpiredTokenInProgress = true
        logger?.log("🀄️ Request for a new token from a token provider.")
        tokenProvider { [unowned self] in self.setup(token: $0) }
        
        return true
    }
    
    private func setup(token: Token) {
        if webSocket.isConnected {
            webSocket.disconnect()
        }
        
        self.token = nil
        
        if token.isEmpty {
            logger?.log("❌ Token is empty.", level: .error)
            return
        }
        
        guard let user = user else {
            logger?.log("❌ User is empty. Skip Token setup.", level: .error)
            return
        }
        
        if token == .guest {
            requestGuestToken()
            return
        }
        
        var token = token
        
        if token == .development {
            if let developmentToken = developmentToken() {
                token = developmentToken
            } else {
                return
            }
        }
        
        if logOptions.isEnabled {
            ClientLogger.logger("👤", "", "\(user.name): \(user.id)")
            ClientLogger.logger("🀄️", "", "Token: \(token)")
        }
        
        if let error = checkUserAndToken(token) {
            logger?.log(error)
            return
        }
        
        guard let webSocket = setupWebSocket(user: user, token: token) else {
            return
        }
        
        database?.user = user
        self.webSocket = webSocket
        urlSession = setupURLSession(token: token)
        self.token = token
    }
    
    private func requestGuestToken() {
        guard let user = user else {
            return
        }
        
        logger?.log("Sending a request for a Guest Token...")
        
        request(endpoint: .guestToken(user)) { [unowned self] (result: Result<TokenResponse, ClientError>) in
            if let response = try? result.get() {
                self.set(user: response.user, token: response.token)
            } else {
                self.logger?.log(result.error, message: "Guest Token")
            }
        }
    }
    
    private func developmentToken() -> Token? {
        guard let user = user,
            let json = try? JSONSerialization.data(withJSONObject: ["user_id": user.id]) else {
                return nil
        }
        
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\(json.base64EncodedString()).devtoken" // {"alg": "HS256", "typ": "JWT"}
    }
    
    private func checkUserAndToken(_ token: Token) -> ClientError? {
        guard let user = user else {
            return ClientError.emptyUser
        }
        
        guard token.isValidToken(userId: user.id), let payload = token.payload else {
            return ClientError.tokenInvalid(description: "Token is invalid or Token payload is invalid")
        }
        
        if let userId = payload["user_id"] as? String, userId == user.id {
            return nil
        }
        
        return ClientError.tokenInvalid(description: "Token payload user_id doesn't equal to the client user id")
    }
}

// MARK: - Connection

extension Client {
    func createObservableConnection() -> Observable<WebSocket.Connection> {
        if let token = token, let error = checkUserAndToken(token) {
            return .error(error)
        }
        
        let app = UIApplication.shared
        
        let appState = isTests()
            ? .just(.active)
            : app.rx.appState
                .filter { $0 != .inactive }
                .distinctUntilChanged()
                .startWith(app.appState)
                .do(onNext: { state in
                    if Client.shared.logOptions.isEnabled {
                        ClientLogger.log("📱", "App state \(state)")
                    }
                })
        
        let internetIsAvailable: Observable<Bool> = isTests()
            ? .just(true)
            : InternetConnection.shared.isAvailableObservable
        
        let webSocketResponse = internetIsAvailable
            .filter({ $0 })
            .flatMapLatest { [unowned self]  _ in self.tokenSubject.asObserver() }
            .distinctUntilChanged()
            .map { $0?.isValidToken() ?? false }
            .observeOn(MainScheduler.instance)
            .flatMapLatest({ [unowned self] isTokenValid -> Observable<WebSocketEvent> in
                if isTokenValid {
                    self.webSocket.connect()
                    return self.webSocket.webSocket.rx.response
                }
                
                return .just(.disconnected(nil))
            })
            .do(onDispose: { [unowned self] in self.webSocket.disconnect() })
        
        return Observable.combineLatest(appState, internetIsAvailable, webSocketResponse)
            .compactMap { [unowned self] in self.webSocket.parseConnection(appState: $0, isInternetAvailable: $1, event: $2) }
            .distinctUntilChanged()
            .do(onNext: { [unowned self] in
                if case .connected(_, let user) = $0 {
                    self.user = user
                }
            })
            .share(replay: 1)
    }
    
    func connectedRequest<T: Decodable>(_ endpoint: Endpoint) -> Observable<T> {
        let request: Observable<T> = rx.request(endpoint: endpoint)
        return connectedRequest(request)
    }
    
    func connectedRequest<T>(_ request: Observable<T>) -> Observable<T> {
        return webSocket.isConnected ? request : connection.connected().take(1).flatMapLatest { request }
    }
}
