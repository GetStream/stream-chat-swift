//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class MissingEventsPublisher_Tests: StressTestCase {
    typealias ExtraData = DefaultExtraData
    
    var database: DatabaseContainerMock!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var publisher: MissingEventsPublisher<ExtraData>?
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        database = try! DatabaseContainerMock(kind: .inMemory)
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        
        publisher = MissingEventsPublisher(
            database: database,
            webSocketClient: webSocketClient,
            apiClient: apiClient
        )
    }
    
    override func tearDown() {
        apiClient.cleanUp()
        
        AssertAsync {
            Assert.canBeReleased(&publisher)
            Assert.canBeReleased(&database)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
        }
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_endpointIsNotCalled_ifThereIsNoCurrentUser() throws {
        // Simulate `.connecting` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connecting)
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert endpoint is not called as `lastSyncAt` is unknown
        AssertAsync.staysTrue(apiClient.request_endpoint == nil)
    }
    
    func test_endpointIsNotCalled_ifThereAreNoWatchedChannels() throws {
        // Create current user in the database
        try database.createCurrentUser()
        
        // Set `lastReceivedEventDate` field
        try database.writeSynchronously {
            let dto = try XCTUnwrap($0.currentUser())
            dto.lastReceivedEventDate = Date()
        }
        
        // Simulate `.connecting` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connecting)
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert endpoint is not called as there are no watched channels
        AssertAsync.staysTrue(apiClient.request_endpoint == nil)
    }
    
    func test_endpointIsCalled_whenStatusBecomesConnected() throws {
        let cid: ChannelId = .unique
        let lastReceivedEventDate: Date = .unique
        
        // Create current user in the database
        try database.createCurrentUser()
        
        // Create channel in the database
        try database.createChannel(cid: cid)

        // Set `lastReceivedEventDate`
        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser())
            currentUser.lastReceivedEventDate = lastReceivedEventDate
        }
        
        // Simulate `.connecting` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connecting)
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert endpoint is called with correct values
        let endpoint: Endpoint<MissingEventsPayload<ExtraData>> = .missingEvents(
            since: lastReceivedEventDate,
            cids: [cid]
        )
        
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))
    }
    
    func test_noEventsArePublished_ifErrorResponseComes() throws {
        let cid: ChannelId = .unique

        // Create current user in the database
        try database.createCurrentUser()
        
        // Create channel in the database
        try database.createChannel(cid: cid)
        
        // Set `lastReceivedEventDate`
        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser())
            currentUser.lastReceivedEventDate = Date()
        }
        
        // Simulate `.connecting` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connecting)
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Create event logger to check published events
        let eventLogger = EventLogger(webSocketClient.init_eventNotificationCenter)
        
        // Assert a network request is created
        AssertAsync.willBeEqual(apiClient.request_allRecordedCalls.count, 1)
        
        // Simulate error response
        apiClient.test_simulateResponse(Result<MissingEventsPayload<ExtraData>, Error>.failure(TestError()))
        
        // Assert no events are published
        AssertAsync.willBeTrue(eventLogger.equatableEvents.isEmpty)
    }
    
    func test_eventsFromPayloadArePublished_ifSuccessfulResponseComes() throws {
        let json = XCTestCase.mockData(fromFile: "MissingEventsPayload")
        let payload = try JSONDecoder.default.decode(MissingEventsPayload<ExtraData>.self, from: json)
        let events = payload.eventPayloads.compactMap { try? $0.event() }
        
        // Create current user in the database
        try database.createCurrentUser()
        
        // Create channel in the database
        try database.createChannel(cid: (events.first as! EventWithChannelId).cid)
        
        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser())
            currentUser.lastReceivedEventDate = .unique
        }
        
        webSocketClient.simulateConnectionStatus(.connecting)
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Create event logger to check published events
        let eventLogger = EventLogger(webSocketClient.init_eventNotificationCenter)
        
        // Assert a network request is created
        AssertAsync.willBeEqual(apiClient.request_allRecordedCalls.count, 1)
        
        // Simulate successful response
        apiClient.test_simulateResponse(Result<MissingEventsPayload<ExtraData>, Error>.success(payload))
        
        // Assert events from payload are published
        AssertAsync.willBeEqual(eventLogger.equatableEvents, events.map(\.asEquatable))
    }
    
    func test_eventPublisher_doesNotRetainItself() throws {
        // Create current user in the database
        try database.createCurrentUser()
        
        // Create channel in the database
        try database.createChannel()
        
        // Set `lastReceivedEventDate`
        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser())
            currentUser.lastReceivedEventDate = Date()
        }
        
        // Simulate `.connecting` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connecting)
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert apiClient is called
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Assert
        AssertAsync.canBeReleased(&publisher)
    }
}
