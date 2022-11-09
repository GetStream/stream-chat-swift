//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class ConnectionRepository {
    private let connectionQueue: DispatchQueue = DispatchQueue(label: "io.getstream.connection-repository", attributes: .concurrent)
    private var _connectionIdWaiters: [String: (String?) -> Void] = [:]
    private var _connectionId: ConnectionId?

    private var connectionIdWaiters: [String: (String?) -> Void] {
        get { connectionQueue.sync { _connectionIdWaiters } }
        set { connectionQueue.async(flags: .barrier) { self._connectionIdWaiters = newValue }}
    }

    /// The current connection id
    private(set) var connectionId: ConnectionId? {
        get { connectionQueue.sync { _connectionId } }
        set { connectionQueue.async(flags: .barrier) { self._connectionId = newValue }}
    }

    private let isClientInActiveMode: Bool
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
    /// - Parameter completion: Called when the connection is established. If the connection fails, the completion is
    /// called with an error.
    ///
    func connect(
        userInfo: UserInfo? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
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
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
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
        let completion = timerType.addTimeout(timeout, to: completion, noValueError: ClientError.MissingConnectionId()) { [weak self] in
            self?.invalidateConnectionIdWaiter(waiterToken)
        }

        connectionIdWaiters[waiterToken] = completion
    }

    func completeConnectionIdWaiters(connectionId: String?) {
        connectionQueue.sync {
            _connectionIdWaiters.forEach { $0.value(connectionId) }
            _connectionIdWaiters = [:]
        }
    }

    func invalidateConnectionIdWaiter(_ waiter: WaiterToken) {
        connectionIdWaiters[waiter] = nil
    }
}

extension Timer {
    static func addTimeout<T>(
        _ timeout: TimeInterval,
        to block: @escaping (Result<T, Error>) -> Void,
        noValueError: Error,
        onTimeout: @escaping () -> Void
    ) -> (T?) -> Void {
        var timer: TimerControl?
        let completionCancellingTimer: (Result<T, Error>) -> Void = { result in
            timer?.cancel()
            block(result)
        }

        timer = schedule(timeInterval: timeout, queue: .global()) {
            onTimeout()
            completionCancellingTimer(.failure(ClientError.WaiterTimeout()))
        }

        return { value in
            if let value = value {
                completionCancellingTimer(.success(value))
            } else {
                completionCancellingTimer(.failure(noValueError))
            }
        }
    }
}
