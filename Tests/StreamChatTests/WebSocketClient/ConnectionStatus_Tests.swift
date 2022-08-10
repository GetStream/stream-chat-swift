//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatClientConnectionStatus_Tests: XCTestCase {
    func test_wsConnectionState_isTranslatedCorrectly() {
        let testError = ClientError(with: TestError())
        
        let invalidTokenError = ClientError(
            with: ErrorPayload(
                code: ClosedRange.tokenInvalidErrorCodes.lowerBound,
                message: .unique,
                statusCode: .unique,
                details: []
            )
        )

        let pairs: [(WebSocketConnectionState, ConnectionStatus)] = [
            (.initialized, .initialized),
            (.connecting, .connecting),
            (.waitingForConnectionId, .connecting),
            (.disconnected(source: .systemInitiated), .connecting),
            (.disconnected(source: .noPongReceived), .connecting),
            (.disconnected(source: .serverInitiated(error: nil)), .connecting),
            (.disconnected(source: .serverInitiated(error: testError)), .connecting),
            (.disconnected(source: .serverInitiated(error: invalidTokenError)), .connecting),
            (.connected(connectionId: .unique), .connected),
            (.disconnecting(source: .noPongReceived), .disconnecting),
            (.disconnecting(source: .serverInitiated(error: testError)), .disconnecting),
            (.disconnecting(source: .systemInitiated), .disconnecting),
            (.disconnecting(source: .userInitiated), .disconnecting),
            (.disconnected(source: .userInitiated), .disconnected(error: nil))
        ]
        
        pairs.forEach {
            XCTAssertEqual($1, ConnectionStatus(webSocketConnectionState: $0))
        }
    }
}

final class WebSocketConnectionState_Tests: XCTestCase {
    // MARK: - Server error
    
    func test_disconnectionSource_serverError() {
        // Create test error
        let testError = ClientError(with: TestError())
        
        // Create pairs of disconnection source and expected server error
        let testCases: [(WebSocketConnectionState.DisconnectionSource, ClientError?)] = [
            (.userInitiated, nil),
            (.systemInitiated, nil),
            (.noPongReceived, nil),
            (.serverInitiated(error: nil), nil),
            (.serverInitiated(error: testError), testError)
        ]
        
        // Iterate pairs
        testCases.forEach { source, serverError in
            // Assert returned server error matches expected one
            XCTAssertEqual(source.serverError, serverError)
        }
    }
    
    // MARK: - Automatic reconnection
    
    func test_isAutomaticReconnectionEnabled_whenNotDisconnected_returnsFalse() {
        // Create array of connection states excluding disconnected state
        let connectionStates: [WebSocketConnectionState] = [
            .initialized,
            .connecting,
            .waitingForConnectionId,
            .connected(connectionId: .unique),
            .disconnecting(source: .userInitiated),
            .disconnecting(source: .systemInitiated),
            .disconnecting(source: .noPongReceived),
            .disconnecting(source: .serverInitiated(error: nil))
        ]
        
        // Iterate conneciton states
        for state in connectionStates {
            // Assert `isAutomaticReconnectionEnabled` returns false
            XCTAssertFalse(state.isAutomaticReconnectionEnabled)
        }
    }
    
    func test_isAutomaticReconnectionEnabled_whenDisconnectedBySystem_returnsTrue() {
        // Create disconnected state initated by the sytem
        let state: WebSocketConnectionState = .disconnected(source: .systemInitiated)
        
        // Assert `isAutomaticReconnectionEnabled` returns true
        XCTAssertTrue(state.isAutomaticReconnectionEnabled)
    }
    
    func test_isAutomaticReconnectionEnabled_whenDisconnectedWithNoPongReceived_returnsTrue() {
        // Create disconnected state when pong does not come
        let state: WebSocketConnectionState = .disconnected(source: .noPongReceived)
        
        // Assert `isAutomaticReconnectionEnabled` returns true
        XCTAssertTrue(state.isAutomaticReconnectionEnabled)
    }
    
    func test_isAutomaticReconnectionEnabled_whenDisconnectedByServerWithoutError_returnsTrue() {
        // Create disconnected state initiated by the server without any error
        let state: WebSocketConnectionState = .disconnected(source: .serverInitiated(error: nil))
        
        // Assert `isAutomaticReconnectionEnabled` returns true
        XCTAssertTrue(state.isAutomaticReconnectionEnabled)
    }
    
    func test_isAutomaticReconnectionEnabled_whenDisconnectedByServerWithRandomError_returnsTrue() {
        // Create disconnected state intiated by the server with random error
        let state: WebSocketConnectionState = .disconnected(source: .serverInitiated(error: ClientError(.unique)))
        
        // Assert `isAutomaticReconnectionEnabled` returns true
        XCTAssertTrue(state.isAutomaticReconnectionEnabled)
    }
    
    func test_isAutomaticReconnectionEnabled_whenDisconnectedByUser_returnsFalse() {
        // Create disconnected state initated by the user
        let state: WebSocketConnectionState = .disconnected(source: .userInitiated)
        
        // Assert `isAutomaticReconnectionEnabled` returns false
        XCTAssertFalse(state.isAutomaticReconnectionEnabled)
    }
    
    func test_isAutomaticReconnectionEnabled_whenDisconnectedByServerWithInvalidTokenError_returnsFalse() {
        // Create invalid token error
        let invalidTokenError = ErrorPayload(
            code: ClosedRange.tokenInvalidErrorCodes.lowerBound,
            message: .unique,
            statusCode: .unique,
            details: []
        )
        
        // Create disconnected state intiated by the server with invalid token error
        let state: WebSocketConnectionState = .disconnected(
            source: .serverInitiated(error: ClientError(with: invalidTokenError))
        )
        
        // Assert `isAutomaticReconnectionEnabled` returns false
        XCTAssertFalse(state.isAutomaticReconnectionEnabled)
    }
    
    func test_isAutomaticReconnectionEnabled_whenDisconnectedByServerWithClientError_returnsFalse() {
        // Create client error
        let clientError = ErrorPayload(
            code: .unique,
            message: .unique,
            statusCode: ClosedRange.clientErrorCodes.lowerBound,
            details: []
        )
        
        // Create disconnected state intiated by the server with client error
        let state: WebSocketConnectionState = .disconnected(
            source: .serverInitiated(error: ClientError(with: clientError))
        )
        
        // Assert `isAutomaticReconnectionEnabled` returns false
        XCTAssertFalse(state.isAutomaticReconnectionEnabled)
    }
    
    func test_isAutomaticReconnectionEnabled_whenDisconnectedByServerWithStopError_returnsFalse() {
        // Create stop error
        let stopError = WebSocketEngineError(
            reason: .unique,
            code: WebSocketEngineError.stopErrorCode,
            engineError: nil
        )
        
        // Create disconnected state intiated by the server with stop error
        let state: WebSocketConnectionState = .disconnected(
            source: .serverInitiated(error: ClientError(with: stopError))
        )
        
        // Assert `isAutomaticReconnectionEnabled` returns false
        XCTAssertFalse(state.isAutomaticReconnectionEnabled)
    }
}
