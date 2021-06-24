//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class WebSocketClient_Tests: StressTestCase {
    struct TestEvent: Event, Equatable {
        let id = UUID()
    }
    
    // The longest time WebSocket waits to reconnect.
    let maxReconnectTimeout: VirtualTime.Seconds = 25
    
    var webSocketClient: WebSocketClient!
    
    var time: VirtualTime!
    var endpoint: Endpoint<EmptyResponse>!
    private var decoder: EventDecoderMock!
    private var reconnectionStrategy: MockReconnectionStrategy!
    var engine: WebSocketEngineMock? { webSocketClient.engine as? WebSocketEngineMock }
    var connectionId: String!
    var user: ChatUser!
    var requestEncoder: TestRequestEncoder!
    var pingController: WebSocketPingControllerMock { webSocketClient.pingController as! WebSocketPingControllerMock }
    var internetConnectionMonitor: InternetConnectionMonitorMock!
    
    var eventNotificationCenter: EventNotificationCenter!
    private var eventNotificationCenterMiddleware: EventMiddlewareMock!
    
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        endpoint = .webSocketConnect(
            userId: .unique
        )
        
        decoder = EventDecoderMock()
        
        reconnectionStrategy = MockReconnectionStrategy()
        
        requestEncoder = TestRequestEncoder(baseURL: .unique(), apiKey: .init(.unique))
        
        database = DatabaseContainerMock()
        eventNotificationCenter = EventNotificationCenter(database: database)
        eventNotificationCenterMiddleware = EventMiddlewareMock()
        eventNotificationCenter.add(middleware: eventNotificationCenterMiddleware)
        
        internetConnectionMonitor = InternetConnectionMonitorMock()
        
        var environment = WebSocketClient.Environment()
        environment.timerType = VirtualTimeTimer.self
        environment.createPingController = WebSocketPingControllerMock.init
        environment.createEngine = WebSocketEngineMock.init
        
        webSocketClient = WebSocketClient(
            sessionConfiguration: .ephemeral,
            requestEncoder: requestEncoder,
            eventDecoder: decoder,
            eventNotificationCenter: eventNotificationCenter,
            internetConnection: InternetConnection(monitor: internetConnectionMonitor),
            reconnectionStrategy: reconnectionStrategy,
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
        webSocketClient.disconnect()

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
        webSocketClient.disconnect()

        // Update request encode to provide different request.
        requestEncoder.encodeRequest = .success(.init(url: .unique()))
        // Simulate connect to trigger engine creation or reuse.
        webSocketClient.connect()

        // Assert engine is recreated since the connect request is changed.
        XCTAssertFalse(oldEngine === webSocketClient.engine)
    }
    
    // MARK: - Connection tests
    
    func test_connectionFlow() {
        assert(webSocketClient.connectionState == .disconnected())
        
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
    
    func test_callingConnect_whenWaitingForReconnection_connectsImmediately() {
        // Simulate reconnection state
        test_connectionFlow()
        assert(reconnectionStrategy.reconnectionDelay_calledWithError == nil)
        reconnectionStrategy.reconnectionDelay = 20
        engine!.simulateDisconnect()
        
        assert(webSocketClient.connectionState == .waitingForReconnect())
        // Reset counters
        engine!.connect_calledCount = 0
        engine!.disconnect_calledCount = 0
        
        // Call connect and assert calls `connect`
        webSocketClient.connect()
        AssertAsync {
            Assert.willBeTrue(self.webSocketClient.connectionState == .connecting)
            Assert.willBeTrue(self.engine!.connect_calledCount == 1)
        }
    }
    
    func test_disconnect() {
        // Simulate connection
        test_connectionFlow()
        
        assert(webSocketClient.connectionState == .connected(connectionId: connectionId))
        assert(engine!.disconnect_calledCount == 0)
        
        // Call `disconnect`, it should change connection state and call `disconnect` on the engine
        webSocketClient.disconnect()
        XCTAssertEqual(webSocketClient.connectionState, .disconnecting(source: .userInitiated))
        AssertAsync.willBeEqual(engine!.disconnect_calledCount, 1)
        
        // Simulate the engine is disconnected and check the connection state is updated
        engine!.simulateDisconnect()
        AssertAsync.willBeEqual(webSocketClient.connectionState, .disconnected())
    }
    
    func test_reconnectionStrategy_successfullyConnectedIsCalled() {
        assert(reconnectionStrategy.sucessfullyConnected_calledCount == 0)
        
        // Simulate response from the encoder
        let request = URLRequest(url: .unique())
        requestEncoder.encodeRequest = .success(request)
        
        // Simulate connection
        webSocketClient.connectEndpoint = endpoint
        webSocketClient.connect()
        engine!.simulateConnectionSuccess()
        
        // `sucessfullyConnected` shouldn't be called before the first health check event arrives
        AssertAsync.staysTrue(reconnectionStrategy.sucessfullyConnected_calledCount == 0)
        
        // Simulate a health check event
        decoder.decodedEvent = .success(HealthCheckEvent(connectionId: connectionId))
        engine!.simulateMessageReceived()
        
        // `sucessfullyConnected` should be called now
        AssertAsync.willBeEqual(reconnectionStrategy.sucessfullyConnected_calledCount, 1)
    }
    
    func test_reconnectionStrategy_reconnectionDelayIsRequestedAndUsed() {
        // Simulate connection
        test_connectionFlow()
        assert(reconnectionStrategy.reconnectionDelay_calledWithError == nil)
        // Reset the counter
        engine!.connect_calledCount = 0
        
        // Make the reconnection strategy return 20 seconds
        reconnectionStrategy.reconnectionDelay = 20
        
        // Simulate the engine disconnects
        let testError = WebSocketEngineError(reason: UUID().uuidString, code: 0, engineError: nil)
        engine!.simulateDisconnect(testError)
        
        AssertAsync {
            Assert.willBeEqual(self.reconnectionStrategy.reconnectionDelay_calledWithError as? WebSocketEngineError, testError)
            Assert.willBeEqual(
                self.webSocketClient.connectionState,
                .waitingForReconnect(error: ClientError.WebSocket(with: testError))
            )
        }
        
        // Simulate 10 seconds passed and check `connect` is not called yet
        time.run(numberOfSeconds: 10)
        AssertAsync.staysEqual(engine!.connect_calledCount, 0)
        
        // Simulate another 11 seconds passed and `connect` is called now
        time.run(numberOfSeconds: 11)
        AssertAsync.willBeEqual(engine!.connect_calledCount, 1)
    }
    
    func test_reconnectionStrategy_reconnectionNotHappeningWhenNilIsReturned() {
        // Simulate connection
        test_connectionFlow()
        // Reset the counter
        engine!.connect_calledCount = 0
        
        // Make the reconnection strategy return `nil``
        reconnectionStrategy.reconnectionDelay = nil
        
        // Simulate the engine disconnects and check `connectionState` is updated
        engine!.simulateDisconnect()
        AssertAsync.willBeEqual(webSocketClient.connectionState, .disconnected())
        
        // Simulate time passed and make sure `connect` is not called
        time.run(numberOfSeconds: 60)
        AssertAsync.staysTrue(engine!.connect_calledCount == 0)
    }
    
    func test_reconnectionStrategy_notCalledWhenDisconnectedManually() {
        // Simulate connection
        test_connectionFlow()
        // Reset the counter
        engine!.connect_calledCount = 0
        
        // Make the reconnection return 10 seconds
        reconnectionStrategy.reconnectionDelay = 10
        
        // Simulate manual disconnect
        webSocketClient.disconnect()
        engine!.simulateDisconnect()
        
        // Simulate time passed and make sure `connect` is not called
        time.run(numberOfSeconds: 60)
        AssertAsync.staysTrue(engine!.connect_calledCount == 0)
    }
    
    func test_connectionState_afterDecodingError() {
        // Simulate connection
        test_connectionFlow()
        
        decoder.decodedEvent = .failure(
            DecodingError.keyNotFound(
                EventPayload<NoExtraData>.CodingKeys.eventType,
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
    
    func test_pongReceived_callsPingController_pongRecieved() {
        // Simulate connection to make sure web socket engine exists
        test_connectionFlow()
        assert(pingController.pongRecievedCount == 1)
        
        // Simulate a health check (pong) event is received
        decoder.decodedEvent = .success(HealthCheckEvent(connectionId: connectionId))
        engine!.simulateMessageReceived()
        
        AssertAsync.willBeEqual(pingController.pongRecievedCount, 2)
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
        
        // Save the original engine reference
        let oldEngine = engine
        
        // Simulate connect endpoint is updated (i.e. new user is logged in)
        let newEndpoint = Endpoint<EmptyResponse>(
            path: .unique,
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
        webSocketClient.disconnect()
        AssertAsync.willBeEqual(engine!.disconnect_calledCount, 1)
        
        // Reconnect again
        webSocketClient.connect()
        XCTAssertEqual(requestEncoder.encodeRequest_endpoint, AnyEndpoint(newEndpoint))
        
        // Check the engige got recreated
        XCTAssert(engine !== oldEngine)
        
        AssertAsync {
            Assert.willBeEqual(self.engine!.request, newRequest)
            Assert.willBeEqual(self.engine!.connect_calledCount, 1)
        }
    }
    
    // MARK: - Event handling tests
    
    func test_incomingEventIsPublished() {
        // Simulate connection
        test_connectionFlow()
        
        // Make the decoder always return TestEvent
        let testEvent = TestEvent()
        decoder.decodedEvent = .success(testEvent)
        
        // Clean up pending events and start logging the new ones
        eventNotificationCenter.pendingEvents = []
        let eventLogger = EventLogger(eventNotificationCenter)
        
        // Simulate incoming data
        let incomingData = UUID().uuidString.data(using: .utf8)!
        engine!.simulateMessageReceived(incomingData)
        
        // Assert that the decoder is used with correct data and the event decoder returns is published
        AssertAsync {
            Assert.willBeEqual(self.decoder.decode_calledWithData, incomingData)
            Assert.willBeEqual(eventLogger.events, [testEvent])
        }
    }
    
    func test_incomingEvent_processedUsingMiddlewares() {
        // Simulate connection
        test_connectionFlow()
        
        // Clean up pending events
        eventNotificationCenter.pendingEvents = []

        // Make the decoder return an event
        let incomingEvent = TestEvent()
        decoder.decodedEvent = .success(incomingEvent)
        
        let processedEvent = TestEvent()
        eventNotificationCenterMiddleware.closure = { middlewareIncomingEvent, session in
            XCTAssertEqual(incomingEvent.asEquatable, middlewareIncomingEvent.asEquatable)
            XCTAssertEqual(session as? NSManagedObjectContext, self.database.writableContext)
            return processedEvent
        }
        
        // Start logging events
        let eventLogger = EventLogger(eventNotificationCenter)
        
        // Simulate incoming event
        engine!.simulateMessageReceived()
        
        // Assert the published event is the one from the middleware
        AssertAsync.willBeEqual(eventLogger.equatableEvents, [processedEvent.asEquatable])
    }
    
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
            .disconnected(),
            .disconnected() // duplicate state should be ignored
        ]
        
        connectionStates.forEach { webSocketClient.simulateConnectionStatus($0) }
        
        let expectedEvents = [
            WebSocketConnectionState.connecting, // states 0...3
            .connected(connectionId: connectionId), // states 4...5
            .disconnecting(source: .userInitiated), // states 6...7
            .disconnected() // states 8...9
        ].map {
            ConnectionStatusUpdated(webSocketConnectionState: $0).asEquatable
        }

        AssertAsync.willBeEqual(eventLogger.equatableEvents, expectedEvents)
    }
    
    func test_currentUserDTOExists_whenStateIsConnected() throws {
        // Add `EventDataProcessorMiddleware` which is responsible for saving CurrentUser
        let eventDataProcessorMiddleware = EventDataProcessorMiddleware<NoExtraData>()
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
        let eventPayload = EventPayload<NoExtraData>(
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
}

private struct TestEvent: Event, Equatable {
    let uuid: UUID = .init()
}

// MARK: - Helpers

private class EventDecoderMock: AnyEventDecoder {
    var decode_calledWithData: Data?
    var decodedEvent: Result<Event, Error>!
    
    func decode(from data: Data) throws -> Event {
        decode_calledWithData = data
        
        switch decodedEvent {
        case let .success(event): return event
        case let .failure(error): throw error
        case .none:
            XCTFail("Undefined state, `decodedEvent` should not be nil")
            // just dummy error to make compiler happy
            throw NSError(domain: "some error", code: 0, userInfo: nil)
        }
    }
}

private class MockReconnectionStrategy: WebSocketClientReconnectionStrategy {
    var sucessfullyConnected_calledCount: Int = 0
    var reconnectionDelay_calledWithError: Error?
    
    var reconnectionDelay: TimeInterval?
    
    func successfullyConnected() {
        sucessfullyConnected_calledCount += 1
    }
    
    func reconnectionDelay(forConnectionError error: Error?) -> TimeInterval? {
        reconnectionDelay_calledWithError = error
        return reconnectionDelay
    }
}

extension WebSocketEngineError: Equatable {
    public static func == (lhs: WebSocketEngineError, rhs: WebSocketEngineError) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}

class MockBackgroundTaskScheduler: BackgroundTaskScheduler {
    var beginBackgroundTask_called: Bool = false
    var beginBackgroundTask_expirationHandler: (() -> Void)?
    var beginBackgroundTask_returns: Bool = true
    func beginTask(expirationHandler: (() -> Void)?) -> Bool {
        beginBackgroundTask_called = true
        beginBackgroundTask_expirationHandler = expirationHandler
        return beginBackgroundTask_returns
    }

    var endBackgroundTask_called: Bool = false
    func endTask() {
        endBackgroundTask_called = true
    }

    var startListeningForAppStateUpdates_called: Bool = false
    var startListeningForAppStateUpdates_onBackground: (() -> Void)?
    var startListeningForAppStateUpdates_onForeground: (() -> Void)?
    func startListeningForAppStateUpdates(
        onEnteringBackground: @escaping () -> Void,
        onEnteringForeground: @escaping () -> Void
    ) {
        startListeningForAppStateUpdates_called = true
        startListeningForAppStateUpdates_onBackground = onEnteringBackground
        startListeningForAppStateUpdates_onForeground = onEnteringForeground
    }
}

class WebSocketPingControllerMock: WebSocketPingController {
    var connectionStateDidChange_connectionStates: [WebSocketConnectionState] = []
    var pongRecievedCount = 0
    
    override func connectionStateDidChange(_ connectionState: WebSocketConnectionState) {
        connectionStateDidChange_connectionStates.append(connectionState)
        super.connectionStateDidChange(connectionState)
    }
    
    override func pongRecieved() {
        pongRecievedCount += 1
        super.pongRecieved()
    }
}
