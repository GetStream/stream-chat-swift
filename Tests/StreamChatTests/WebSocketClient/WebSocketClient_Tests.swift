//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class WebSocketClient_Tests: XCTestCase {
    // The longest time WebSocket waits to reconnect.
    let maxReconnectTimeout: VirtualTime.Seconds = 25
    
    var webSocketClient: WebSocketClient!
    
    var time: VirtualTime!
    var endpoint: Endpoint<EmptyResponse>!
    private var decoder: EventDecoder_Mock!
    var engine: WebSocketEngine_Mock? { webSocketClient.engine as? WebSocketEngine_Mock }
    var connectionId: String!
    var user: ChatUser!
    var requestEncoder: RequestEncoder_Spy!
    var pingController: WebSocketPingController_Mock { webSocketClient.pingController as! WebSocketPingController_Mock }
    var eventsBatcher: EventBatcher_Mock { webSocketClient.eventsBatcher as! EventBatcher_Mock }
    
    var eventNotificationCenter: EventNotificationCenter_Mock!
    private var eventNotificationCenterMiddleware: EventMiddleware_Mock!
    
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        endpoint = .webSocketConnect(
            userInfo: UserInfo(id: .unique)
        )
        
        decoder = EventDecoder_Mock()
        
        requestEncoder = RequestEncoder_Spy(baseURL: .unique(), apiKey: .init(.unique))
        
        database = DatabaseContainer_Spy()
        eventNotificationCenter = EventNotificationCenter_Mock(database: database)
        eventNotificationCenterMiddleware = EventMiddleware_Mock()
        eventNotificationCenter.add(middleware: eventNotificationCenterMiddleware)
        
        var environment = WebSocketClient.Environment.mock
        environment.timerType = VirtualTimeTimer.self
        
        webSocketClient = WebSocketClient(
            sessionConfiguration: .ephemeral,
            requestEncoder: requestEncoder,
            eventDecoder: decoder,
            eventNotificationCenter: eventNotificationCenter,
            environment: environment
        )
        
        connectionId = UUID().uuidString
        user = .mock(id: "test_user_\(UUID().uuidString)")
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&webSocketClient)
        AssertAsync.canBeReleased(&eventNotificationCenter)
        AssertAsync.canBeReleased(&eventNotificationCenterMiddleware)
        AssertAsync.canBeReleased(&database)

        webSocketClient = nil
        eventNotificationCenter = nil
        eventNotificationCenterMiddleware = nil
        database = nil
        VirtualTimeTimer.invalidate()
        time = nil
        endpoint = nil
        decoder = nil
        connectionId = nil
        user = nil
        requestEncoder = nil

        super.tearDown()
    }

    // MARK: - Setup

    func test_webSocketClient_isInstantiatedInCorrectState() {
        XCTAssertNil(webSocketClient.connectEndpoint)
        XCTAssertNil(webSocketClient.engine)
    }

    func test_engine_isReused_ifRequestIsNotChanged() {
        // Setup endpoint.
        webSocketClient.connectEndpoint = endpoint

        // Simulate connect to trigger engine creation or reuse.
        webSocketClient.connect()
        // Save currently existed engine.
        let oldEngine = webSocketClient.engine
        // Disconnect the client.
        webSocketClient.disconnect {}

        // Simulate connect to trigger engine creation or reuse.
        webSocketClient.connect()

        // Assert engine is reused since the connect request is not changed.
        XCTAssertTrue(oldEngine === webSocketClient.engine)
    }

    func test_engine_isRecreated_ifRequestIsChanged() {
        // Setup endpoint.
        webSocketClient.connectEndpoint = endpoint

        // Simulate connect to trigger engine creation or reuse.
        webSocketClient.connect()
        // Save currently existed engine.
        let oldEngine = webSocketClient.engine
        // Disconnect the client.
        webSocketClient.disconnect {}

        // Update request encode to provide different request.
        requestEncoder.encodeRequest = .success(.init(url: .unique()))
        // Simulate connect to trigger engine creation or reuse.
        webSocketClient.connect()

        // Assert engine is recreated since the connect request is changed.
        XCTAssertFalse(oldEngine === webSocketClient.engine)
    }
    
    // MARK: - Connection tests
    
    func test_connectionFlow() {
        assert(webSocketClient.connectionState == .initialized)
        
        // Simulate response from the encoder
        let request = URLRequest(url: .unique())
        requestEncoder.encodeRequest = .success(request)
        
        // Call `connect`, it should change connection state and call `connect` on the engine
        webSocketClient.connectEndpoint = endpoint
        webSocketClient.connect()
        XCTAssertEqual(webSocketClient.connectionState, .connecting)
        
        AssertAsync {
            Assert.willBeEqual(self.engine!.request, request)
            Assert.willBeEqual(self.engine!.connect_calledCount, 1)
        }
        
        // Simulate the engine is connected and check the connection state is updated
        engine!.simulateConnectionSuccess()
        AssertAsync.willBeEqual(webSocketClient.connectionState, .waitingForConnectionId)
        
        // Simulate a health check event is received and the connection state is updated
        decoder.decodedEvent = .success(HealthCheckEvent(connectionId: connectionId))
        engine!.simulateMessageReceived()
        
        AssertAsync.willBeEqual(webSocketClient.connectionState, .connected(connectionId: connectionId))
    }
    
    func test_callingConnect_whenAlreadyConnected_hasNoEffect() {
        // Simulate connection
        test_connectionFlow()
        
        assert(webSocketClient.connectionState == .connected(connectionId: connectionId))
        assert(engine!.connect_calledCount == 1)
        
        // Call connect and assert it has no effect
        webSocketClient.connect()
        AssertAsync {
            Assert.staysTrue(self.engine!.connect_calledCount == 1)
            Assert.staysTrue(self.webSocketClient.connectionState == .connected(connectionId: self.connectionId))
        }
    }
    
    func test_disconnect_callsEngine() {
        // Simulate connection
        test_connectionFlow()
        
        assert(webSocketClient.connectionState == .connected(connectionId: connectionId))
        assert(engine!.disconnect_calledCount == 0)
                
        // Call `disconnect`, it should change connection state and call `disconnect` on the engine
        let source: WebSocketConnectionState.DisconnectionSource = .userInitiated
        webSocketClient.disconnect(source: source) {}
        
        // Assert disconnect is called
        AssertAsync.willBeEqual(engine!.disconnect_calledCount, 1)
    }
    
    func test_whenConnectedAndEngineDisconnectsWithServerError_itIsTreatedAsServerInitiatedDisconnect() {
        // Simulate connection
        test_connectionFlow()
        
        // Simulate the engine disconnecting with server error
        let errorPayload = ErrorPayload(
            code: .unique,
            message: .unique,
            statusCode: .unique
        )
        let engineError = WebSocketEngineError(
            reason: UUID().uuidString,
            code: 0,
            engineError: errorPayload
        )
        engine!.simulateDisconnect(engineError)
        
        // Assert state is disconnected with `systemInitiated` source
        XCTAssertEqual(
            webSocketClient.connectionState,
            .disconnected(source: .serverInitiated(error: ClientError.WebSocket(with: engineError)))
        )
    }
    
    func test_disconnect_propagatesDisconnectionSource() {
        // Simulate connection
        test_connectionFlow()
        
        let testCases: [WebSocketConnectionState.DisconnectionSource] = [
            .userInitiated,
            .systemInitiated,
            .serverInitiated(error: nil),
            .serverInitiated(error: .init(.unique))
        ]
        
        for source in testCases {
            engine?.disconnect_calledCount = 0
            
            // Call `disconnect` with the given source
            webSocketClient.disconnect(source: source) {}
            
            // Assert connection state is changed to disconnecting respecting the source
            XCTAssertEqual(webSocketClient.connectionState, .disconnecting(source: source))
            
            // Assert disconnect is called
            AssertAsync.willBeEqual(engine!.disconnect_calledCount, 1)
            
            // Simulate engine disconnection
            engine!.simulateDisconnect()
            
            // Assert state is `disconnected` with the correct source
            AssertAsync.willBeEqual(webSocketClient.connectionState, .disconnected(source: source))
        }
    }
    
    func test_connectionState_afterDecodingError() {
        // Simulate connection
        test_connectionFlow()
        
        decoder.decodedEvent = .failure(
            DecodingError.keyNotFound(
                EventPayload.CodingKeys.eventType,
                .init(codingPath: [], debugDescription: "")
            )
        )
        engine!.simulateMessageReceived()
        
        AssertAsync.staysEqual(webSocketClient.connectionState, .connected(connectionId: connectionId))
    }
    
    // MARK: - Ping Controller
    
    func test_webSocketPingController_connectionStateDidChange_calledWhenConnectionChanges() {
        test_connectionFlow()
        AssertAsync.willBeEqual(
            pingController.connectionStateDidChange_connectionStates,
            [.connecting, .waitingForConnectionId, .connected(connectionId: connectionId)]
        )
    }
    
    func test_webSocketPingController_ping_callsEngineWithPing() {
        // Simulate connection to make sure web socket engine exists
        test_connectionFlow()
        // Reset the counter
        engine!.sendPing_calledCount = 0

        pingController.delegate?.sendPing()
        AssertAsync.willBeEqual(engine!.sendPing_calledCount, 1)
    }
    
    func test_pongReceived_callsPingController_pongReceived() {
        // Simulate connection to make sure web socket engine exists
        test_connectionFlow()
        assert(pingController.pongReceivedCount == 1)
        
        // Simulate a health check (pong) event is received
        decoder.decodedEvent = .success(HealthCheckEvent(connectionId: connectionId))
        engine!.simulateMessageReceived()
        
        AssertAsync.willBeEqual(pingController.pongReceivedCount, 2)
    }
    
    func test_webSocketPingController_disconnectOnNoPongReceived_disconnectsEngine() {
        // Simulate connection to make sure web socket engine exists
        test_connectionFlow()
        
        assert(engine!.disconnect_calledCount == 0)

        pingController.delegate?.disconnectOnNoPongReceived()
        
        AssertAsync {
            Assert.willBeEqual(self.webSocketClient.connectionState, .disconnecting(source: .noPongReceived))
            Assert.willBeEqual(self.engine!.disconnect_calledCount, 1)
        }
    }
    
    // MARK: - Setting a new connect endpoint
    
    func test_changingConnectEndpointAndReconnecting() {
        // Simulate connection
        test_connectionFlow()
        requestEncoder.encodeRequest_endpoints = []
        
        // Save the original engine reference
        let oldEngine = engine
        
        // Simulate connect endpoint is updated (i.e. new user is logged in)
        let newEndpoint = Endpoint<EmptyResponse>(
            path: .guest,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        webSocketClient.connectEndpoint = newEndpoint
        
        // Simulate request encoder response
        let newRequest = URLRequest(url: .unique())
        requestEncoder.encodeRequest = .success(newRequest)
        
        // Disconnect
        assert(engine!.disconnect_calledCount == 0)
        webSocketClient.disconnect {}
        AssertAsync.willBeEqual(engine!.disconnect_calledCount, 1)
        
        // Reconnect again
        webSocketClient.connect()
        XCTAssertEqual(requestEncoder.encodeRequest_endpoints.first, AnyEndpoint(newEndpoint))
        
        // Check the engine got recreated
        XCTAssert(engine !== oldEngine)
        
        AssertAsync {
            Assert.willBeEqual(self.engine!.request, newRequest)
            Assert.willBeEqual(self.engine!.connect_calledCount, 1)
        }
    }
    
    // MARK: - Event handling tests
    
    func test_connectionStatusUpdated_eventsArePublished_whenWSConnectionStateChanges() {
        // Start logging events
        let eventLogger = EventLogger(eventNotificationCenter)

        // Simulate connection state changes
        let connectionStates: [WebSocketConnectionState] = [
            .connecting,
            .connecting, // duplicate state should be ignored
            .waitingForConnectionId,
            .waitingForConnectionId, // duplicate state should be ignored
            .connected(connectionId: connectionId),
            .connected(connectionId: connectionId), // duplicate state should be ignored
            .disconnecting(source: .userInitiated),
            .disconnecting(source: .userInitiated), // duplicate state should be ignored
            .disconnected(source: .userInitiated),
            .disconnected(source: .userInitiated) // duplicate state should be ignored
        ]
        
        connectionStates.forEach { webSocketClient.simulateConnectionStatus($0) }
        
        let expectedEvents = [
            WebSocketConnectionState.connecting, // states 0...3
            .connected(connectionId: connectionId), // states 4...5
            .disconnecting(source: .userInitiated), // states 6...7
            .disconnected(source: .userInitiated) // states 8...9
        ].map {
            ConnectionStatusUpdated(webSocketConnectionState: $0).asEquatable
        }

        AssertAsync.willBeEqual(eventLogger.equatableEvents, expectedEvents)
    }
    
    func test_currentUserDTOExists_whenStateIsConnected() throws {
        // Add `EventDataProcessorMiddleware` which is responsible for saving CurrentUser
        let eventDataProcessorMiddleware = EventDataProcessorMiddleware()
        webSocketClient.eventNotificationCenter.add(middleware: eventDataProcessorMiddleware)
        
        // Simulate connection
        
        // Simulate response from the encoder
        let request = URLRequest(url: .unique())
        requestEncoder.encodeRequest = .success(request)
        
        // Assert that `CurrentUserDTO` does not exist
        var currentUser: CurrentUserDTO? {
            database.viewContext.currentUser
        }
        
        XCTAssertNil(currentUser)
        
        // Call `connect`, it should change connection state and call `connect` on the engine
        webSocketClient.connectEndpoint = endpoint
        webSocketClient.connect()
        
        AssertAsync {
            Assert.willBeEqual(self.engine!.connect_calledCount, 1)
        }
        
        // Simulate the engine is connected and check the connection state is updated
        engine!.simulateConnectionSuccess()
        AssertAsync.willBeEqual(webSocketClient.connectionState, .waitingForConnectionId)
        
        // Simulate a health check event is received and the connection state is updated
        let payloadCurrentUser = dummyCurrentUser
        let eventPayload = EventPayload(
            eventType: .healthCheck,
            connectionId: connectionId,
            cid: nil,
            currentUser: payloadCurrentUser,
            channel: nil
        )
        decoder.decodedEvent = .success(try HealthCheckEvent(from: eventPayload))
        engine!.simulateMessageReceived()
        
        // We should see `CurrentUserDTO` being saved before we get connectionId
        AssertAsync.willBeEqual(currentUser?.user.id, payloadCurrentUser.id)
        AssertAsync.willBeEqual(webSocketClient.connectionState, .connected(connectionId: connectionId))
    }
    
    func test_whenHealthCheckEventComes_itGetProcessedSilentlyWithoutBatching() throws {
        // Simulate response from the encoder
        let request = URLRequest(url: .unique())
        requestEncoder.encodeRequest = .success(request)
        
        // Assign connect endpoint
        webSocketClient.connectEndpoint = endpoint
        
        // Connect the web-socket client
        webSocketClient.connect()
        
        // Wait for engine to be called
        AssertAsync.willBeEqual(engine!.connect_calledCount, 1)
        
        // Simulate engine established connection
        engine!.simulateConnectionSuccess()
        
        // Wait for the connection state to be propagated to web-socket client
        AssertAsync.willBeEqual(webSocketClient.connectionState, .waitingForConnectionId)
        
        // Simulate received health check event
        let healthCheckEvent = HealthCheckEvent(connectionId: .unique)
        decoder.decodedEvent = .success(healthCheckEvent)
        engine!.simulateMessageReceived()
        
        // Assert healtch check event does not get batched
        let batchedEvents = eventsBatcher.mock_append.calls.map(\.asEquatable)
        XCTAssertFalse(batchedEvents.contains(healthCheckEvent.asEquatable))
        
        // Assert health check event was processed
        let (_, postNotification, _) = try XCTUnwrap(
            eventNotificationCenter.mock_process.calls.first(where: { events, _, _ in
                events.first is HealthCheckEvent
            })
        )
        
        // Assert health check events was not posted
        XCTAssertFalse(postNotification)
    }
        
    func test_whenNonHealthCheckEventComes_getsBatchedAndPostedAfterProcessing() throws {
        // Simulate connection
        test_connectionFlow()
        
        // Clear state
        eventsBatcher.mock_append.calls.removeAll()
        eventNotificationCenter.mock_process.calls.removeAll()
        
        // Simulate incoming event
        let incomingEvent = UserPresenceChangedEvent(user: .unique, createdAt: .unique)
        decoder.decodedEvent = .success(incomingEvent)
        engine!.simulateMessageReceived()
        
        // Assert event gets batched
        XCTAssertEqual(
            eventsBatcher.mock_append.calls.map(\.asEquatable),
            [incomingEvent.asEquatable]
        )
        
        // Assert incoming event get processed and posted
        let (events, postNotifications, completion) = try XCTUnwrap(eventNotificationCenter.mock_process.calls.first)
        XCTAssertEqual(events.map(\.asEquatable), [incomingEvent.asEquatable])
        XCTAssertTrue(postNotifications)
        XCTAssertNotNil(completion)
    }
    
    func test_whenDisconnectHappens_immidiateBatchedEventsProcessingIsTriggered() {
        // Simulate connection
        test_connectionFlow()
        
        // Assert `processImmediately` was not triggered
        XCTAssertFalse(eventsBatcher.mock_processImmediately.called)
        
        // Simulate disconnection
        var completionCalled = false
        webSocketClient.disconnect {
            completionCalled = true
        }
        
        // Assert `processImmediately` is triggered
        AssertAsync.willBeTrue(eventsBatcher.mock_processImmediately.called)
        XCTAssertFalse(completionCalled)
        
        // Simulate batch processing completion
        eventsBatcher.mock_processImmediately.calls.last?()
        
        // Assert completion called
        XCTAssertTrue(completionCalled)
    }
}
