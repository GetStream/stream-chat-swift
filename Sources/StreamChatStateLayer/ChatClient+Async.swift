//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat

@available(iOS 13.0, *)
extension ChatClient {
    /// Connects the client with the given user.
    ///
    /// - Parameters:
    ///   - userInfo: The user info passed to `connect` endpoint.
    ///   - tokenProvider: The closure used to retreive a token. Token provider will be used to establish the initial connection and also to obtain the new token when the previous one expires.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: A type representing the connected user and its state.
    @discardableResult public func connectUser(
        userInfo: UserInfo,
        tokenProvider: @escaping TokenProvider
    ) async throws -> ConnectedUser {
        try await withCheckedThrowingContinuation { continuation in
            connectUser(userInfo: userInfo, tokenProvider: tokenProvider) { error in
                continuation.resume(with: error)
            }
        }
        return try await makeConnectedUser()
    }
    
    /// Connects the client with the given user.
    ///
    /// - Note: Connect endpoint uses an upsert mechanism. If the user does not exist, it will be created with the given `userInfo`. If user already exists, it will get updated with non-nil fields from the `userInfo`.
    /// - Important: This method can only be used when `token` does not expire. If the token expires, the `connect` API with token provider has to be used.
    ///
    /// - Parameters:
    ///   - userInfo: User info that is passed to the `connect` endpoint for user creation
    ///   - token: Authorization token for the user.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: A type representing the connected user and its state.
    @available(iOS 13.0, *)
    @discardableResult public func connectUser(
        userInfo: UserInfo,
        token: Token
    ) async throws -> ConnectedUser {
        try await withCheckedThrowingContinuation { continuation in
            connectUser(userInfo: userInfo, token: token) { error in
                continuation.resume(with: error)
            }
        }
        return try await makeConnectedUser()
    }
    
    /// Connects a guest user.
    ///
    /// - Parameters:
    ///   - userInfo: User info that is passed to the `connect` endpoint for user creation
    ///   - extraData: Extra data for user that is passed to the `connect` endpoint for user creation.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: A type representing the connected user and its state.
    @discardableResult public func connectGuestUser(userInfo: UserInfo) async throws -> ConnectedUser {
        try await withCheckedThrowingContinuation { continuation in
            connectGuestUser(userInfo: userInfo) { error in
                continuation.resume(with: error)
            }
        }
        return try await makeConnectedUser()
    }
    
    /// Connects an anonymous user.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: A type representing the connected user and its state.
    @discardableResult public func connectAnonymousUser() async throws -> ConnectedUser {
        try await withCheckedThrowingContinuation { continuation in
            connectAnonymousUser { error in
                continuation.resume(with: error)
            }
        }
        return try await makeConnectedUser()
    }
    
    /// Disconnects the chat client from the chat servers. No further updates from the servers
    /// are received.
    public func disconnect() async {
        await withCheckedContinuation { continuation in
            disconnect {
                continuation.resume()
            }
        }
    }
    
    /// Disconnects the chat client form the chat servers and removes all the local data related.
    public func logout() async {
        await withCheckedContinuation { continuation in
            logout {
                continuation.resume()
            }
        }
    }
    
    // MARK: - Listening for Client Events
    
    /// Subscribes to web-socket events of the specified event type.
    ///
    /// - Note: The handler is always called on the main thread.
    ///
    /// An example of observing connection status changes:
    /// ```swift
    /// client.subscribe(toEvent: ConnectionStatusUpdated.self) { connectionEvent in
    ///     switch connectionEvent.connectionStatus {
    ///         case .connected:
    ///           …
    ///     }
    /// }
    /// ```
    ///
    /// - SeeAlso: ``Chat.subscribe(toEvent:handler:)`` for subscribing to channel specific events.
    ///
    /// - Parameters:
    ///   - event: The event type to subscribe to (e.g. ``ConnectionStatusUpdated``).
    ///   - handler: The handler closure which is called when the event happens.
    ///
    /// - Returns: A cancellable instance, which you use when you end the subscription. Deallocation of the result will tear down the subscription stream.
    public func subscribe<E>(
        toEvent event: E.Type,
        handler: @escaping (E) -> Void
    ) -> AnyCancellable where E: Event {
        eventNotificationCenter.subscribe(to: E.self, handler: handler)
    }

    /// Subscribes to all the web-socket events.
    ///
    /// - SeeAlso: ``Chat.subscribe(handler:)`` for subscribing to channel specific events.
    ///
    /// - Parameter handler: The handler closure which is called when the event happens.
    ///
    /// - Returns: A cancellable instance, which you use when you end the subscription. Deallocation of the result will tear down the subscription stream.
    public func subscribe(_ handler: @escaping (Event) -> Void) -> AnyCancellable {
        eventNotificationCenter.subscribe(handler: handler)
    }
    
    // MARK: -
    
    /// Fetches the app settings and updates the ``ChatClient/appSettings``.
    ///
    /// - Returns: The latest state of app settings.
    public func loadAppSettings() async throws -> AppSettings {
        try await withCheckedThrowingContinuation { continuation in
            loadAppSettings(completion: continuation.resume(with:))
        }
    }
}
