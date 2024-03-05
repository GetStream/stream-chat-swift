//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

/// Mock implementation of `ChatClientUpdater`
final class ConnectionRepository_Mock: ConnectionRepository, Spy {
    enum Signature {
        static let connect = "connect(completion:)"
        static let disconnect = "disconnect(source:completion:)"
        static let forceConnectionInactiveMode = "forceConnectionStatusForInactiveModeIfNeeded()"
        static let updateWebSocketEndpointTokenInfo = "updateWebSocketEndpoint(with:userInfo:)"
        static let updateWebSocketEndpointUserId = "updateWebSocketEndpoint(with:)"
        static let completeConnectionIdWaiters = "completeConnectionIdWaiters(connectionId:)"
        static let provideConnectionId = "provideConnectionId(timeout:completion:)"
        static let handleConnectionUpdate = "handleConnectionUpdate(state:onExpiredToken:)"
    }

    var recordedFunctions: [String] = []
    var connectResult: Result<Void, Error>?

    var disconnectSource: WebSocketConnectionState.DisconnectionSource?
    var disconnectResult: Result<Void, Error>?

    var updateWebSocketEndpointToken: Token?
    var updateWebSocketEndpointUserInfo: UserInfo?
    var completeWaitersConnectionId: ConnectionId?
    var connectionUpdateState: WebSocketConnectionState?
    var simulateExpiredTokenOnConnectionUpdate = false

    convenience init() {
        self.init(isClientInActiveMode: true,
                  syncRepository: SyncRepository_Mock(),
                  webSocketClient: WebSocketClient_Mock(),
                  apiClient: APIClient_Spy(),
                  timerType: DefaultTimer.self)
    }

    convenience init(client: ChatClient) {
        self.init(isClientInActiveMode: client.config.isClientInActiveMode,
                  syncRepository: client.syncRepository,
                  webSocketClient: client.webSocketClient,
                  apiClient: client.apiClient,
                  timerType: DefaultTimer.self)
    }

    override init(isClientInActiveMode: Bool, syncRepository: SyncRepository, webSocketClient: WebSocketClient?, apiClient: APIClient, timerType: StreamChat.Timer.Type) {
        super.init(
            isClientInActiveMode: isClientInActiveMode,
            syncRepository: syncRepository,
            webSocketClient: webSocketClient,
            apiClient: apiClient,
            timerType: timerType
        )
    }

    // MARK: - Overrides

    override func connect(completion: ((Error?) -> Void)? = nil) {
        record()
        if let result = connectResult {
            completion?(result.error)
        }
    }

    override func disconnect(
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @escaping () -> Void
    ) {
        record()
        if disconnectResult != nil {
            completion()
        }

        disconnectSource = source
    }

    override func forceConnectionStatusForInactiveModeIfNeeded() {
        record()
    }

    override func updateWebSocketEndpoint(with token: Token, userInfo: UserInfo?) {
        updateWebSocketEndpointToken = token
        updateWebSocketEndpointUserInfo = userInfo
        record()
    }

    override func updateWebSocketEndpoint(with currentUserId: UserId) {
        record()
    }

    override func completeConnectionIdWaiters(connectionId: String?) {
        record()
        completeWaitersConnectionId = connectionId
    }

    override func provideConnectionId(timeout: TimeInterval = 10, completion: @escaping (Result<ConnectionId, Error>) -> Void) {
        record()
    }

    override func handleConnectionUpdate(state: WebSocketConnectionState, onExpiredToken: () -> Void) {
        record()
        connectionUpdateState = state
        if simulateExpiredTokenOnConnectionUpdate {
            onExpiredToken()
        }
    }

    // MARK: - Clean Up

    func cleanUp() {
        clear()
        connectResult = nil
        updateWebSocketEndpointToken = nil

        disconnectResult = nil
        disconnectSource = nil
        simulateExpiredTokenOnConnectionUpdate = false
        connectionUpdateState = nil
        completeWaitersConnectionId = nil
        updateWebSocketEndpointToken = nil
    }
}
