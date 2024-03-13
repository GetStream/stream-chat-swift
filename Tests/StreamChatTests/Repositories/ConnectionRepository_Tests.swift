//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ConnectionRepository_Tests: XCTestCase {
    private var repository: ConnectionRepository!
    private var webSocketClient: WebSocketClient_Mock!
    private var syncRepository: SyncRepository_Mock!
    private var apiClient: APIClient_Spy!

    override func setUp() {
        super.setUp()
        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        syncRepository = SyncRepository_Mock()
        repository = ConnectionRepository(
            isClientInActiveMode: true,
            syncRepository: syncRepository,
            webSocketClient: webSocketClient,
            apiClient: apiClient,
            timerType: DefaultTimer.self
        )
    }

    override func tearDown() {
        super.tearDown()
        repository = nil
    }

    func test_concurrentAccess() {
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = repository.connectionStatus
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = repository.connectionId
        }
    }

    // MARK: Connect

    func test_connect_notInActiveMode_shouldReturnError() {
        repository = ConnectionRepository(
            isClientInActiveMode: false,
            syncRepository: syncRepository,
            webSocketClient: webSocketClient,
            apiClient: apiClient,
            timerType: DefaultTimer.self
        )

        var receivedError: Error?
        let expectation = self.expectation(description: "connect completes")
        repository.connect {
            receivedError = $0
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertTrue(receivedError is ClientError.ClientIsNotInActiveMode)
    }

    func test_connect_existingConnectionId_shouldReturnWithoutTryingToConnect() {
        repository.completeConnectionIdWaiters(connectionId: "123")
        XCTAssertNotNil(repository.connectionId)

        var receivedError: Error?
        let expectation = self.expectation(description: "connect completes")
        repository.connect {
            receivedError = $0
            expectation.fulfill()
        }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(receivedError)
        XCTAssertFalse(webSocketClient.connect_called)
    }

    func test_connect_noConnectionId_failure() throws {
        XCTAssertNil(repository.connectionId)

        var receivedError: Error?
        let expectation = self.expectation(description: "connect completes")
        repository.connect {
            receivedError = $0
            expectation.fulfill()
        }

        // Simulate error scenario (change status + force waiters completion)
        webSocketClient.mockedConnectionState = .waitingForConnectionId
        repository.completeConnectionIdWaiters(connectionId: nil)

        waitForExpectations(timeout: defaultTimeout)

        let error = try XCTUnwrap(receivedError as? ClientError.ConnectionNotSuccessful)
        XCTAssertNil(error.underlyingError)
        XCTAssertEqual(webSocketClient.connect_calledCounter, 1)
        XCTAssertNil(repository.connectionId)
    }

    func test_connect_noConnectionId_invalidTokenError() throws {
        XCTAssertNil(repository.connectionId)

        var receivedError: Error?
        let expectation = self.expectation(description: "connect completes")
        repository.connect {
            receivedError = $0
            expectation.fulfill()
        }

        let invalidTokenError = ClientError(with: ErrorPayload(
            code: .random(in: ClosedRange.tokenInvalidErrorCodes),
            message: .unique,
            statusCode: .unique
        ))
        webSocketClient.mockedConnectionState = .disconnected(source: .serverInitiated(error: invalidTokenError))
        repository.completeConnectionIdWaiters(connectionId: nil)

        waitForExpectations(timeout: defaultTimeout)

        let error = try XCTUnwrap(receivedError as? ClientError.ConnectionNotSuccessful)
        XCTAssertEqual(error.underlyingError, invalidTokenError)
        XCTAssertEqual(webSocketClient.connect_calledCounter, 1)
        XCTAssertNil(repository.connectionId)
    }

    func test_connect_noConnectionId_success() throws {
        XCTAssertNil(repository.connectionId)

        var receivedError: Error?
        let expectation = self.expectation(description: "connect completes")
        repository.connect {
            receivedError = $0
            expectation.fulfill()
        }

        let connectionId = "con123"
        repository.completeConnectionIdWaiters(connectionId: connectionId)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertNil(receivedError)
        XCTAssertEqual(webSocketClient.connect_calledCounter, 1)
        XCTAssertEqual(repository.connectionId, connectionId)
    }

    // MARK: Disconnect

    func test_disconnect_noConnectionId_shouldReturnWithoutTryingToConnect() {
        XCTAssertNil(repository.connectionId)

        let expectation = self.expectation(description: "connect completes")
        repository.disconnect(source: .userInitiated) { expectation.fulfill() }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertFalse(webSocketClient.disconnect_called)
        XCTAssertCall(APIClient_Spy.Signature.flushRequestsQueue, on: apiClient)
        XCTAssertCall(SyncRepository_Mock.Signature.cancelRecoveryFlow, on: syncRepository)
    }

    func test_disconnect_withConnectionId_notInActiveMode_shouldReturnError() {
        repository.completeConnectionIdWaiters(connectionId: "123")
        XCTAssertNotNil(repository.connectionId)

        repository = ConnectionRepository(
            isClientInActiveMode: false,
            syncRepository: syncRepository,
            webSocketClient: webSocketClient,
            apiClient: apiClient,
            timerType: DefaultTimer.self
        )

        let expectation = self.expectation(description: "connect completes")
        repository.disconnect(source: .userInitiated) { expectation.fulfill() }

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertFalse(webSocketClient.disconnect_called)
        XCTAssertCall(APIClient_Spy.Signature.flushRequestsQueue, on: apiClient)
        XCTAssertCall(SyncRepository_Mock.Signature.cancelRecoveryFlow, on: syncRepository)
    }

    func test_disconnect_existingConnectionId_activeMode() throws {
        repository.completeConnectionIdWaiters(connectionId: "123")
        XCTAssertNotNil(repository.connectionId)

        let expectation = self.expectation(description: "connect completes")
        repository.disconnect(source: .userInitiated) { expectation.fulfill() }

        let disconnectCompletion = try XCTUnwrap(webSocketClient.disconnect_completion)
        disconnectCompletion()

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertTrue(webSocketClient.disconnect_called)
        XCTAssertNil(repository.connectionId)
        XCTAssertCall(APIClient_Spy.Signature.flushRequestsQueue, on: apiClient)
        XCTAssertCall(SyncRepository_Mock.Signature.cancelRecoveryFlow, on: syncRepository)
    }

    // MARK: Update WebSocket Endpoint

    func test_updateWebSocketEndpointWithToken() throws {
        let tokenUserId = "123-token-userId"
        let token = Token(rawValue: "", userId: tokenUserId, expiration: nil)

        XCTAssertNil(webSocketClient.connectEndpoint)
        repository.updateWebSocketEndpoint(with: token, userInfo: nil)

        // UserInfo should take priority
        XCTAssertEqual(
            webSocketClient.connectEndpoint.map(AnyEndpoint.init),
            AnyEndpoint(
                .webSocketConnect(
                    userInfo: UserInfo(id: tokenUserId)
                )
            )
        )
    }

    func test_updateWebSocketEndpointWithTokenAndUserInfo() throws {
        let userInfoUserId = "123-userId"
        let userInfo = UserInfo(id: userInfoUserId)
        let tokenUserId = "123-token-userId"
        let token = Token(rawValue: "", userId: tokenUserId, expiration: nil)

        XCTAssertNil(webSocketClient.connectEndpoint)
        repository.updateWebSocketEndpoint(with: token, userInfo: userInfo)

        // UserInfo should take priority
        XCTAssertEqual(
            webSocketClient.connectEndpoint.map(AnyEndpoint.init),
            AnyEndpoint(
                .webSocketConnect(
                    userInfo: UserInfo(id: userInfoUserId)
                )
            )
        )
    }

    func test_updateWebSocketEndpointWithUserId() throws {
        let userId = "123-userId"
        XCTAssertNil(webSocketClient.connectEndpoint)
        repository.updateWebSocketEndpoint(with: userId)

        XCTAssertEqual(
            webSocketClient.connectEndpoint.map(AnyEndpoint.init),
            AnyEndpoint(
                .webSocketConnect(
                    userInfo: UserInfo(id: userId)
                )
            )
        )
    }

    // MARK: Handle connection update

    func test_handleConnectionUpdate_setsCorrectConnectionStatus() {
        let invalidTokenError = ClientError(with: ErrorPayload(
            code: .random(in: ClosedRange.tokenInvalidErrorCodes),
            message: .unique,
            statusCode: .unique
        ))

        let pairs: [(WebSocketConnectionState, ConnectionStatus)] = [
            (.initialized, .initialized),
            (.connecting, .connecting),
            (.waitingForConnectionId, .connecting),
            (.connected(connectionId: "123"), .connected),
            (.disconnecting(source: .userInitiated), .disconnecting),
            (.disconnecting(source: .noPongReceived), .disconnecting),
            (.disconnected(source: .userInitiated), .disconnected(error: nil)),
            (.disconnected(source: .systemInitiated), .connecting),
            (.disconnected(source: .serverInitiated(error: invalidTokenError)), .connecting)
        ]

        for (webSocketState, connectionStatus) in pairs {
            repository.handleConnectionUpdate(state: webSocketState, onExpiredToken: {})
            XCTAssertEqual(repository.connectionStatus, connectionStatus)
        }
    }

    func test_handleConnectionUpdate_shouldNotifyWaitersWhenNeeded() {
        let invalidTokenError = ClientError(with: ErrorPayload(
            code: .random(in: ClosedRange.tokenInvalidErrorCodes),
            message: .unique,
            statusCode: .unique
        ))

        let pairs: [(WebSocketConnectionState, Bool)] = [
            (.initialized, false),
            (.connecting, false),
            (.waitingForConnectionId, false),
            (.connected(connectionId: "123"), true),
            (.disconnecting(source: .userInitiated), false),
            (.disconnecting(source: .noPongReceived), false),
            (.disconnected(source: .userInitiated), true),
            (.disconnected(source: .systemInitiated), true),
            (.disconnected(source: .serverInitiated(error: invalidTokenError)), false)
        ]

        for (webSocketState, shouldNotify) in pairs {
            let repository = ConnectionRepository(
                isClientInActiveMode: true,
                syncRepository: syncRepository,
                webSocketClient: webSocketClient,
                apiClient: apiClient,
                timerType: DefaultTimer.self
            )

            let expectation = shouldNotify ? self.expectation(description: "ConnectionId waiters complete") : nil
            repository.provideConnectionId { [weak repository] result in
                guard repository != nil else { return }

                if result.error is ClientError.WaiterTimeout {
                    XCTFail("\(webSocketState) should not reach timeout")
                } else if let expectation = expectation {
                    expectation.fulfill()
                } else {
                    XCTFail("\(webSocketState) should not notify")
                }
            }

            repository.handleConnectionUpdate(state: webSocketState, onExpiredToken: {})

            if shouldNotify {
                waitForExpectations(timeout: defaultTimeout)
            }
        }
    }

    func test_handleConnectionUpdate_shouldUpdateConnectionId() {
        let pairs: [(WebSocketConnectionState, ConnectionId?)] = [
            (.initialized, nil),
            (.connecting, nil),
            (.waitingForConnectionId, nil),
            (.connected(connectionId: "123"), "123"),
            (.disconnecting(source: .userInitiated), nil),
            (.disconnected(source: .userInitiated), nil)
        ]

        for (webSocketState, newConnectionIdValue) in pairs {
            let repository = ConnectionRepository(
                isClientInActiveMode: true,
                syncRepository: syncRepository,
                webSocketClient: webSocketClient,
                apiClient: apiClient,
                timerType: DefaultTimer.self
            )

            let originalConnectionId = "original-connection-id"
            repository.completeConnectionIdWaiters(connectionId: originalConnectionId)
            XCTAssertEqual(repository.connectionId, originalConnectionId)

            repository.handleConnectionUpdate(state: webSocketState, onExpiredToken: {})

            XCTAssertEqual(repository.connectionId, newConnectionIdValue)
        }
    }

    func test_handleConnectionUpdate_whenExpiredToken_shouldExecuteExpiredTokenBlock() {
        let expectation = self.expectation(description: "Expired Token Block Not Executed")
        let expiredTokenError = ClientError(with: ErrorPayload(
            code: StreamErrorCode.expiredToken,
            message: .unique,
            statusCode: .unique
        ))

        repository.handleConnectionUpdate(state: .disconnected(source: .serverInitiated(error: expiredTokenError)), onExpiredToken: {
            expectation.fulfill()
        })

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_handleConnectionUpdate_whenInvalidToken_shouldNotExecuteExpiredTokenBlock() {
        let expectation = self.expectation(description: "Expired Token Block Not Executed")
        expectation.isInverted = true
        let invalidTokenError = ClientError(with: ErrorPayload(
            code: StreamErrorCode.invalidTokenSignature,
            message: .unique,
            statusCode: .unique
        ))

        repository.handleConnectionUpdate(state: .disconnected(source: .serverInitiated(error: invalidTokenError)), onExpiredToken: {
            expectation.fulfill()
        })

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_handleConnectionUpdate_whenInvalidToken_whenDisconnecting_shouldNOTExecuteRefreshTokenBlock() {
        // We only want to refresh the token when it is actually disconnected, not while it is disconnecting, otherwise we trigger refresh token twice.
        let invalidTokenError = ClientError(with: ErrorPayload(
            code: .random(in: ClosedRange.tokenInvalidErrorCodes),
            message: .unique,
            statusCode: .unique
        ))

        repository.handleConnectionUpdate(state: .disconnecting(source: .serverInitiated(error: invalidTokenError)), onExpiredToken: {
            XCTFail("Should not execute invalid token block")
        })
    }

    func test_handleConnectionUpdate_whenNoError_shouldNOTExecuteRefreshTokenBlock() {
        let states: [WebSocketConnectionState] = [.connecting, .initialized, .connected(connectionId: .newUniqueId), .waitingForConnectionId]

        for state in states {
            repository.handleConnectionUpdate(state: state, onExpiredToken: {
                XCTFail("Should not execute invalid token block")
            })
        }
    }

    // MARK: Provide ConnectionId

    func test_connectionId_returnsValue_whenAlreadyHasToken() {
        let existingConnectionId = "existing-connection-id"
        repository.completeConnectionIdWaiters(connectionId: existingConnectionId)

        var result: Result<ConnectionId, Error>?
        let expectation = self.expectation(description: "Provide Connection Id Completion")
        repository.provideConnectionId(timeout: defaultTimeout) {
            result = $0
            expectation.fulfill()
        }

        // Sync execution
        XCTAssertNotNil(result)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(result?.value, existingConnectionId)
    }

    func test_connectionId_returnsErrorOnTimeout() {
        var result: Result<ConnectionId, Error>?
        let expectation = self.expectation(description: "Provide Token Completion")
        repository.provideConnectionId(timeout: 0.01) {
            result = $0
            expectation.fulfill()
        }
        XCTAssertNil(result)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertTrue(result?.error is ClientError.WaiterTimeout)
    }

    func test_connectionId_returnsErrorOnTimeout_threadSafe() {
        let expectation = self.expectation(description: "Provide Token Completion")
        expectation.expectedFulfillmentCount = 100

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            expectation.fulfill()
            repository.provideConnectionId(timeout: 0.1) { _ in }
        }

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_connectionId_returnsErrorOnMissingValue() {
        var result: Result<ConnectionId, Error>?
        let expectation = self.expectation(description: "Provide Token Completion")
        repository.provideConnectionId(timeout: defaultTimeout) {
            result = $0
            expectation.fulfill()
        }
        XCTAssertNil(result)

        // Complete with nil
        repository.completeConnectionIdWaiters(connectionId: nil)
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertTrue(result?.error is ClientError.MissingConnectionId)
    }

    func test_connectionId_returnsValue_whenCompletingTokenWaiters() {
        var result: Result<ConnectionId, Error>?
        let expectation = self.expectation(description: "Provide Token Completion")
        repository.provideConnectionId(timeout: defaultTimeout) {
            result = $0
            expectation.fulfill()
        }
        XCTAssertNil(result)

        // Complete with connection id
        let connectionId = "connection-id"
        repository.completeConnectionIdWaiters(connectionId: connectionId)
        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(result?.value, connectionId)
    }

    func test_connectionId_triggersCompletions_whenConcurrentlyCalled() {
        let iterations = 100
        let expectations = (0..<iterations).map { XCTestExpectation(description: "\($0)") }
        DispatchQueue.concurrentPerform(iterations: 100) { index in
            repository.provideConnectionId(timeout: 0) { _ in
                expectations[index].fulfill()
            }
        }
        // Trigger another complete for making sure that _connectionIdWaiters were correctly cleaned up as part of provideConnectionId (expectation is not fulfilled twice)
        repository.completeConnectionIdWaiters(connectionId: "newId")
        wait(for: expectations, timeout: defaultTimeout)
    }

    // MARK: Complete ConnectionId Waiters

    func test_completeConnectionIdWaiters_nil_connectionId() {
        // Set initial connectionId
        let initialConnectionId = "initial-connection-id"
        repository.handleConnectionUpdate(
            state: .connected(connectionId: initialConnectionId),
            onExpiredToken: {}
        )
        XCTAssertEqual(repository.connectionId, initialConnectionId)

        repository.completeConnectionIdWaiters(connectionId: nil)

        // Clears connectionId
        XCTAssertNil(repository.connectionId)
    }

    func test_completeConnectionIdWaiters_valid_connectionId_completesWaiters() {
        var result: Result<ConnectionId, Error>?
        let expectation = self.expectation(description: "Provide Connection Id Completion")
        repository.provideConnectionId(timeout: defaultTimeout) {
            result = $0
            expectation.fulfill()
        }
        XCTAssertNil(result)

        let connectionId = "connection-id"
        repository.completeConnectionIdWaiters(connectionId: connectionId)

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(result?.value, connectionId)
        XCTAssertEqual(repository.connectionId, connectionId)
    }

    // MARK: Force ConnectionStatus for Inactive Mode

    func test_forceConnectionStatusForInactiveModeIfNeeded_doesNotChangeConnectionStatus_ifActiveMode() {
        repository = ConnectionRepository(
            isClientInActiveMode: true,
            syncRepository: syncRepository,
            webSocketClient: webSocketClient,
            apiClient: apiClient,
            timerType: DefaultTimer.self
        )

        XCTAssertEqual(repository.connectionStatus, .initialized)

        repository.forceConnectionStatusForInactiveModeIfNeeded()

        XCTAssertEqual(repository.connectionStatus, .initialized)
    }

    func test_forceConnectionStatusForInactiveModeIfNeeded_setsDisconnectedState_ifNotActiveMode() {
        repository = ConnectionRepository(
            isClientInActiveMode: false,
            syncRepository: syncRepository,
            webSocketClient: webSocketClient,
            apiClient: apiClient,
            timerType: DefaultTimer.self
        )
        XCTAssertEqual(repository.connectionStatus, .initialized)

        repository.forceConnectionStatusForInactiveModeIfNeeded()

        XCTAssertEqual(repository.connectionStatus, .disconnected(error: nil))
    }
}
