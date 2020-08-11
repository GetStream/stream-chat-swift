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
    public func set(user: User, token: Token, _ completion: Client.Completion<UserConnection>? = nil) {
        reset()
        
        if apiKey.isEmpty || token.isEmpty {
            logger?.log("❌ API key or token is empty: \(apiKey), \(token)", level: .error)
            completion?(.failure(.emptyAPIKey))
            return
        }
        
        userAtomic.set(user)
        setup(token: token, completion)
    }
    
    /// Setup the current user as guest.
    ///
    /// Guest sessions do not require any server-side authentication.
    /// Guest users have a limited set of permissions.
    /// - Parameters:
    ///   - user: a guest user.
    ///   - completion: a connection completion block.
    public func setGuestUser(_ user: User, _ completion: Client.Completion<UserConnection>? = nil) {
        reset()
        
        if apiKey.isEmpty {
            logger?.log("❌ API key is empty", level: .error)
            completion?(.failure(.emptyAPIKey))
            return
        }
        
        userAtomic.set(user)
        urlSession = makeURLSession()
        logger?.log("Sending a request for a Guest Token...")
        
        request(endpoint: .guestToken(user)) { [unowned self] (result: Result<TokenResponse, ClientError>) in
            if let response = result.value {
                self.set(user: response.user, token: response.token, completion)
            } else if let error = result.error {
                self.logger?.log(error, message: "Guest Token")
                completion?(.failure(error))
            }
        }
    }
    
    /// Setup the current user as anonymous.
    ///
    /// If a user is not logged in, you can call the setAnonymousUser method.
    /// While you’re anonymous, you can’t do much, but for the livestream channel type,
    /// you’re still allowed to read the chat conversation.
    /// - Parameter completion: a connection completion block.
    public func setAnonymousUser(_ completion: Client.Completion<UserConnection>? = nil) {
        reset()
        userAtomic.set(.anonymous)
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
    ///             disconnect()
    ///         }
    ///     }
    ///
    ///     task.resume()
    /// }
    ///
    /// Client.shared.set(user: user, tokenProvider: tokenProvider) { result in
    ///     do {
    ///         let userConnection = try result.get()
    ///         // Print the current user.
    ///         print(userConnection.user)
    ///     } catch {
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - user: the current user (see `User`).
    ///   - tokenProvider: a token provider.
    ///   - completion: a connection completion block.
    public func set(user: User, tokenProvider: @escaping TokenProvider, completion: Client.Completion<UserConnection>? = nil) {
        reset()
        
        if apiKey.isEmpty {
            logger?.log("❌ API key is empty.", level: .error)
            completion?(.failure(.emptyAPIKey))
            return
        }
        
        userAtomic.set(user)
        self.tokenProvider = tokenProvider
        touchTokenProvider(isExpiredTokenInProgress: false, completion)
    }
    
    func touchTokenProvider(isExpiredTokenInProgress: Bool, _ completion: Client.Completion<UserConnection>?) {
        guard let tokenProvider = tokenProvider else {
            return
        }
        
        self.isExpiredTokenInProgress = isExpiredTokenInProgress
        
        if webSocket.isConnected {
            webSocket.disconnect(reason: "Updating Token with a token provider")
        }
        
        logger?.log("🀄️ Request for a new token from a token provider.")
        tokenProvider { [unowned self] in self.setup(token: $0, completion) }
    }
    
    private func setup(token: Token, _ completion: Client.Completion<UserConnection>?) {
        if webSocket.isConnected {
            webSocket.disconnect(reason: "Requesting new token")
        }
        
        var token = token
        
        if token == .development {
            do {
                token = try developmentToken()
            } catch {
                completion?(.failure(.encodingFailure(error, object: ["jwt": ["user_id": user.id]])))
                return
            }
        }
        
        if logOptions.isEnabled {
            ClientLogger.log(user.isAnonymous ? "👺" : "👤", "", .info, user.isAnonymous ? "Anonymous" : "\(user.name): \(user.id)")
            
            if !user.isAnonymous {
                ClientLogger.log("🀄️", "", .info, "Token: \(token)")
            }
        }
        
        if let error = checkUserAndToken(token) {
            logger?.log(error)
            completion?(.failure(error))
            return
        }
        
        // Switch completion block to the main thread.
        let completion = completion == nil ? nil : { result in DispatchQueue.main.async { completion?(result) } }
        
        do {
            webSocket.request = try makeWebSocketRequest(user: user, token: token)
            urlSession = makeURLSession(token: token)
            self.token = token
            
            if let completion = completion {
                var subscription: Cancellable?
                
                subscription = subscribe(forEvents: [.connectionChanged]) { event in
                    if case .connectionChanged(let state) = event {
                        if case .connected(let userConnection) = state {
                            completion(.success(userConnection))
                            subscription?.cancel()
                        }
                        
                        if case .disconnected(let error) = state, let clientError = error {
                            completion(.failure(clientError))
                        }
                    }
                }
            }
            
            // Observe Application state and handle the Client connection.
            Application.shared.onStateChanged = { [unowned self] state in self.connect(appState: state) }
            // Observe Internet connection state and handle the Client connection.
            InternetConnection.shared.onStateChanged = { [unowned self] state in self.connect(internetConnectionState: state) }
            // Start observing Internet connection state and get the current state.
            InternetConnection.shared.startNotifier()
            
        } catch {
            logger?.log(error)
            completion?(.failure(.unexpectedError(description: error.localizedDescription, error: error)))
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
