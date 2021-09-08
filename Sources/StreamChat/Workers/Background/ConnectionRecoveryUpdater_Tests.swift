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
            useSyncEndpoint: true
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
    
    func test_whenConnectedFirstTime_currentDateIsUsedAsSyncDateAndQueriesAreNotFetched() throws {
        // Create current user in database without last sync date
        try database.createCurrentUser()
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Load current user
        let currentUser = try XCTUnwrap(database.viewContext.currentUser)
        
        AssertAsync {
            // Assert /sync is not called
            Assert.staysTrue(self.apiClient.request_endpoint == nil)
            // Assert queries are not refetched
            Assert.staysTrue(self.channelDatabaseCleanupUpdater.syncChannelListQueries_syncedChannelIDs == nil)
            // Assert `lastSyncedAt` is updated with current date
            Assert.willNotBeNil(currentUser.lastSyncedAt)
        }
    }
    
    func test_whenSyncIsNotUsedAndRefetchFails_lastSyncDateStaysTheSame() throws {
        // Create updates that should not use `/sync` endpoint
        updater = ConnectionRecoveryUpdater(
            database: database,
            eventNotificationCenter: webSocketClient.eventNotificationCenter,
            apiClient: apiClient,
            databaseCleanupUpdater: channelDatabaseCleanupUpdater,
            useSyncEndpoint: false
        )
        
        // Create current user in database
        try database.createCurrentUser()
        
        // Set `lastSyncedAt` field
        let lastSyncedAt = Date.unique
        try database.writeSynchronously {
            $0.currentUser?.lastSyncedAt = lastSyncedAt
        }
        
        // Create channels linked to queries
        let cids: Set<ChannelId> = [.unique, .unique, .unique]
        for cid in cids {
            try database.createChannel(cid: cid, withQuery: true)
        }
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        AssertAsync {
            // Assert /sync is not called
            Assert.staysTrue(self.apiClient.request_endpoint == nil)
            // Assert queries are refetched without synced channels given
            Assert.willBeEqual(self.channelDatabaseCleanupUpdater.syncChannelListQueries_syncedChannelIDs, [])
        }
        
        // Simulate failed queries refetch
        channelDatabaseCleanupUpdater.syncChannelListQueries_completion?(
            .failure(ClientError(.unique))
        )
            
        // Load current user
        let currentUser = try XCTUnwrap(database.viewContext.currentUser)
        
        // Assert `lastSyncedAt` stays the same
        AssertAsync.staysEqual(currentUser.lastSyncedAt, lastSyncedAt)
    }
    
    func test_whenSyncIsNotUsedAndRefetchSucceeds_lastSyncDateIsBumped() throws {
        // Create updates that should not use `/sync` endpoint
        updater = ConnectionRecoveryUpdater(
            database: database,
            eventNotificationCenter: webSocketClient.eventNotificationCenter,
            apiClient: apiClient,
            databaseCleanupUpdater: channelDatabaseCleanupUpdater,
            useSyncEndpoint: false
        )
        
        // Create current user in database
        try database.createCurrentUser()
        
        // Set `lastSyncedAt` field
        let lastSyncedAt = Date.unique
        try database.writeSynchronously {
            $0.currentUser?.lastSyncedAt = lastSyncedAt
        }
        
        // Create channels linked to queries
        let cids: Set<ChannelId> = [.unique, .unique, .unique]
        for cid in cids {
            try database.createChannel(cid: cid, withQuery: true)
        }
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        AssertAsync {
            // Assert /sync is not called
            Assert.staysTrue(self.apiClient.request_endpoint == nil)
            // Assert queries are refetched without synced channels given
            Assert.willBeEqual(self.channelDatabaseCleanupUpdater.syncChannelListQueries_syncedChannelIDs, [])
        }
        
        // Simulate successful queries refetch
        channelDatabaseCleanupUpdater.syncChannelListQueries_completion?(.success(()))
            
        // Load current user
        let currentUser = try XCTUnwrap(database.viewContext.currentUser)
            
        // Assert `lastSyncedAt` is updated with current date
        AssertAsync.willBeTrue(currentUser.lastSyncedAt! > lastSyncedAt)
    }
    
    func test_whenSyncReturnsEvents_eventsArePosted() throws {
        // Create current user in the database
        try database.createCurrentUser()
        
        // Set `lastSyncedAt` field
        try database.writeSynchronously {
            $0.currentUser?.lastSyncedAt = Date()
        }
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert /sync is called
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Setup event logger
        let eventLogger = EventLogger(webSocketClient.init_eventNotificationCenter)
        
        // Simulate successful response
        let payload = MissingEventsPayload(
            eventPayloads: [
                .init(eventType: .messageNew),
                .init(eventType: .channelHidden)
            ]
        )
        apiClient.test_simulateResponse(.success(payload))
        
        // Assert received events are posted
        AssertAsync.willBeEqual(
            eventLogger.equatableEvents,
            payload
                .eventPayloads
                .compactMap { try? $0.event() }
                .map(\.asEquatable)
        )
    }
    
    func test_whenSyncReturnsEventsAndRefetchSucceeds_lastSyncIsSetToMostRecentEventTimestamp() throws {
        // Create current user in the database
        try database.createCurrentUser()
        
        // Set `lastSyncedAt` field
        try database.writeSynchronously {
            $0.currentUser?.lastSyncedAt = Date()
        }
        
        // Create channels linked to queries
        let cids: Set<ChannelId> = [.unique, .unique, .unique]
        for cid in cids {
            try database.createChannel(cid: cid, withQuery: true)
        }
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert /sync is called
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Simulate successful /sync response
        let olderEvent = EventPayload(
            eventType: .messageNew,
            createdAt: Date()
        )
        let newerEvent = EventPayload(
            eventType: .messageNew,
            createdAt: Date().addingTimeInterval(10)
        )
        apiClient.test_simulateResponse(
            .success(
                MissingEventsPayload(
                    eventPayloads: [olderEvent, newerEvent]
                )
            )
        )
        
        // Assert `syncChannelListQueries` is invoked with local channels as synced
        AssertAsync.willBeEqual(
            channelDatabaseCleanupUpdater.syncChannelListQueries_syncedChannelIDs,
            cids
        )
        
        // Simulate successful queries refetch
        channelDatabaseCleanupUpdater.syncChannelListQueries_completion?(.success(()))
        
        // Load current user
        let currentUser = try XCTUnwrap(database.viewContext.currentUser)
        
        // Assert `lastSyncedAt` equals most recent event timestamp
        AssertAsync.willBeEqual(currentUser.lastSyncedAt, newerEvent.createdAt)
    }
    
    func test_whenSyncReturnsEventsButRefetchFails_lastSyncDateStaysTheSame() throws {
        // Create current user in the database
        try database.createCurrentUser()
        
        // Set `lastSyncedAt` field
        let lastSyncedAt = Date()
        try database.writeSynchronously {
            $0.currentUser?.lastSyncedAt = lastSyncedAt
        }
        
        // Create channels linked to queries
        let cids: Set<ChannelId> = [.unique, .unique, .unique]
        for cid in cids {
            try database.createChannel(cid: cid, withQuery: true)
        }
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert /sync is called
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Simulate successful /sync response
        let olderEvent = EventPayload(
            eventType: .messageNew,
            createdAt: Date()
        )
        let newerEvent = EventPayload(
            eventType: .messageNew,
            createdAt: Date().addingTimeInterval(10)
        )
        apiClient.test_simulateResponse(
            .success(
                MissingEventsPayload(
                    eventPayloads: [olderEvent, newerEvent]
                )
            )
        )
        
        // Assert `syncChannelListQueries` is invoked with local channels as synced
        AssertAsync.willBeEqual(
            channelDatabaseCleanupUpdater.syncChannelListQueries_syncedChannelIDs,
            cids
        )
        
        // Simulate failed queries refetch
        channelDatabaseCleanupUpdater.syncChannelListQueries_completion?(
            .failure(ClientError(.unique))
        )
        
        // Load current user
        let currentUser = try XCTUnwrap(database.viewContext.currentUser)
        
        // Assert `lastSyncedAt` stays the same
        AssertAsync.staysEqual(currentUser.lastSyncedAt, lastSyncedAt)
    }
    
    func test_whenSyncReturnsZeroEventsAndRefetchSucceeds_lastSyncDateStaysTheSame() throws {
        // Create current user in the database
        try database.createCurrentUser()
        
        // Set `lastSyncedAt` field
        let lastSyncedAt: Date = .unique
        try database.writeSynchronously {
            $0.currentUser?.lastSyncedAt = lastSyncedAt
        }
        
        // Create channels linked to queries
        let cids: Set<ChannelId> = [.unique, .unique, .unique]
        for cid in cids {
            try database.createChannel(cid: cid, withQuery: true)
        }
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert /sync is called
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Simulate successful /sync response
        apiClient.test_simulateResponse(
            .success(MissingEventsPayload(eventPayloads: []))
        )
        
        // Assert `syncChannelListQueries` is invoked with local channels as synced
        AssertAsync.willBeEqual(
            channelDatabaseCleanupUpdater.syncChannelListQueries_syncedChannelIDs,
            cids
        )
        
        // Simulate successful queries refetch
        channelDatabaseCleanupUpdater.syncChannelListQueries_completion?(.success(()))
        
        // Load current user
        let currentUser = try XCTUnwrap(database.viewContext.currentUser)
        
        // Assert `lastSyncedAt` stays the same
        AssertAsync.staysEqual(currentUser.lastSyncedAt, lastSyncedAt)
    }
    
    func test_whenSyncReturnsZeroEventsAndRefetchFails_lastSyncDateStaysTheSame() throws {
        // Create current user in the database
        try database.createCurrentUser()
        
        // Set `lastSyncedAt` field
        let lastSyncedAt: Date = .unique
        try database.writeSynchronously {
            $0.currentUser?.lastSyncedAt = lastSyncedAt
        }
        
        // Create channels linked to queries
        let cids: Set<ChannelId> = [.unique, .unique, .unique]
        for cid in cids {
            try database.createChannel(cid: cid, withQuery: true)
        }
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert /sync is called
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Simulate successful /sync response
        apiClient.test_simulateResponse(
            .success(MissingEventsPayload(eventPayloads: []))
        )
        
        // Assert `syncChannelListQueries` is invoked with local channels as synced
        AssertAsync.willBeEqual(
            channelDatabaseCleanupUpdater.syncChannelListQueries_syncedChannelIDs,
            cids
        )
        
        // Simulate failed queries refetch
        channelDatabaseCleanupUpdater.syncChannelListQueries_completion?(
            .failure(ClientError(.unique))
        )
        
        // Load current user
        let currentUser = try XCTUnwrap(database.viewContext.currentUser)
        
        // Assert `lastSyncedAt` stays the same
        AssertAsync.staysEqual(currentUser.lastSyncedAt, lastSyncedAt)
    }
    
    func test_whenSyncFailsButRefetchSucceeds_lastSyncDateIsChangedToCurrentDate() throws {
        // Create current user in the database
        try database.createCurrentUser()
        
        // Set `lastSyncedAt` field
        let lastSyncedAt = Date()
        try database.writeSynchronously {
            $0.currentUser?.lastSyncedAt = lastSyncedAt
        }
        
        // Create channels linked to queries
        let cids: Set<ChannelId> = [.unique, .unique, .unique]
        for cid in cids {
            try database.createChannel(cid: cid, withQuery: true)
        }
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert /sync is called
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Simulate error from /sync endpoint
        let tooManyEventsError = ClientError(
            with: ErrorPayload(
                code: 0,
                message: "",
                statusCode: 400
            )
        )
        apiClient.test_simulateResponse(
            Result<MissingEventsPayload, Error>.failure(tooManyEventsError)
        )
        
        // Assert `syncChannelListQueries` is invoked with empty synced channels
        AssertAsync.willBeEqual(
            channelDatabaseCleanupUpdater.syncChannelListQueries_syncedChannelIDs,
            []
        )
        
        // Simulate successful queries refetch
        channelDatabaseCleanupUpdater.syncChannelListQueries_completion?(.success(()))
        
        // Load current user
        let currentUser = try XCTUnwrap(database.viewContext.currentUser)
        
        // Assert `lastSyncedAt` is updated with the current date
        AssertAsync.willBeTrue(currentUser.lastSyncedAt! > lastSyncedAt)
    }
    
    func test_whenSyncAndRefetchFail_lastSyncDateStaysTheSame() throws {
        // Create current user in the database
        try database.createCurrentUser()
        
        // Set `lastSyncedAt` field
        let lastSyncedAt: Date = .unique
        try database.writeSynchronously {
            $0.currentUser?.lastSyncedAt = lastSyncedAt
        }
        
        // Create channels linked to queries
        let cids: Set<ChannelId> = [.unique, .unique, .unique]
        for cid in cids {
            try database.createChannel(cid: cid, withQuery: true)
        }
        
        // Simulate `.connected` connection state of a web-socket
        webSocketClient.simulateConnectionStatus(.connected(connectionId: .unique))
        
        // Assert /sync is called
        AssertAsync.willBeTrue(apiClient.request_endpoint != nil)
        
        // Simulate too many events error from /sync
        let tooManyEventsError = ClientError(
            with: ErrorPayload(
                code: 0,
                message: "",
                statusCode: 400
            )
        )
        apiClient.test_simulateResponse(
            Result<MissingEventsPayload, Error>.failure(tooManyEventsError)
        )
        
        // Assert `syncChannelListQueries` is invoked with empty synced channels
        AssertAsync.willBeEqual(
            channelDatabaseCleanupUpdater.syncChannelListQueries_syncedChannelIDs,
            []
        )
        
        // Simulate failed queries refetch
        channelDatabaseCleanupUpdater.syncChannelListQueries_completion?(
            .failure(ClientError(.unique))
        )
        
        // Load current user
        let currentUser = try XCTUnwrap(database.viewContext.currentUser)
        
        // Assert `lastSyncedAt` stays the same
        AssertAsync.staysEqual(currentUser.lastSyncedAt, lastSyncedAt)
    }
    
    func test_eventPublisher_doesNotRetainItself() throws {
        // Create current user in the database
        try database.createCurrentUser()
        
        // Create channel in the database
        try database.createChannel(withQuery: true)
        
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
                
        // Assert
        AssertAsync.canBeReleased(&updater)
    }
}
