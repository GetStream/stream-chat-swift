//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ConnectionRecoveryHandler_Tests: XCTestCase {
    var handler: DefaultConnectionRecoveryHandler!
    var mockChatClient: ChatClient_Mock!
    var mockInternetConnection: InternetConnection_Mock!
    var mockBackgroundTaskScheduler: BackgroundTaskScheduler_Mock!
    var mockRetryStrategy: RetryStrategy_Spy!
    var mockTime: VirtualTime { VirtualTimeTimer.time }

    override func setUp() {
        super.setUp()

        VirtualTimeTimer.time = .init()

        mockChatClient = ChatClient_Mock(config: .init(apiKeyString: .unique))
        mockBackgroundTaskScheduler = BackgroundTaskScheduler_Mock()
        mockRetryStrategy = RetryStrategy_Spy()
        mockRetryStrategy.mock_nextRetryDelay.returns(5)
        mockInternetConnection = .init(notificationCenter: mockChatClient.eventNotificationCenter)
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&handler)
        AssertAsync.canBeReleased(&mockChatClient)
        AssertAsync.canBeReleased(&mockInternetConnection)
        AssertAsync.canBeReleased(&mockRetryStrategy)
        AssertAsync.canBeReleased(&mockBackgroundTaskScheduler)

        handler = nil
        mockChatClient = nil
        mockInternetConnection = nil
        mockRetryStrategy = nil
        mockBackgroundTaskScheduler = nil
        VirtualTimeTimer.invalidate()

        super.tearDown()
    }

    /// keepConnectionAliveInBackground == false
    ///
    /// 1. internet -> OFF (no disconnect, no bg task, no timer)
    /// 2. internet -> ON (no reconnect)
    func test_socketIsInitialized_internetOffOn() {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Internet -> OFF
        mockInternetConnection.monitorMock.status = .unavailable

        // Assert no disconnect
        XCTAssertFalse(mockChatClient.mockWebSocketClient.disconnect_called)
        // Assert no background task started
        XCTAssertFalse(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        // Assert no reconnect timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)

        mockChatClient.mockWebSocketClient.connect_calledCounter = 0

        // Internet -> ON
        mockInternetConnection.monitorMock.status = .available(.great)

        // Assert no reconnect
        XCTAssertFalse(mockChatClient.mockWebSocketClient.connect_called)
    }

    /// keepConnectionAliveInBackground == false
    ///
    /// 1. app -> background (no disconnect, no bg task, no timer)
    /// 2. app -> foregorund (no reconnect)
    func test_socketIsInitialized_appBackgroundForeground() {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // App -> background
        mockBackgroundTaskScheduler.simulateAppGoingToBackground()

        // Assert no disconnect
        XCTAssertFalse(mockChatClient.mockWebSocketClient.disconnect_called)
        // Assert no background task started
        XCTAssertFalse(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        // Assert no reconnect timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)

        mockChatClient.mockWebSocketClient.connect_calledCounter = 0

        // App -> foreground
        mockBackgroundTaskScheduler.simulateAppGoingToForeground()

        // Assert no reconnect
        XCTAssertFalse(mockChatClient.mockWebSocketClient.connect_called)
    }

    /// keepConnectionAliveInBackground == false
    ///
    /// 1. ws -> connected
    /// 2. ws -> disconnected by user
    /// 3. internet -> OFF (no disconnect, no bg task, no timer)
    /// 4. internet -> ON (no reconnect)
    func test_socketIsDisconnectedByUser_internetOffOn() {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Connect
        connectWebSocket()

        // Disconnect (user initiated)
        disconnectWebSocket(source: .userInitiated)

        // Internet -> OFF
        mockInternetConnection.monitorMock.status = .unavailable

        // Assert no disconnect
        XCTAssertFalse(mockChatClient.mockWebSocketClient.disconnect_called)
        // Assert no background task started
        XCTAssertFalse(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        // Assert no reconnect timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)

        mockChatClient.mockWebSocketClient.connect_calledCounter = 0

        // Internet -> ON
        mockInternetConnection.monitorMock.status = .available(.great)

        // Assert no reconnect
        XCTAssertFalse(mockChatClient.mockWebSocketClient.connect_called)
    }

    /// keepConnectionAliveInBackground == false
    ///
    /// 1. ws -> connected
    /// 2. ws -> disconnected by user
    /// 3. app -> background (no disconnect, no bg task, no timer)
    /// 4. app -> foregorund (no reconnect)
    func test_socketIsDisconnectedByUser_appBackgroundForeground() {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Connect
        connectWebSocket()

        // Disconnect (user initiated)
        disconnectWebSocket(source: .userInitiated)

        // App -> background
        mockBackgroundTaskScheduler.simulateAppGoingToBackground()

        // Assert no disconnect
        XCTAssertFalse(mockChatClient.mockWebSocketClient.disconnect_called)
        // Assert no background task started
        XCTAssertFalse(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        // Assert no reconnect timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)

        mockChatClient.mockWebSocketClient.connect_calledCounter = 0

        // App -> foregorund
        mockBackgroundTaskScheduler.simulateAppGoingToForeground()

        // Assert no reconnect
        XCTAssertFalse(mockChatClient.mockWebSocketClient.connect_called)
    }

    /// keepConnectionAliveInBackground == false
    ///
    /// 1. ws -> connected
    /// 2. internet -> OFF (no bg task, no timer)
    /// 3. internet -> ON (reconnect)
    func test_socketIsConnected_appBackgroundForeground() {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Connect
        connectWebSocket()

        // Internet -> OFF
        mockInternetConnection.monitorMock.status = .unavailable

        // Assert no background task
        XCTAssertFalse(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        // Assert no reconnect timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)

        mockChatClient.mockWebSocketClient.connect_calledCounter = 0

        // Disconnect (system initiated)
        disconnectWebSocket(source: .systemInitiated)

        // Internet -> ON
        mockInternetConnection.monitorMock.status = .available(.great)

        // Assert reconnection happens (handler dispatches through engineQueue, so wait for it)
        AssertAsync.willBeTrue(mockChatClient.mockWebSocketClient.connect_called)
    }

    /// keepConnectionAliveInBackground == true
    ///
    /// 1. ws -> connected
    /// 2. app -> background (disconnect, background task is started, no timer)
    /// 3. app -> foregorund (reconnect, background task is ended)
    func test_socketIsConnected_appBackgroundTaskRunningAppForeground() {
        // Create handler active in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: true)

        // Connect
        connectWebSocket()

        // App -> background
        mockBackgroundTaskScheduler.simulateAppGoingToBackground()

        // Assert no disconnect
        XCTAssertFalse(mockChatClient.mockWebSocketClient.disconnect_called)
        // Assert background task is started
        XCTAssertTrue(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        // Assert no reconnect timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)

        mockChatClient.mockWebSocketClient.connect_calledCounter = 0

        // App -> foregorund
        mockBackgroundTaskScheduler.simulateAppGoingToForeground()

        // Assert background task is ended
        XCTAssertTrue(mockBackgroundTaskScheduler.endBackgroundTask_called)

        // Assert the reconnection does not happen since client is still connected
        XCTAssertFalse(mockChatClient.mockWebSocketClient.connect_called)
    }

    /// keepConnectionAliveInBackground == true
    ///
    /// 1. ws -> connected
    /// 2. app -> background (no disconnect, background task is started, no timer)
    /// 3. bg task -> killed (disconnect)
    /// 3. app -> foregorund (reconnect)
    func test_socketIsConnected_appBackgroundTaskKilledAppForeground() {
        // Create handler active in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: true)

        // Connect
        connectWebSocket()

        // App -> background
        mockBackgroundTaskScheduler.simulateAppGoingToBackground()

        // Assert disconnect is not called because it should stay connected in background
        XCTAssertFalse(mockChatClient.mockWebSocketClient.disconnect_called)
        // Assert background task is started so client stays connected in background
        XCTAssertTrue(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        // Assert no reconnect timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)

        // Backgroud task killed
        mockBackgroundTaskScheduler.beginBackgroundTask_expirationHandler?()

        // Assert disconnection is initiated by the system (handler dispatches through engineQueue)
        AssertAsync.willBeEqual(mockChatClient.mockWebSocketClient.disconnect_source, .systemInitiated)

        // Disconnect (system initiated)
        disconnectWebSocket(source: .systemInitiated)

        // App -> foregorund
        mockBackgroundTaskScheduler.simulateAppGoingToForeground()

        // Assert reconnection happens
        AssertAsync.willBeTrue(mockChatClient.mockWebSocketClient.connect_called)
    }

    /// keepConnectionAliveInBackground == false
    ///
    /// 1. ws -> connected
    /// 2. app -> background (disconnect, no bg task, no timer)
    /// 3. app -> foregorund (reconnect)
    func test_socketIsConnected_internetOffOn() {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Connect
        connectWebSocket()

        // App -> background
        mockBackgroundTaskScheduler.simulateAppGoingToBackground()

        // Assert disconnect is initiated by the sytem (handler dispatches through engineQueue)
        AssertAsync.willBeEqual(mockChatClient.mockWebSocketClient.disconnect_source, .systemInitiated)
        // Assert no background task
        XCTAssertFalse(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        // Assert no reconnect timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)

        // Disconnect (system initiated)
        disconnectWebSocket(source: .systemInitiated)

        // App -> foregorund
        mockBackgroundTaskScheduler.simulateAppGoingToForeground()

        // Assert reconnection happens
        AssertAsync.willBeTrue(mockChatClient.mockWebSocketClient.connect_called)
    }

    /// keepConnectionAliveInBackground == true
    ///
    /// 1. ws -> connected
    /// 2. app -> background (no disconnect, background task is started, no timer)
    /// 3. internet -> OFF
    /// 4. internet -> ON (no reconnect in background)
    /// 5. internet -> OFF (no disconnect)
    /// 6. app -> foregorund (reconnect)
    /// 7. internet -> ON (reconnect)
    func test_socketIsConnected_appBackgroundInternetOffOnOffAppForegroundInternetOn() {
        // Create handler active in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: true)

        // Connect
        connectWebSocket()

        // App -> background
        mockBackgroundTaskScheduler.simulateAppGoingToBackground()

        // Assert no disconnect
        XCTAssertFalse(mockChatClient.mockWebSocketClient.disconnect_called)
        // Assert background task is started
        XCTAssertTrue(mockBackgroundTaskScheduler.beginBackgroundTask_called)
        // Assert no reconnect timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)

        // Internet -> OFF
        mockInternetConnection.monitorMock.status = .unavailable

        // Disconnect (system initiated)
        disconnectWebSocket(source: .systemInitiated)

        // Reset calls counts
        mockChatClient.mockWebSocketClient.disconnect_calledCounter = 0
        mockChatClient.mockWebSocketClient.connect_calledCounter = 0

        // Internet -> ON
        mockInternetConnection.monitorMock.status = .available(.great)

        // Assert no reconnect in background
        XCTAssertFalse(mockChatClient.mockWebSocketClient.connect_called)

        // Internet -> OFF
        mockInternetConnection.monitorMock.status = .unavailable

        // App -> foregorund
        mockBackgroundTaskScheduler.simulateAppGoingToForeground()

        // Internet -> ON
        mockInternetConnection.monitorMock.status = .available(.great)

        // Assert reconnection happens
        XCTAssertTrue(mockChatClient.mockWebSocketClient.connect_called)
    }

    /// 1. ws -> connected
    /// 2. ws -> disconnected by server with no error (timer starts)
    /// 3. retry delay -> passed (reconnect)
    func test_socketIsConnected_serverInitiatesDisconnectWithoutError() throws {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Mock retry delay
        let retryDelay: TimeInterval = 5
        mockRetryStrategy.mock_nextRetryDelay.returns(retryDelay)

        // Connect
        connectWebSocket()

        // Disconnect (server initiated)
        disconnectWebSocket(source: .serverInitiated(error: nil))

        // Assert timer is scheduled with correct delay
        let timer = try XCTUnwrap(mockTime.scheduledTimers.first { $0.scheduledFireTime == retryDelay })
        // Assert timer is non repeated
        XCTAssertFalse(timer.isRepeated)
        // Assert timer is active
        XCTAssertTrue(timer.isActive)

        // Wait for reconnection delay to pass
        mockTime.run(numberOfSeconds: 10)

        // Assert reconnection happens (timer onFire dispatches through engineQueue)
        AssertAsync.willBeTrue(mockChatClient.mockWebSocketClient.connect_called)
    }

    /// 1. ws -> connected
    /// 2. ws -> disconnected by server with client error (no timer)
    func test_socketIsConnected_serverInitiatesDisconnectWithClientError() throws {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Connect
        connectWebSocket()

        // Disconnect (server initiated)
        let clientError = ClientError(
            with: ErrorPayload(
                code: .unique,
                message: .unique,
                statusCode: ClosedRange.clientErrorCodes.lowerBound
            )
        )
        disconnectWebSocket(source: .serverInitiated(error: clientError))

        // Assert reconnection timer is not scheduled
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)
    }

    /// 1. ws -> connected
    /// 2. ws -> disconnected by server with token error (no timer)
    func test_socketIsConnected_serverInitiatesDisconnectionWithTokenError() {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Connect
        connectWebSocket()

        // Disconnect (server initiated)
        let tokenError = ClientError(
            with: ErrorPayload(
                code: ClosedRange.tokenInvalidErrorCodes.lowerBound,
                message: .unique,
                statusCode: .unique
            )
        )
        disconnectWebSocket(source: .serverInitiated(error: tokenError))

        // Assert no reconnection timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)
    }

    /// 1. ws -> connected
    /// 2. ws -> disconnected by server with stop error (no timer)
    func test_socketIsConnected_serverInitiatesDisconnectionWithStopError() {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Connect
        connectWebSocket()

        // Disconnect (server initiated)
        let stopError = ClientError(
            with: WebSocketEngineError(
                reason: .unique,
                code: WebSocketEngineError.stopErrorCode,
                engineError: nil
            )
        )
        disconnectWebSocket(source: .serverInitiated(error: stopError))

        // Assert no reconnection timer
        XCTAssertTrue(mockTime.scheduledTimers.isEmpty)
    }

    /// 1. ws -> connected
    /// 2. ws -> disconnected by server without error (time starts)
    /// 3. ws -> connecting (timer is cancelled)
    func test_socketIsWaitingForReconnect_connectionIsInitatedManually() throws {
        // Create handler passive in background
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Mock retry delay
        let retryDelay: TimeInterval = 5
        mockRetryStrategy.mock_nextRetryDelay.returns(retryDelay)

        // Connect
        connectWebSocket()

        // Disconnect (server initiated)
        disconnectWebSocket(source: .serverInitiated(error: nil))

        // Assert timer is scheduled with correct delay
        let timer = try XCTUnwrap(mockTime.scheduledTimers.first { $0.scheduledFireTime == retryDelay })
        // Assert timer is non repeated
        XCTAssertFalse(timer.isRepeated)
        // Assert timer is active
        XCTAssertTrue(timer.isActive)

        // Connect
        mockChatClient.mockWebSocketClient.simulateConnectionStatus(.connecting)

        // Assert timer is cancelled
        XCTAssertFalse(timer.isActive)
    }

    // MARK: - Websocket connection

    func test_webSocketStateUpdate_connecting() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Simulate connection update
        handler.webSocketClient(mockChatClient.mockWebSocketClient, didUpdateConnectionState: .connecting)

        XCTAssertNotCall("syncLocalState(completion:)", on: mockChatClient.mockSyncRepository)
    }

    func test_webSocketStateUpdate_connecting_whenTimeout_whenNotRunning_shouldStartTimeout() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false, withReconnectionTimeout: true)

        // Simulate connection update
        handler.webSocketClient(mockChatClient.mockWebSocketClient, didUpdateConnectionState: .connecting)

        XCTAssertNotCall("syncLocalState(completion:)", on: mockChatClient.mockSyncRepository)
    }

    func test_webSocketStateUpdate_connecting_whenTimeout_whenRunning_shouldNotStartTimeout() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false, withReconnectionTimeout: true)

        // Simulate connection update
        handler.webSocketClient(mockChatClient.mockWebSocketClient, didUpdateConnectionState: .connecting)

        XCTAssertNotCall("syncLocalState(completion:)", on: mockChatClient.mockSyncRepository)
    }

    func test_webSocketStateUpdate_connected() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Simulate connection update
        handler.webSocketClient(mockChatClient.mockWebSocketClient, didUpdateConnectionState: .connected(connectionId: "124"))

        XCTAssertCall(RetryStrategy_Spy.Signature.resetConsecutiveFailures, on: mockRetryStrategy, times: 1)
        XCTAssertCall("syncLocalState(completion:)", on: mockChatClient.mockSyncRepository, times: 1)
    }

    func test_webSocketStateUpdate_connected_whenTimeout_shouldStopTimeout() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false, withReconnectionTimeout: true)

        // Simulate connection update
        handler.webSocketClient(mockChatClient.mockWebSocketClient, didUpdateConnectionState: .connected(connectionId: "124"))

        XCTAssertCall(RetryStrategy_Spy.Signature.resetConsecutiveFailures, on: mockRetryStrategy, times: 1)
        XCTAssertCall("syncLocalState(completion:)", on: mockChatClient.mockSyncRepository, times: 1)
    }

    func test_webSocketStateUpdate_disconnected_userInitiated() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // We need to set the state on the client as well
        let status = WebSocketConnectionState.disconnected(source: .userInitiated)
        mockChatClient.webSocketClient?.simulateConnectionStatus(status)
        // Simulate connection update
        handler.webSocketClient(mockChatClient.mockWebSocketClient, didUpdateConnectionState: status)

        // getDelayAfterTheFailure() calls nextRetryDelay() & incrementConsecutiveFailures() internally
        XCTAssertNotCall(RetryStrategy_Spy.Signature.nextRetryDelay, on: mockRetryStrategy)
        XCTAssertNotCall("incrementConsecutiveFailures()", on: mockRetryStrategy)
        XCTAssertNotCall("syncLocalState(completion:)", on: mockChatClient.mockSyncRepository)
    }

    func test_webSocketStateUpdate_disconnected_systemInitiated() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // We need to set the state on the client as well
        let status = WebSocketConnectionState.disconnected(source: .systemInitiated)
        mockRetryStrategy.mock_nextRetryDelay.returns(5)
        mockChatClient.webSocketClient?.simulateConnectionStatus(status)
        mockRetryStrategy.clear()
        mockChatClient.mockSyncRepository.clear()

        // Simulate connection update
        handler.webSocketClient(mockChatClient.mockWebSocketClient, didUpdateConnectionState: status)

        // getDelayAfterTheFailure() calls nextRetryDelay() & incrementConsecutiveFailures() internally
        XCTAssertCall(RetryStrategy_Spy.Signature.nextRetryDelay, on: mockRetryStrategy, times: 1)
        XCTAssertCall("incrementConsecutiveFailures()", on: mockRetryStrategy, times: 1)
        XCTAssertNotCall("syncLocalState(completion:)", on: mockChatClient.mockSyncRepository)
    }

    func test_webSocketStateUpdate_initialized() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Simulate connection update
        handler.webSocketClient(mockChatClient.mockWebSocketClient, didUpdateConnectionState: .initialized)

        XCTAssertNotCall("syncLocalState(completion:)", on: mockChatClient.mockSyncRepository)
    }

    func test_webSocketStateUpdate_waitingForConnectionId() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Simulate connection update
        handler.webSocketClient(mockChatClient.mockWebSocketClient, didUpdateConnectionState: .waitingForConnectionId)

        XCTAssertNotCall("syncLocalState(completion:)", on: mockChatClient.mockSyncRepository)
    }

    func test_webSocketStateUpdate_disconnecting() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)

        // Simulate connection update
        handler.webSocketClient(
            mockChatClient.mockWebSocketClient,
            didUpdateConnectionState: .disconnecting(source: .systemInitiated)
        )

        XCTAssertNotCall("syncLocalState(completion:)", on: mockChatClient.mockSyncRepository)
    }

    // MARK: - Race regression: disconnect/reconnect must dispatch onto engineQueue

    /// Regression test for the data race that left `connectionState` stuck at `.disconnecting`.
    ///
    /// Without the fix, `disconnectIfNeeded` ran synchronously on the caller's queue (typically
    /// `io.getStream.chat.internet-monitor`). When the internet went down, the handler's
    /// `webSocketClient.disconnect(source: .systemInitiated)` raced with the engine's own
    /// `webSocketDidDisconnect` callback on `engineQueue`, allowing the handler to overwrite
    /// the engine's legitimate `.disconnected` with `.disconnecting`.
    ///
    /// The fix dispatches the handler's check-and-act onto `engineQueue`, serialising it with
    /// engine callbacks. This test verifies the dispatch mechanism by suspending the queue:
    /// without the fix, `disconnect` would be called synchronously on the test thread; with
    /// the fix, the call is queued and only runs once the queue is resumed.
    func test_disconnectIfNeeded_dispatchesOntoEngineQueue() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)
        connectWebSocket()

        let webSocketClient = mockChatClient.mockWebSocketClient
        webSocketClient.disconnect_calledCounter = 0

        webSocketClient.engineQueue.suspend()
        defer { webSocketClient.engineQueue.resume() }

        // Trigger disconnectIfNeeded via internet OFF.
        mockInternetConnection.monitorMock.status = .unavailable

        // With the fix, the handler's block is queued on the suspended engineQueue — disconnect
        // has not been invoked yet. Without the fix, disconnect would already have been called.
        XCTAssertFalse(
            webSocketClient.disconnect_called,
            "Handler must dispatch disconnect onto engineQueue, not call it from the caller's queue."
        )
    }

    /// Symmetric to `test_disconnectIfNeeded_dispatchesOntoEngineQueue` but for the reconnect
    /// path triggered by internet returning (`reconnectIfNeededFromOffline`).
    func test_reconnectFromOffline_dispatchesOntoEngineQueue() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)
        // Put the client in a state from which automatic reconnection is allowed.
        connectWebSocket()
        disconnectWebSocket(source: .systemInitiated)

        let webSocketClient = mockChatClient.mockWebSocketClient
        webSocketClient.connect_calledCounter = 0

        webSocketClient.engineQueue.suspend()
        defer { webSocketClient.engineQueue.resume() }

        // Trigger reconnect via internet ON.
        mockInternetConnection.monitorMock.status = .available(.great)

        XCTAssertFalse(
            webSocketClient.connect_called,
            "Handler must dispatch connect onto engineQueue, not call it from the caller's queue."
        )
    }

    /// Verifies the reconnection-timer onFire path also dispatches onto `engineQueue`.
    func test_reconnectTimerFire_dispatchesOntoEngineQueue() {
        handler = makeConnectionRecoveryHandler(keepConnectionAliveInBackground: false)
        connectWebSocket()
        // Server-initiated disconnect schedules the reconnection timer.
        disconnectWebSocket(source: .serverInitiated(error: nil))

        let webSocketClient = mockChatClient.mockWebSocketClient
        webSocketClient.connect_calledCounter = 0

        webSocketClient.engineQueue.suspend()
        defer { webSocketClient.engineQueue.resume() }

        // Advance virtual time so the reconnect timer fires.
        mockTime.run(numberOfSeconds: 10)

        XCTAssertFalse(
            webSocketClient.connect_called,
            "Timer-driven reconnect must dispatch connect onto engineQueue, not call it from the timer's queue."
        )
    }
}

// MARK: - Private

private extension ConnectionRecoveryHandler_Tests {
    func makeConnectionRecoveryHandler(
        keepConnectionAliveInBackground: Bool,
        withReconnectionTimeout: Bool = false
    ) -> DefaultConnectionRecoveryHandler {
        let handler = DefaultConnectionRecoveryHandler(
            webSocketClient: mockChatClient.mockWebSocketClient,
            eventNotificationCenter: mockChatClient.eventNotificationCenter,
            syncRepository: mockChatClient.mockSyncRepository,
            backgroundTaskScheduler: mockBackgroundTaskScheduler,
            internetConnection: mockInternetConnection,
            reconnectionStrategy: mockRetryStrategy,
            reconnectionTimerType: VirtualTimeTimer.self,
            keepConnectionAliveInBackground: keepConnectionAliveInBackground
        )
        handler.start()

        // Make a handler a delegate to simlulate real life chain when
        // connection changes are propagated back to the handler.
        mockChatClient.webSocketClient?.connectionStateDelegate = handler

        return handler
    }

    func connectWebSocket() {
        let ws = mockChatClient.mockWebSocketClient

        ws.simulateConnectionStatus(.connecting)
        ws.simulateConnectionStatus(.waitingForConnectionId)
        ws.simulateConnectionStatus(.connected(connectionId: .unique))
    }

    func disconnectWebSocket(source: WebSocketConnectionState.DisconnectionSource) {
        let ws = mockChatClient.mockWebSocketClient

        ws.simulateConnectionStatus(.disconnecting(source: source))
        ws.simulateConnectionStatus(.disconnected(source: source))
    }
}
