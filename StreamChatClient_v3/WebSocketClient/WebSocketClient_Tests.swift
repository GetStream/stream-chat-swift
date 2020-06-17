//
// WebSocketClient_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

final class WebSocketClient_Tests: XCTestCase {
    struct TestEvent: Event, Equatable {
        static let eventRawType = "test_event"
        let id = UUID()
    }
    
    // The longest time WebSocket waits to reconnect.
    let maxReconnectTimeout: VirtualTime.Seconds = 25
    
    var webSocketClient: WebSocketClient!
    
    var time: VirtualTime!
    var reuqest: URLRequest!
    private var decoder: EventDecoderMock!
    private var reconnectionStrategy: MockReconnectionStrategy!
    var engine: WebSocketEngineMock!
    var connectionId: String!
    var user: User!
    var backgroundTaskScheduler: MockBackgroundTaskScheduler!
    
    var eventNotificationCenter: NotificationCenter!
    
    override func setUp() {
        super.setUp()
        
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        reuqest = URLRequest(url: URL.unique())
        decoder = EventDecoderMock()
        engine = WebSocketEngineMock()
        backgroundTaskScheduler = MockBackgroundTaskScheduler()
        
        eventNotificationCenter = NotificationCenter()
        reconnectionStrategy = MockReconnectionStrategy()
        
        var environment = WebSocketClient.Environment()
        environment.engineBuilder = { _, _ in self.engine }
        environment.notificationCenterBuilder = { self.eventNotificationCenter }
        environment.timer = VirtualTimeTimer.self
        environment.backgroundTaskScheduler = backgroundTaskScheduler
        
        webSocketClient = WebSocketClient(urlRequest: reuqest,
                                          eventDecoder: decoder,
                                          eventMiddlewares: [],
                                          reconnectionStrategy: reconnectionStrategy,
                                          environment: environment)
        
        connectionId = UUID().uuidString
        user = User(id: "test_user_\(UUID().uuidString)")
    }
    
    override func tearDown() {
        // Check there are no memory leaks
        weak var weakReference = webSocketClient
        webSocketClient = nil
        XCTAssertNil(weakReference)
        
        super.tearDown()
    }
    
    // MARK: - Connection tests
    
    func test_connectionFlow() {
        assert(webSocketClient.connectionState == .notConnected())
        assert(engine.connect_calledCount == 0)
        
        // Call `connect`, it should change connection state and call `connect` on the engine
        webSocketClient.connect()
        XCTAssertEqual(webSocketClient.connectionState, .connecting)
        AssertAsync.willBeEqual(engine.connect_calledCount, 1)
        
        // Simulate the engine is connected and check the connection state is updated
        engine.simulateConnectionSuccess()
        AssertAsync.willBeEqual(webSocketClient.connectionState, .waitingForConnectionId)
        
        // Simulate a health check event is received and the connection state is updated
        decoder.decodedEvent = HealthCheck(connectionId: connectionId)
        engine.simulateMessageReceived()
        
        AssertAsync.willBeEqual(webSocketClient.connectionState, .connected(connectionId: connectionId))
    }
    
    func test_callingConnect_whenAlreadyConnected_hasNoEffect() {
        // Simulate connection
        test_connectionFlow()
        
        assert(webSocketClient.connectionState == .connected(connectionId: connectionId))
        assert(engine.connect_calledCount == 1)
        
        // Call connect and assert it has no effect
        webSocketClient.connect()
        AssertAsync {
            Assert.staysTrue(self.engine.connect_calledCount == 1)
            Assert.staysTrue(self.webSocketClient.connectionState == .connected(connectionId: self.connectionId))
        }
    }
    
    func test_callingConnect_whenWaitingForReconnection_connectsImmediately() {
        // Simulate reconnection state
        test_connectionFlow()
        assert(reconnectionStrategy.reconnectionDelay_calledWithError == nil)
        reconnectionStrategy.reconnectionDelay = 20
        engine.simulateDisconnect()
        
        assert(webSocketClient.connectionState == .waitingForReconnect())
        // Reset counters
        engine.connect_calledCount = 0
        engine.disconnect_calledCount = 0
        
        // Call connect and assert calls `connect`
        webSocketClient.connect()
        AssertAsync {
            Assert.willBeTrue(self.webSocketClient.connectionState == .connecting)
            Assert.willBeTrue(self.engine.connect_calledCount == 1)
        }
    }
    
    func test_disconnect() {
        // Simulate connection
        test_connectionFlow()
        
        assert(webSocketClient.connectionState == .connected(connectionId: connectionId))
        assert(engine.disconnect_calledCount == 0)
        
        // Call `disconnect`, it should change connection state and call `disconnect` on the engine
        webSocketClient.disconnect()
        XCTAssertEqual(webSocketClient.connectionState, .disconnecting(source: .userInitiated))
        AssertAsync.willBeEqual(engine.disconnect_calledCount, 1)
        
        // Simulate the engine is disconnected and check the connection state is updated
        engine.simulateDisconnect()
        AssertAsync.willBeEqual(webSocketClient.connectionState, .notConnected())
    }
    
    func test_reconnectionStrategy_successfullyConnectedIsCalled() {
        assert(reconnectionStrategy.sucessfullyConnected_calledCount == 0)
        
        // Simulate connection
        webSocketClient.connect()
        engine.simulateConnectionSuccess()
        
        // `sucessfullyConnected` shouldn't be called before the first health check event arrives
        AssertAsync.staysTrue(reconnectionStrategy.sucessfullyConnected_calledCount == 0)
        
        // Simulate a health check event
        decoder.decodedEvent = HealthCheck(connectionId: connectionId)
        engine.simulateMessageReceived()
        
        // `sucessfullyConnected` should be called now
        AssertAsync.willBeEqual(reconnectionStrategy.sucessfullyConnected_calledCount, 1)
    }
    
    func test_reconnectionStrategy_reconnectionDelayIsRequestedAndUsed() {
        // Simulate connection
        test_connectionFlow()
        assert(reconnectionStrategy.reconnectionDelay_calledWithError == nil)
        engine.connect_calledCount = 0 // Reset the counter
        
        // Make the reconnection strategy return 20 seconds
        reconnectionStrategy.reconnectionDelay = 20
        
        // Simulate the engine disconnects
        let testError = WebSocketEngineError(reason: UUID().uuidString, code: 0, engineError: nil)
        engine.simulateDisconnect(testError)
        
        AssertAsync {
            Assert.willBeEqual(self.reconnectionStrategy.reconnectionDelay_calledWithError as? WebSocketEngineError, testError)
            Assert.willBeEqual(self.webSocketClient.connectionState,
                               .waitingForReconnect(error: ClientError.WebSocketError(with: testError)))
        }
        
        // Simulate 10 seconds passed and check `connect` is not called yet
        time.run(numberOfSeconds: 10)
        AssertAsync.staysEqual(engine.connect_calledCount, 0)
        
        // Simulate another 11 seconds passed and `connect` is called now
        time.run(numberOfSeconds: 11)
        AssertAsync.willBeEqual(engine.connect_calledCount, 1)
    }
    
    func test_reconnectionStrategy_reconnectionNotHappeningWhenNilIsReturned() {
        // Simulate connection
        test_connectionFlow()
        engine.connect_calledCount = 0 // Reset the counter
        
        // Make the reconnection strategy return `nil``
        reconnectionStrategy.reconnectionDelay = nil
        
        // Simulate the engine disconnects and check `connectionState` is updated
        engine.simulateDisconnect()
        AssertAsync.willBeEqual(webSocketClient.connectionState, .notConnected())
        
        // Simulate time passed and make sure `connect` is not called
        time.run(numberOfSeconds: 60)
        AssertAsync.staysTrue(engine.connect_calledCount == 0)
    }
    
    func test_reconnectionStrategy_notCalledWhenDisconnectedManually() {
        // Simulate connection
        test_connectionFlow()
        engine.connect_calledCount = 0 // Reset the counter
        
        // Make the reconnection return 10 seconds
        reconnectionStrategy.reconnectionDelay = 10
        
        // Simulate manual disconnect
        webSocketClient.disconnect()
        engine.simulateDisconnect()
        
        // Simulate time passed and make sure `connect` is not called
        time.run(numberOfSeconds: 60)
        AssertAsync.staysTrue(engine.connect_calledCount == 0)
    }
    
    func test_pingIsSentPeriodically() {
        // Simulate connection
        test_connectionFlow()
        
        let pingInterval = WebSocketClient.pingTimeInterval
        assert(engine.sendPing_calledCount == 0)
        
        // Simulate time longer than pingTimeInterval and assert `engine.sendPing` was called
        time.run(numberOfSeconds: pingInterval + 1)
        XCTAssertEqual(engine.sendPing_calledCount, 1)
        
        // Simulate time 3x longer than pingTimeInterval and assert 3 more pings
        time.run(numberOfSeconds: 3 * pingInterval)
        XCTAssertEqual(engine.sendPing_calledCount, 1 + 3)
    }
    
    // MARK: - Event handling tests
    
    func test_incomingEventIsPublished() {
        // Simulate connection
        test_connectionFlow()
        
        // Make the decoder always return TestEvent
        let testEvent = TestEvent()
        decoder.decodedEvent = testEvent
        
        // Start logging events
        let eventLogger = EventLogger(eventNotificationCenter)
        
        // Simulate incoming data
        let incomingData = UUID().uuidString.data(using: .utf8)!
        engine.simulateMessageReceived(incomingData)
        
        // Assert that the decoder is used with correct data and the event decoder returns is published
        AssertAsync {
            Assert.willBeEqual(self.decoder.decode_calledWithData, incomingData)
            Assert.willBeEqual(eventLogger.events, [testEvent])
        }
    }
    
    func test_incomingEvent_processedUsingMiddlewares() {
        // Simulate connection
        test_connectionFlow()
        
        // Make the decoder return an event
        let incomingEvent = TestEvent()
        decoder.decodedEvent = incomingEvent
        
        let processedEvent = TestEvent()
        webSocketClient.middlewares = [ClosureBasedMiddleware { middlewareIncomingEvent, completion in
            XCTAssertEqual(incomingEvent.asEquatable, middlewareIncomingEvent.asEquatable)
            completion(processedEvent)
    }]
        
        // Start logging events
        let eventLogger = EventLogger(eventNotificationCenter)
        
        // Simulate incoming event
        engine.simulateMessageReceived()
        
        // Assert the published event is the one from the middleware
        AssertAsync.willBeEqual(eventLogger.equatableEvents, [processedEvent.asEquatable])
    }
    
    // MARK: - Background task tests
    
    func test_backgroundTaskIsCreated_whenWebSocketIsConnected_andAppGoesToBackground() {
        // Simulate connection
        test_connectionFlow()
        assert(backgroundTaskScheduler.beginBackgroundTask_called == false)
        
        // Set up mock response
        backgroundTaskScheduler.beginBackgroundTask = UIBackgroundTaskIdentifier(rawValue: .random(in: 1 ... 100))
        
        // Simulate app going to the background
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Check a new background task is scheduled
        AssertAsync.willBeTrue(backgroundTaskScheduler.beginBackgroundTask_called)
    }
    
    func test_backgroundTaskIsNotCreated_whenWebSocketIsConnected_appGoesToBackground_andBackgroundConnectionIsForbidden() {
        // Simulate connection
        test_connectionFlow()
        assert(backgroundTaskScheduler.beginBackgroundTask_called == false)
        
        // Turn off background connection
        webSocketClient.options.remove(.staysConnectedInBackground)
        
        // Set up mock response
        backgroundTaskScheduler.beginBackgroundTask = UIBackgroundTaskIdentifier(rawValue: .random(in: 1 ... 100))
        
        // Simulate app going to the background
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Check a new background task is scheduled
        AssertAsync.staysTrue(backgroundTaskScheduler.beginBackgroundTask_called == false)
    }
    
    func test_backgroundTaskIsNotCreated_whenWebSocketIsNotConnected_andAppGoesToBackground() {
        assert(backgroundTaskScheduler.beginBackgroundTask_called == false)
        
        // Simulate app going to the background
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Check a new background task is not scheduled
        AssertAsync.staysTrue(backgroundTaskScheduler.beginBackgroundTask_called == false)
    }
    
    func test_backgroundTaskIsNotCreated_whenWebSocketIsDisconnected_andAppGoesToBackground() {
        // Simulate disconnection
        test_disconnect()
        
        assert(backgroundTaskScheduler.beginBackgroundTask_called == false)
        
        // Simulate app going to the background
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Check a new background task is not scheduled
        AssertAsync.staysTrue(backgroundTaskScheduler.beginBackgroundTask_called == false)
    }
    
    func test_connectionIsTerminated_whenBackgroundTaskCantBeInitiated() {
        // Simulate connection and start a background task
        test_connectionFlow()
        
        assert(engine.disconnect_calledCount == 0)
        
        // Simulate the background task can't be scheduled
        backgroundTaskScheduler.beginBackgroundTask = .invalid
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Check the connection is terminated
        AssertAsync {
            Assert.willBeEqual(self.engine.disconnect_calledCount, 1)
            Assert.willBeEqual(self.webSocketClient.connectionState, .disconnecting(source: .systemInitiated))
        }
    }
    
    func test_connectionIsTerminated_whenBackgroundTaskFinishesExecution() {
        // Simulate connection and start a background task
        test_connectionFlow()
        backgroundTaskScheduler.beginBackgroundTask = UIBackgroundTaskIdentifier(rawValue: .random(in: 1 ... 100))
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        assert(engine.disconnect_calledCount == 0)
        
        // Simulate the background task finishes execution
        backgroundTaskScheduler.beginBackgroundTask_expirationHandler?()
        
        // Check the connection is terminated
        AssertAsync {
            Assert.willBeEqual(self.engine.disconnect_calledCount, 1)
            Assert.willBeEqual(self.webSocketClient.connectionState, .disconnecting(source: .systemInitiated))
        }
    }
    
    func test_backgroundTaskIsCancelled_whenAppBecomesActive() {
        // Simulate connection and start a background task
        test_connectionFlow()
        let task = UIBackgroundTaskIdentifier(rawValue: .random(in: 1 ... 100))
        backgroundTaskScheduler.beginBackgroundTask = task
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Wait for `beginBackgroundTask` being called since it can be done asynchronously
        AssertAsync.willBeTrue(backgroundTaskScheduler.beginBackgroundTask_called)
        assert(backgroundTaskScheduler.endBackgroundTask_called == nil)
        
        // Simulate an app going to the foreground
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // Check the background task is terminated
        AssertAsync.willBeEqual(backgroundTaskScheduler.endBackgroundTask_called, task)
    }
    
    func test_backgroundTaskIsCancelled_whenDisconnected() {
        // Simulate connection and start a background task
        test_connectionFlow()
        let task = UIBackgroundTaskIdentifier(rawValue: .random(in: 1 ... 100))
        backgroundTaskScheduler.beginBackgroundTask = task
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Wait for `beginBackgroundTask` being called since it can be done asynchronously
        AssertAsync.willBeTrue(backgroundTaskScheduler.beginBackgroundTask_called)
        assert(backgroundTaskScheduler.endBackgroundTask_called == nil)
        
        // Simulate the connection is terminated
        webSocketClient.disconnect()
        engine.simulateDisconnect()
        
        // Check the background task is terminated
        AssertAsync.willBeEqual(backgroundTaskScheduler.endBackgroundTask_called, task)
    }
}

// MARK: - Helpers

private class EventDecoderMock: AnyEventDecoder {
    var decode_calledWithData: Data?
    var decodedEvent: Event!
    
    func decode(data: Data) throws -> Event {
        decode_calledWithData = data
        return decodedEvent
    }
}

private class EventLogger {
    var events: [Event] = []
    var equatableEvents: [EquatableEvent] { events.map(EquatableEvent.init) }
    
    init(_ notificationCenter: NotificationCenter) {
        notificationCenter.addObserver(self, selector: #selector(handleNewEvent), name: .NewEventReceived, object: nil)
    }
    
    @objc func handleNewEvent(_ notification: Notification) {
        events.append(notification.event!)
    }
}

private class MockReconnectionStrategy: WebSocketClientReconnectionStrategy {
    var sucessfullyConnected_calledCount: Int = 0
    var reconnectionDelay_calledWithError: Error?
    
    var reconnectionDelay: TimeInterval?
    
    func sucessfullyConnected() {
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

/// A test middleware that can be initiated with a closure/
private struct ClosureBasedMiddleware: EventMiddleware {
    let closure: (_ event: Event, _ completion: @escaping (Event?) -> Void) -> Void
    
    func handle(event: Event, completion: @escaping (Event?) -> Void) {
        closure(event, completion)
    }
}

class MockBackgroundTaskScheduler: BackgroundTaskScheduler {
    var beginBackgroundTask_called: Bool = false
    var beginBackgroundTask_expirationHandler: (() -> Void)?
    var beginBackgroundTask: UIBackgroundTaskIdentifier!
    
    var endBackgroundTask_called: UIBackgroundTaskIdentifier?
    
    func beginBackgroundTask(expirationHandler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        beginBackgroundTask_called = true
        beginBackgroundTask_expirationHandler = expirationHandler
        return beginBackgroundTask
    }
    
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        endBackgroundTask_called = identifier
    }
}
