//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

class ConnectionRepository {
    private let connectionQueue: DispatchQueue = DispatchQueue(label: "io.getstream.connection-repository", attributes: .concurrent)
    private var _connectionIdWaiters: [String: (Result<ConnectionId, Error>) -> Void] = [:]
    private var _connectionId: ConnectionId?
    private var _connectionStatus: ConnectionStatus = .initialized

    private(set) var connectionIdWaiters: [String: (Result<ConnectionId, Error>) -> Void] {
        get { connectionQueue.sync { _connectionIdWaiters } }
        set { connectionQueue.async(flags: .barrier) { self._connectionIdWaiters = newValue }}
    }

    /// The current connection status of the client
    private(set) var connectionStatus: ConnectionStatus {
        get { connectionQueue.sync { _connectionStatus } }
        set { connectionQueue.async(flags: .barrier) { self._connectionStatus = newValue }}
    }

    /// The current connection id
    private(set) var connectionId: ConnectionId? {
        get { connectionQueue.sync { _connectionId } }
        set { connectionQueue.async(flags: .barrier) { self._connectionId = newValue }}
    }

    let isClientInActiveMode: Bool
    private let syncRepository: SyncRepository
    private let webSocketClient: WebSocketClient?
    private let apiClient: APIClient
    private let timerType: Timer.Type

    init(
        isClientInActiveMode: Bool,
        syncRepository: SyncRepository,
        webSocketClient: WebSocketClient?,
        apiClient: APIClient,
        timerType: Timer.Type
    ) {
        self.isClientInActiveMode = isClientInActiveMode
        self.syncRepository = syncRepository
        self.webSocketClient = webSocketClient
        self.apiClient = apiClient
        self.timerType = timerType
    }

    /// Connects the chat client the controller represents to the chat servers.
    ///
    /// When the connection is established, `ChatClient` starts receiving chat updates, and `currentUser` variable is available.
    ///
    /// - Parameters:
    ///   - completion: Called when the connection is established. If the connection fails, the completion is called with an error.
    ///
    func connect(completion: ((Error?) -> Void)? = nil) {
        // Connecting is not possible in connectionless mode (duh)
        guard isClientInActiveMode else {
            completion?(ClientError.ClientIsNotInActiveMode())
            return
        }

        guard connectionId == nil else {
            log.warning("The client is already connected. Skipping the `connect` call.")
            completion?(nil)
            return
        }

        // Set up a waiter for the new connection id to know when the connection process is finished
        provideConnectionId { [weak webSocketClient] result in
            switch result {
            case .success:
                completion?(nil)
            case .failure:
                // Try to get a concrete error
                if case let .disconnected(source) = webSocketClient?.connectionState {
                    completion?(ClientError.ConnectionNotSuccessful(with: source.serverError))
                } else {
                    completion?(ClientError.ConnectionNotSuccessful())
                }
            }
        }
        webSocketClient?.connect()
    }

    /// Disconnects the chat client the controller represents from the chat servers. No further updates from the servers
    /// are received.
    func disconnect(
        source: WebSocketConnectionState.DisconnectionSource,
        completion: @escaping () -> Void
    ) {
        apiClient.flushRequestsQueue()
        syncRepository.cancelRecoveryFlow()

        // Disconnecting is not possible in connectionless mode (duh)
        guard isClientInActiveMode else {
            log.error(ClientError.ClientIsNotInActiveMode().localizedDescription)
            completion()
            return
        }

        if connectionId == nil {
            if source == .userInitiated {
                log.warning("The client is already disconnected. Skipping the `disconnect` call.")
            }
            completion()
            return
        }

        // Disconnect the web socket
        webSocketClient?.disconnect(source: source) { [weak self] in
            // Reset `connectionId`. This would happen asynchronously by the callback from WebSocketClient anyway, but it's
            // safer to do it here synchronously to immediately stop all API calls.
            self?.connectionId = nil

            // Remove all waiters for connectionId
            self?.completeConnectionIdWaiters(connectionId: nil)

            completion()
        }
    }

    /// Updates the WebSocket endpoint to use the passed token and user information for the connection
    func updateWebSocketEndpoint(with token: Token, userInfo: UserInfo?) {
        webSocketClient?.connectEndpoint = .webSocketConnect(userInfo: userInfo ?? .init(id: token.userId))
    }

    /// Updates the WebSocket endpoint to use the passed user id
    func updateWebSocketEndpoint(with currentUserId: UserId) {
        webSocketClient?.connectEndpoint = .webSocketConnect(userInfo: UserInfo(id: currentUserId))
    }

    func handleConnectionUpdate(
        state: WebSocketConnectionState,
        onInvalidToken: () -> Void
    ) {
        connectionStatus = .init(webSocketConnectionState: state)

        // We should notify waiters if connectionId was obtained (i.e. state is .connected)
        // or for .disconnected state except for disconnect caused by an expired token
        let shouldNotifyConnectionIdWaiters: Bool
        let connectionId: String?
        switch state {
        case let .connected(connectionId: id):
            shouldNotifyConnectionIdWaiters = true
            connectionId = id

        case let .disconnecting(source) where source.serverError?.isInvalidTokenError == true,
             let .disconnected(source) where source.serverError?.isInvalidTokenError == true:
            onInvalidToken()
            shouldNotifyConnectionIdWaiters = false
            connectionId = nil
        case .disconnected:
            shouldNotifyConnectionIdWaiters = true
            connectionId = nil
        case .initialized,
             .connecting,
             .disconnecting,
             .waitingForConnectionId:
            shouldNotifyConnectionIdWaiters = false
            connectionId = nil
        }

        updateConnectionId(
            connectionId: connectionId,
            shouldNotifyWaiters: shouldNotifyConnectionIdWaiters
        )
    }

    func provideConnectionId(timeout: TimeInterval = 10, completion: @escaping (Result<ConnectionId, Error>) -> Void) {
        if let connectionId = connectionId {
            completion(.success(connectionId))
            return
        } else if !isClientInActiveMode {
            // We're in passive mode
            // We will never have connectionId
            completion(.failure(ClientError.ClientIsNotInActiveMode()))
            return
        }

        let waiterToken = String.newUniqueId
        connectionIdWaiters[waiterToken] = completion

        let globalQueue = DispatchQueue.global()
        timerType.schedule(timeInterval: timeout, queue: globalQueue) { [weak self] in
            guard let self = self else { return }

            // Not the nicest, but we need to ensure the read and write below are treated as an atomic operation,
            // in a queue that is concurrent, whilst the completion needs to be called outside of the barrier'ed operation.
            // If we call the block as part of the barrier'ed operation, and by any chance this ends up synchronously
            // calling any queue protected property in this class before the operation is completed, we can potentially crash the app.
            self.connectionQueue.async(flags: .barrier) {
                guard let completion = self._connectionIdWaiters[waiterToken] else { return }

                globalQueue.async {
                    completion(.failure(ClientError.WaiterTimeout()))
                }

                self._connectionIdWaiters[waiterToken] = nil
            }
        }
    }

    func completeConnectionIdWaiters(connectionId: String?) {
        updateConnectionId(connectionId: connectionId, shouldNotifyWaiters: true)
    }

    func forceConnectionStatusForInactiveModeIfNeeded() {
        guard !isClientInActiveMode else { return }
        connectionStatus = .disconnected(error: nil)
    }

    /// Update connectionId and notify waiters if needed
    /// - Parameters:
    ///   - connectionId: new connectionId (if present)
    ///   - shouldFailWaiters: Whether it's necessary to notify waiters or not
    private func updateConnectionId(
        connectionId: String?,
        shouldNotifyWaiters: Bool
    ) {
        let waiters: [String: (Result<ConnectionId, Error>) -> Void] = connectionQueue.sync {
            _connectionId = connectionId
            guard shouldNotifyWaiters else { return [:] }
            let waiters = _connectionIdWaiters
            _connectionIdWaiters = [:]
            return waiters
        }

        waiters.forEach { waiter in
            if let connectionId = connectionId {
                waiter.value(.success(connectionId))
            } else {
                waiter.value(.failure(ClientError.MissingConnectionId()))
            }
        }
    }

    private func invalidateConnectionIdWaiter(_ waiter: WaiterToken) {
        connectionIdWaiters[waiter] = nil
    }
}
