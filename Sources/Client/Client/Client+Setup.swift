//
//  Client+Setup.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Setup

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
    
    /// Setup the current user as guest.
    ///
    /// Guest sessions do not require any server-side authentication.
    /// Guest users have a limited set of permissions.
    public func setGuestUser(_ user: User) {
        if apiKey.isEmpty {
            logger?.log("❌ API key is empty", level: .error)
            return
        }
        
        disconnect()
        self.user = user
        urlSession = setupURLSession()
        logger?.log("Sending a request for a Guest Token...")
        
        request(endpoint: .guestToken(user)) { [unowned self] (result: Result<TokenResponse, ClientError>) in
            if let response = try? result.get() {
                self.set(user: response.user, token: response.token)
            } else {
                self.logger?.log(result.error, message: "Guest Token")
            }
        }
    }
    
    /// Setup the current user as anonymous.
    ///
    /// If a user is not logged in, you can call the setAnonymousUser method.
    /// While you’re anonymous, you can’t do much, but for the livestream channel type,
    /// you’re still allowed to read the chat conversation.
    public func setAnonymousUser() {
        user = .anonymous
        tokenProvider = nil
        setup(token: "")
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
        touchTokenProvider(isExpiredTokenInProgress: false)
    }
    
    @discardableResult
    func touchTokenProvider(isExpiredTokenInProgress: Bool) -> Bool {
        guard let tokenProvider = tokenProvider else {
            return false
        }
        
        self.isExpiredTokenInProgress = isExpiredTokenInProgress
        
        if webSocket.isConnected {
            webSocket.disconnect()
        }
        
        logger?.log("🀄️ Request for a new token from a token provider.")
        tokenProvider(setup)
        
        return true
    }
    
    private func setup(token: Token) {
        if webSocket.isConnected {
            webSocket.disconnect()
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
            ClientLogger.logger(user.isAnonymous ? "👺" : "👤", "", user.isAnonymous ? "Anonymous" : "\(user.name): \(user.id)")
            
            if !user.isAnonymous {
                ClientLogger.logger("🀄️", "", "Token: \(token)")
            }
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
        
        if isExpiredTokenInProgress {
            connect()
        }
    }
    
    private func developmentToken() -> Token? {
        guard let json = try? JSONSerialization.data(withJSONObject: ["user_id": user.id]) else {
            return nil
        }
        
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\(json.base64EncodedString()).devtoken" // {"alg": "HS256", "typ": "JWT"}
    }
    
    private func checkUserAndToken(_ token: Token) -> ClientError? {
        if user.isAnonymous, token.isEmpty {
            return nil
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
