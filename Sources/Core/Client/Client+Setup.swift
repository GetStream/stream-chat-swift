//
//  Client+Setup.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Setup

extension Client {
    
    /// Setup the current user with a given token.
    ///
    /// - Parameters:
    ///     - user: the current user (see `User`).
    ///     - token: a Stream Chat API token.
    public func set(user: User, token: Token) {
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
    public func set(user: User, _ tokenProvider: TokenProvider) {
        self.user = user
        tokenProvider { self.setup(token: $0) }
    }
    
    private func setup(token: Token) {
        guard let user = user else {
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
        
        urlSession = setupURLSession(token: token)
        webSocket = setupWebSocket(user: user, token: token)
        self.token = token
    }
    
    private func requestGuestToken() {
        guard let user = user else {
            return
        }
        
        request(endpoint: .guestToken(user)) { [weak self] (result: Result<TokenResponse, ClientError>) in
            if let response = try? result.get() {
                self?.set(user: response.user, token: response.token)
            } else {
                ClientLogger.log("🐴", result.error, message: "Guest Token")
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
}

// MARK: - Connection

extension Client {
    func createObservableConnection() -> Observable<WebSocket.Connection> {
        let app = UIApplication.shared
        
        let appState = app.rx.appState.startWith(app.appState)
            .do(onNext: { state in ClientLogger.log("📱", "App state \(state)") })
        
        let webSocketResponse = tokenSubject.asObserver()
            .distinctUntilChanged()
            .unwrap()
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] _ in self?.webSocket.connect() })
            .flatMap { [weak self] _ -> Observable<WebSocketEvent> in self?.webSocket.webSocket.rx.response ?? .empty() }
            .do(onDispose: { [weak self] in self?.webSocket.disconnect() })
        
        return Observable.combineLatest(appState, InternetConnection.shared.isAvailableObservable, webSocketResponse)
            .map { [weak self] in self?.webSocket.parseConnection(appState: $0, isInternetAvailable: $1, event: $2) }
            .unwrap()
            .distinctUntilChanged()
            .do(onNext: { [weak self] in
                if case .connected(_, let user) = $0 {
                    self?.user = user
                }
            })
            .share(replay: 1)
    }
    
    func connectedRequest<T>(_ request: Observable<T>) -> Observable<T> {
        return webSocket.isConnected ? request : connection.connected().take(1).flatMapLatest { request }
    }
}
