//
//  Client+Setup.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: Setup

extension Client {
    
    /// Setup the current user with a given token.
    ///
    /// - Parameters:
    ///   - user: the current user (see `User`).
    ///   - token: a Stream Chat API token.
    ///   - completion: a connection completion block.
    public func set(user: User, token: Token, _ completion: @escaping Client.OnConnected) {
        reset()
        
        if apiKey.isEmpty || token.isEmpty {
            logger?.log("❌ API key or token is empty: \(apiKey), \(token)", level: .error)
            completion(ClientError.emptyAPIKey)
            return
        }
        
        self.user = user
        setup(token: token, completion)
    }
    
    /// Setup the current user as guest.
    ///
    /// Guest sessions do not require any server-side authentication.
    /// Guest users have a limited set of permissions.
    /// - Parameters:
    ///   - user: a guest user.
    ///   - completion: a connection completion block.
    public func setGuestUser(_ user: User, _ completion: @escaping Client.OnConnected) {
        reset()
        
        if apiKey.isEmpty {
            logger?.log("❌ API key is empty", level: .error)
            completion(ClientError.emptyAPIKey)
            return
        }
        
        self.user = user
        urlSession = setupURLSession()
        logger?.log("Sending a request for a Guest Token...")
        
        request(endpoint: .guestToken(user)) { [unowned self] (result: Result<TokenResponse, ClientError>) in
            do {
                let response = try result.get()
                self.set(user: response.user, token: response.token, completion)
            } catch {
                self.logger?.log(error, message: "Guest Token")
                completion(error)
            }
        }
    }
    
    /// Setup the current user as anonymous.
    ///
    /// If a user is not logged in, you can call the setAnonymousUser method.
    /// While you’re anonymous, you can’t do much, but for the livestream channel type,
    /// you’re still allowed to read the chat conversation.
    /// - Parameter completion: a connection completion block.
    public func setAnonymousUser(_ completion: @escaping Client.OnConnected) {
        reset()
        user = .anonymous
        tokenProvider = nil
        setup(token: "", completion)
    }
    
    /// Setup the current user with a token provider (see `TokenProvider`).
    ///
    /// A token provider is a function in which you send a request to your own backend to get a Stream Chat API token.
    /// Then you send it to the client to complete the setup with a callback function from the token provider.
    ///
    /// Example:
    /// ```
    /// let tokenProvider: TokenProvider = { tokenCallback in
    ///     guard let url = URL(string: "https://my.backend.io/token?user_id=\(user.id)") else {
    ///         return
    ///     }
    ///
    ///     let task = URLSession.shared.dataTask(with: url) { data, response, error in
    ///         if error == nil,
    ///             let json = try? JSONSerialization.jsonObject(with: data),
    ///             let token = json["token"] as? String {
    ///             tokenCallback(token)
    ///         } else {
    ///             // Handle the error.
    ///             print("Token request failed", error)
    ///         }
    ///     }
    ///
    ///     task.resume()
    /// }
    ///
    /// Client.shared.set(user: user, tokenProvider: tokenProvider) {
    ///     // The client is connected.
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - user: the current user (see `User`).
    ///   - tokenProvider: a token provider.
    ///   - completion: a connection completion block.
    public func set(user: User, tokenProvider: @escaping TokenProvider, _ completion: @escaping Client.OnConnected) {
        reset()
        
        if apiKey.isEmpty {
            logger?.log("❌ API key is empty.", level: .error)
            completion(ClientError.emptyAPIKey)
            return
        }
        
        self.user = user
        self.tokenProvider = tokenProvider
        touchTokenProvider(isExpiredTokenInProgress: false, completion)
    }
    
    func touchTokenProvider(isExpiredTokenInProgress: Bool, _ completion: Client.OnConnected?) {
        guard let tokenProvider = tokenProvider else {
            return
        }
        
        self.isExpiredTokenInProgress = isExpiredTokenInProgress
        
        if webSocket.isConnected {
            webSocket.disconnect()
        }
        
        logger?.log("🀄️ Request for a new token from a token provider.")
        tokenProvider { [unowned self] in self.setup(token: $0, completion) }
    }
    
    private func setup(token: Token, _ completion: Client.OnConnected?) {
        if webSocket.isConnected {
            webSocket.disconnect()
        }
        
        var token = token
        
        if token == .development {
            do {
                token = try developmentToken()
            } catch {
                completion?(error)
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
            completion?(error)
            return
        }
        
        do {
            let webSocket = try setupWebSocket(user: user, token: token)
            database?.user = user
            self.webSocket = webSocket
            urlSession = setupURLSession(token: token)
            self.token = token
            
            let onConnect: OnConnect = {
                if $0.isConnected {
                    completion?(nil)
                } else if case .disconnected(let disconnectedError) = $0, let error = disconnectedError {
                    completion?(error)
                }
            }
            
            InternetConnection.shared.startObserving()
            
            InternetConnection.shared.onStateChanged = { [unowned self] state in
                self.connect(internetConnectionState: state, onConnect)
            }
            
            UIApplication.shared.onStateChanged = { [unowned self] state in
                self.connect(appState: state, onConnect)
            }
        } catch {
            logger?.log(error)
            completion?(error)
        }
    }
    
    private func developmentToken() throws -> Token {
        let json = try JSONSerialization.data(withJSONObject: ["user_id": user.id])
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\(json.base64EncodedString()).devtoken" // {"alg": "HS256", "typ": "JWT"}
    }
    
    private func checkUserAndToken(_ token: Token) -> ClientError? {
        if user.isAnonymous, token.isEmpty {
            return nil
        }
        
        guard token.isValidToken(userId: user.id), let payload = token.payload else {
            return ClientError.invalidToken(description: "Token is invalid or Token payload is invalid")
        }
        
        if let userId = payload["user_id"] as? String, userId == user.id {
            return nil
        }
        
        return ClientError.invalidToken(description: "Token payload user_id doesn't equal to the client user id")
    }
}
