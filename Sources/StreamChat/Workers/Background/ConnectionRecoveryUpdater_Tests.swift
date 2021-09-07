//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ConnectionRecoveryUpdater_Tests: StressTestCase {
    var database: DatabaseContainerMock!
    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var updater: ConnectionRecoveryUpdater?
    var channelDatabaseCleanupUpdater: DatabaseCleanupUpdater_Mock!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        database = DatabaseContainerMock()
        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        channelDatabaseCleanupUpdater = DatabaseCleanupUpdater_Mock(database: database, apiClient: apiClient)
        
        updater = ConnectionRecoveryUpdater(
            database: database,
            eventNotificationCenter: webSocketClient.eventNotificationCenter,
            apiClient: apiClient,
            databaseCleanupUpdater: channelDatabaseCleanupUpdater,
            useSyncEndpoint: false
        )
    }
    
    override func tearDown() {
        apiClient.cleanUp()

        AssertAsync {
            Assert.canBeReleased(&updater)
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
        
        // Set `lastSyncedAt` field
        try database.writeSynchronously {
            let dto = try XCTUnwrap($0.currentUser)
            dto.lastSyncedAt = Date()
        }
        
        // Simulate `.connecting` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connecting)
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert endpoint is not called as there are no watched channels
        AssertAsync.staysTrue(apiClient.request_endpoint == nil)
    }
    
    func test_endpointIsCalled_whenStatusBecomesConnected() throws {
        updater = ConnectionRecoveryUpdater(
            database: database,
            eventNotificationCenter: webSocketClient.eventNotificationCenter,
            apiClient: apiClient,
            databaseCleanupUpdater: channelDatabaseCleanupUpdater,
            useSyncEndpoint: true
        )
        let cid: ChannelId = .unique
        let lastReceivedEventDate: Date = .unique
        
        // Create current user in the database
        try database.createCurrentUser()
        
        // Create channel in the database
        try database.createChannel(cid: cid, withQuery: true)

        // Set `lastSyncedAt`
        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser)
            currentUser.lastSyncedAt = lastReceivedEventDate
        }
        
        // Simulate `.connecting` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connecting)
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert endpoint is called with correct values
        let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(
            since: lastReceivedEventDate,
            cids: [cid]
        )
        
        AssertAsync.willBeEqual(apiClient.request_endpoint, AnyEndpoint(endpoint))
    }
    
    func test_noEventsArePublished_ifErrorResponseComes() throws {
        updater = ConnectionRecoveryUpdater(
            database: database,
            eventNotificationCenter: webSocketClient.eventNotificationCenter,
            apiClient: apiClient,
            databaseCleanupUpdater: channelDatabaseCleanupUpdater,
            useSyncEndpoint: true
        )
        let cid: ChannelId = .unique

        // Create current user in the database
        try database.createCurrentUser()
        
        // Create channel in the database
        try database.createChannel(cid: cid, withQuery: true)
        
        // Set `lastSyncedAt`
        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser)
            currentUser.lastSyncedAt = Date()
        }
        
        // Simulate `.connecting` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connecting)
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Get access to EventNotificationCenter to check for events and remove already logged events
        let eventCenter = webSocketClient.init_eventNotificationCenter as! EventNotificationCenterMock
        eventCenter.process_loggedEvents = []
        
        // Assert a network request is created
        AssertAsync.willBeEqual(apiClient.request_allRecordedCalls.count, 1)
        
        // Simulate error response
        apiClient.test_simulateResponse(Result<MissingEventsPayload, Error>.failure(TestError()))
        
        // Assert no events are published
        AssertAsync.staysTrue(eventCenter.process_loggedEvents.isEmpty)
    }
    
    func test_whenBackendRespondsWith400_callsChannelListCleanUp() throws {
        updater = ConnectionRecoveryUpdater(
            database: database,
            eventNotificationCenter: webSocketClient.eventNotificationCenter,
            apiClient: apiClient,
            databaseCleanupUpdater: channelDatabaseCleanupUpdater,
            useSyncEndpoint: true
        )
        let cid: ChannelId = .unique

        try database.createCurrentUser()
        try database.createChannel(cid: cid)

        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser)
            currentUser.lastSyncedAt = Date()
        }
        
        webSocketClient.simulateConnectionStatus(.connecting)
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))

        AssertAsync.willBeEqual(apiClient.request_allRecordedCalls.count, 1)

        var refetchCalled = false
        channelDatabaseCleanupUpdater.refetchExistingChannelListQueries_body = {
            refetchCalled = true
        }

        var cleanupCalledWithSession: DatabaseSession?
        channelDatabaseCleanupUpdater.resetExistingChannelsData_body = { session in
            cleanupCalledWithSession = session
            // Check refetch wasn't called yet
            XCTAssertFalse(refetchCalled)
        }
        
        apiClient.test_simulateResponse(
            Result<MissingEventsPayload, Error>.failure(
                ClientError(with: ErrorPayload(code: 0, message: "", statusCode: 400))
            )
        )

        AssertAsync {
            Assert.willBeTrue(refetchCalled)
            Assert.willBeEqual(cleanupCalledWithSession as? NSManagedObjectContext, self.database.writableContext)
        }
    }
    
    func test_eventsFromPayloadArePublished_ifSuccessfulResponseComes() throws {
        updater = ConnectionRecoveryUpdater(
            database: database,
            eventNotificationCenter: webSocketClient.eventNotificationCenter,
            apiClient: apiClient,
            databaseCleanupUpdater: channelDatabaseCleanupUpdater,
            useSyncEndpoint: true
        )
        let json = XCTestCase.mockData(fromFile: "MissingEventsPayload")
        let payload = try JSONDecoder.default.decode(MissingEventsPayload.self, from: json)
        let events = payload.eventPayloads.compactMap { try? $0.event() }
        
        // Create current user in the database
        try database.createCurrentUser()
        
        // Create channel in the database
        try database.createChannel(cid: (events.first as! ChannelSpecificEvent).cid)
        
        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser)
            currentUser.lastSyncedAt = .unique
        }
        
        webSocketClient.simulateConnectionStatus(.connecting)
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Get access to EventNotificationCenter to check for events and remove already logged events
        let eventCenter = webSocketClient.init_eventNotificationCenter as! EventNotificationCenterMock
        eventCenter.process_loggedEvents = []

        // Assert a network request is created
        AssertAsync.willBeEqual(apiClient.request_allRecordedCalls.count, 1)
        
        // Create event logger to track posted events
        let eventLogger = EventLogger(eventCenter)

        // Simulate successful response
        apiClient.test_simulateResponse(Result<MissingEventsPayload, Error>.success(payload))
        
        // Assert events from payload are published
        AssertAsync.willBeEqual(eventLogger.equatableEvents, events.map(\.asEquatable))
    }

    func test_existingQueriesAreRefetched_ifSuccessfulResponseComes() throws {
        updater = ConnectionRecoveryUpdater(
            database: database,
            eventNotificationCenter: webSocketClient.eventNotificationCenter,
            apiClient: apiClient,
            databaseCleanupUpdater: channelDatabaseCleanupUpdater,
            useSyncEndpoint: true
        )
        // Create the current user and a channel in the database
        try database.createCurrentUser()
        try database.createChannel(cid: .unique)

        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser)
            currentUser.lastSyncedAt = .unique
        }

        webSocketClient.simulateConnectionStatus(.connecting)
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))

        // Assert a network request is created
        AssertAsync.willBeEqual(apiClient.request_allRecordedCalls.count, 1)

        // Set up callbacks
        var resetChannelsDataCalled = false
        channelDatabaseCleanupUpdater.resetExistingChannelsData_body = { _ in resetChannelsDataCalled = true }

        var refetchQueriesCalled = false
        channelDatabaseCleanupUpdater.refetchExistingChannelListQueries_body = { refetchQueriesCalled = true }

        // Simulate successful response
        apiClient.test_simulateResponse(
            Result<MissingEventsPayload, Error>.success(MissingEventsPayload(eventPayloads: []))
        )

        // Assert only `refetchExistingChannelListQueries` is called
        AssertAsync {
            Assert.willBeTrue(refetchQueriesCalled)
            Assert.staysFalse(resetChannelsDataCalled)
        }
    }
    
    func test_eventPublisher_doesNotRetainItself() throws {
        updater = ConnectionRecoveryUpdater(
            database: database,
            eventNotificationCenter: webSocketClient.eventNotificationCenter,
            apiClient: apiClient,
            databaseCleanupUpdater: channelDatabaseCleanupUpdater,
            useSyncEndpoint: true
        )
        // Create current user in the database
        try database.createCurrentUser()
        
        // Create channel in the database
        try database.createChannel()
        
        // Set `lastSyncedAt`
        try database.writeSynchronously { session in
            let currentUser = try XCTUnwrap(session.currentUser)
            currentUser.lastSyncedAt = Date()
        }
        
        // Simulate `.connecting` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connecting)
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert apiClient is called
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        apiClient.test_simulateResponse(
            Result<MissingEventsPayload, Error>.success(
                MissingEventsPayload(eventPayloads: [])
            )
        )
        
        channelDatabaseCleanupUpdater.refetchExistingChannelListQueries_body()
        
        // Assert
        AssertAsync.canBeReleased(&updater)
    }
}
