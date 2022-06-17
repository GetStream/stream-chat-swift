//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SyncRepository_Tests: XCTestCase {
    var _activeChannelControllers: ThreadSafeWeakCollection<ChatChannelController>!
    var _activeChannelListControllers: ThreadSafeWeakCollection<ChatChannelListController>!
    var client: ChatClient_Mock!
    var offlineRequestsRepository: OfflineRequestsRepository_Spy!
    var database: DatabaseContainer_Spy!
    var apiClient: APIClient_Spy!

    var repository: SyncRepository!

    private var lastSyncAtValue: Date? {
        database.viewContext.currentUser?.lastSynchedEventDate?.bridgeDate
    }

    override func setUp() {
        super.setUp()

        _activeChannelControllers = ThreadSafeWeakCollection<ChatChannelController>()
        _activeChannelListControllers = ThreadSafeWeakCollection<ChatChannelListController>()
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = true
        client = ChatClient_Mock(config: config)
        let messageRepository = MessageRepository_Spy(database: client.databaseContainer, apiClient: client.apiClient)
        offlineRequestsRepository = OfflineRequestsRepository_Spy(
            messageRepository: messageRepository,
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        database = client.mockDatabaseContainer
        apiClient = client.mockAPIClient

        repository = SyncRepository(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: client.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )
    }

    override func tearDown() {
        super.tearDown()
        _activeChannelControllers = nil
        _activeChannelListControllers = nil
        client.cleanUp()
        client = nil
        offlineRequestsRepository.clear()
        offlineRequestsRepository = nil
        database = nil
        apiClient.cleanUp()
        apiClient = nil
        repository = nil
    }
    
    // MARK: - First session
    
    func test_syncLocalState_localStorageEnabled_firstSession() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: nil,
            createChannel: true
        )
        
        let expectation = expectation(description: "syncLocalState completion")
        repository.syncLocalState {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
        
        let lastSyncAt = try XCTUnwrap(lastSyncAtValue)
        XCTAssertTrue(Calendar.current.isDateInToday(lastSyncAt))
        XCTAssertNotCall("enterRecoveryMode()", on: apiClient)
    }
    
    func test_syncLocalState_localStorageDisabled_firstSession() throws {
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = false
        let client = ChatClient_Mock(config: config)
        repository = SyncRepository(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )
        
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: nil,
            createChannel: true
        )
        
        let expectation = expectation(description: "syncLocalState completion")
        repository.syncLocalState {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
        
        let lastSyncAt = try XCTUnwrap(lastSyncAtValue)
        XCTAssertTrue(Calendar.current.isDateInToday(lastSyncAt))
        XCTAssertNotCall("enterRecoveryMode()", on: apiClient)
    }

    // MARK: - Sync local state

    func test_syncLocalState_localStorageDisabled() throws {
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = false
        let client = ChatClient_Mock(config: config)
        repository = SyncRepository(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )
        
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: .init(),
            createChannel: false
        )

        waitForSyncLocalStateRun()

        XCTAssertEqual(database.writeSessionCounter, 0)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        // When isLocalStorageEnabled is false, we don't need to run any offline requests related task
        XCTAssertNotCall("runQueuedRequests(completion:)", on: offlineRequestsRepository)
    }

    func test_syncLocalState_localStorageEnabled_noChannels() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: .init(),
            createChannel: false
        )

        waitForSyncLocalStateRun()
        
        XCTAssertEqual(database.writeSessionCounter, 0)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        XCTAssertCall("runQueuedRequests(completion:)", on: offlineRequestsRepository, times: 1)
    }

    func test_syncLocalState_localStorageEnabled_pendingConnectionDate_channels() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-3600),
            createChannel: true
        )

        let firstEventDate = Date.unique
        let secondEventDate = Date.unique
        let payload = messageEventPayload(with: [firstEventDate, secondEventDate])
        waitForSyncLocalStateRun(requestResult: .success(payload))

        // Should use first event's created at date
        XCTAssertEqual(lastSyncAtValue, secondEventDate)
        // Write: API Response, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 2)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        XCTAssertCall("runQueuedRequests(completion:)", on: offlineRequestsRepository, times: 1)
    }

    func test_syncLocalState_localStorageEnabled_pendingConnectionDate_channels_activeRemoteChannelController() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-3600),
            createChannel: true
        )

        let chatController = ChatChannelController_Spy(client: client)
        chatController.state = .remoteDataFetched
        _activeChannelControllers.add(chatController)

        let eventDate = Date.unique
        waitForSyncLocalStateRun(requestResult: .success(messageEventPayload(with: [eventDate])))

        // Should use first event's created at date
        XCTAssertEqual(lastSyncAtValue, eventDate)
        // Write: API Response, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 2)
        XCTAssertEqual(repository.activeChannelControllers.count, 1)
        XCTAssertCall("recoverWatchedChannel(completion:)", on: chatController, times: 1)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        XCTAssertCall("runQueuedRequests(completion:)", on: offlineRequestsRepository, times: 1)
    }

    func test_syncLocalState_localStorageEnabled_pendingConnectionDate_channels_activeRemoteChannelListController() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-3600),
            createChannel: true
        )

        let chatListController = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        chatListController.state = .remoteDataFetched
        _activeChannelListControllers.add(chatListController)
        chatListController.resetChannelsQueryResult = .success(([], []))

        let eventDate = Date.unique
        waitForSyncLocalStateRun(requestResult: .success(messageEventPayload(with: [eventDate])))

        // Should use first event's created at date
        XCTAssertEqual(lastSyncAtValue, eventDate)
        // Write: API Response, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 2)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 1)
        XCTAssertCall(
            "resetQuery(watchedAndSynchedChannelIds:synchedChannelIds:completion:)", on: chatListController,
            times: 1
        )
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        XCTAssertCall("runQueuedRequests(completion:)", on: offlineRequestsRepository, times: 1)
    }

    func test_syncLocalState_localStorageEnabled_pendingConnectionDate_channels_activeRemoteChannelListController_unwantedChannels(
    ) throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-3600),
            createChannel: true
        )

        let chatListController = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        chatListController.state = .remoteDataFetched
        _activeChannelListControllers.add(chatListController)
        let unwantedId = ChannelId.unique
        chatListController.resetChannelsQueryResult = .success(([], [unwantedId]))

        let eventDate = Date.unique
        waitForSyncLocalStateRun(requestResult: .success(messageEventPayload(with: [eventDate])))

        // Should use first event's created at date
        XCTAssertEqual(lastSyncAtValue, eventDate)
        // Write: API Response, unwanted channels, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 3)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 1)
        XCTAssertCall(
            "resetQuery(watchedAndSynchedChannelIds:synchedChannelIds:completion:)", on: chatListController,
            times: 1
        )
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        XCTAssertCall("runQueuedRequests(completion:)", on: offlineRequestsRepository, times: 1)
    }
    
    func test_syncLocalState_ignoresTheCooldown() throws {
        let lastSyncDate = Date()
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: lastSyncDate,
            createChannel: true
        )
        
        let firstDate = lastSyncDate.addingTimeInterval(1)
        let secondDate = lastSyncDate.addingTimeInterval(2)
        let eventsPayload1 = messageEventPayload(with: [firstDate, secondDate])
        waitForSyncLocalStateRun(requestResult: .success(eventsPayload1))
        
        XCTAssertNearlySameDate(lastSyncAtValue, secondDate)
                
        let thirdDate = secondDate.addingTimeInterval(1)
        let eventsPayload2 = messageEventPayload(with: [thirdDate])
        waitForSyncLocalStateRun(requestResult: .success(eventsPayload2))
        
        XCTAssertNearlySameDate(lastSyncAtValue, thirdDate)
    }

    // MARK: - Sync existing channels events
    
    func test_syncExistingChannelsEvents_whenCooldownHasNotPassed_noNeedToSync() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-2),
            createChannel: false
        )
        
        let result = getSyncExistingChannelEventsResult()

        guard case .noNeedToSync = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }
    }

    func test_syncExistingChannelsEvents_localStorageEnabled_noChannels() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-60),
            createChannel: false
        )
        
        let result = getSyncExistingChannelEventsResult()

        guard let value = result.value else {
            XCTFail("Should return an empty array")
            return
        }

        XCTAssertEqual(value, [])
    }

    func test_syncExistingChannelsEvents_someChannels_noUser() throws {
        try database.writeSynchronously { session in
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: .unique), query: query)
        }

        let result = getSyncExistingChannelEventsResult()

        guard case .noNeedToSync = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }
    }

    func test_syncExistingChannelsEvents_someChannels_userNoLastSyncAt() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: .unique), query: query)
        }
        XCTAssertNil(lastSyncAtValue)

        let result = getSyncExistingChannelEventsResult()

        guard case .noNeedToSync = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }
    }

    func test_syncExistingChannelsEvents_someChannels_lastSyncAt_TooEarly() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: .unique), query: query)
            session.currentUser?.lastSynchedEventDate = DBDate()
        }
        let result = getSyncExistingChannelEventsResult()

        guard case .noNeedToSync = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }
    }

    func test_syncExistingChannelsEvents_someChannels_apiFailure() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = DBDate().addingTimeInterval(-3600)
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: .unique), query: query)
        }

        let result = getSyncExistingChannelEventsResult(requestResult: .failure(ClientError("something went wrong")))

        guard case let .syncEndpointFailed(error) = result.error, let clientError = error as? ClientError else {
            XCTFail("Should return .syncEndpointFailed")
            return
        }
        XCTAssertEqual(clientError.localizedDescription, "something went wrong")
    }

    func test_syncExistingChannelsEvents_someChannels_tooManyEventsError() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = DBDate().addingTimeInterval(-3600)
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: .unique), query: query)
        }

        let expectedError = ErrorPayload(code: 1, message: "Too many events", statusCode: 400, details: [])
        let result = getSyncExistingChannelEventsResult(requestResult: .failure(ClientError(with: expectedError)))

        guard let value = result.value else {
            XCTFail("Should return an empty array")
            return
        }

        XCTAssertEqual(value, [])
    }

    func test_syncExistingChannelsEvents_someChannels_apiSuccess_shouldStoreEvents() throws {
        try database.createCurrentUser(id: "123")
        let cid = try ChannelId(cid: "messaging:A2F4393C-D656-46B8-9A43-6148E9E62D7F")
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = DBDate().addingTimeInterval(-3600)
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0), query: query)
        }

        XCTAssertEqual(ChannelDTO.load(cid: cid, context: database.viewContext)?.messages.count, 0)

        let firstDate = Date.unique
        let secondDate = Date.unique
        let payload = messageEventPayload(cid: cid, with: [firstDate, secondDate])
        let result = getSyncExistingChannelEventsResult(requestResult: .success(payload))

        guard let channelIds = result.value else {
            XCTFail("Should return an empty array")
            return
        }

        let channel = ChannelDTO.load(cid: cid, context: database.viewContext)
        XCTAssertEqual(channel?.messages.count, 2)
        XCTAssertEqual(channelIds.count, 1)
        XCTAssertEqual(channelIds.first, cid)
        XCTAssertEqual(lastSyncAtValue, payload.eventPayloads.last?.createdAt)
    }

    private func getSyncExistingChannelEventsResult(requestResult: Result<MissingEventsPayload, Error>? = nil)
        -> Result<[ChannelId], SyncError> {
        let expectation = self.expectation(description: "syncExistingChannelsEvents completion")
        var receivedResult: Result<[ChannelId], SyncError>!
        repository.syncExistingChannelsEvents { result in
            receivedResult = result
            expectation.fulfill()
        }

        if let result = requestResult {
            // Simulate API Failure
            AssertAsync {
                Assert.willNotBeNil(self.apiClient.request_completion)
            }
            let callback = apiClient.request_completion as! (Result<MissingEventsPayload, Error>) -> Void
            callback(result)
        }

        waitForExpectations(timeout: 0.5, handler: nil)
        return receivedResult
    }

    // MARK: - Queue offline requests

    func test_queueOfflineRequest_localStorageDisabled() {
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = false
        let client = ChatClient_Mock(config: config)
        repository = SyncRepository(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )

        let endpoint = DataEndpoint(
            path: .guest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: true,
            body: nil
        )
        repository.queueOfflineRequest(endpoint: endpoint)

        XCTAssertNotCall("queueOfflineRequest(endpoint:completion:)", on: offlineRequestsRepository)
    }

    func test_queueOfflineRequest_localStorageEnabled() {
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = true
        let client = ChatClient_Mock(config: config)
        repository = SyncRepository(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )

        let endpoint = DataEndpoint(
            path: .guest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: true,
            body: nil
        )
        repository.queueOfflineRequest(endpoint: endpoint)

        XCTAssertCall("queueOfflineRequest(endpoint:completion:)", on: offlineRequestsRepository, times: 1)
    }
    
    // MARL: - cancelRecoveryFlow
    
    func test_cancelRecoveryFlow_existsRecoveryMode() throws {
        // GIVEN
        XCTAssertNotCall("exitRecoveryMode()", on: apiClient)
        
        // WHEN
        repository.cancelRecoveryFlow()
        
        // THEN
        XCTAssertCall("exitRecoveryMode()", on: apiClient, times: 1)
    }
    
    func test_syncLocalState_cancelsRecoveryFlow() throws {
        // GIVEN
        let mock = CancelRecoveryFlowTracker(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )
        
        var cancelRecoveryFlowCalled = false
        mock.cancelRecoveryFlowClosure = {
            cancelRecoveryFlowCalled = true
        }
        
        // WHEN
        mock.syncLocalState(completion: {})
        
        // THEN
        XCTAssertTrue(cancelRecoveryFlowCalled)
    }
    
    func test_deinit_cancelsRecoveryFlow() throws {
        // GIVEN
        var mock: CancelRecoveryFlowTracker? = .init(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )
        
        let expectation = expectation(description: "cancelRecoveryFlow completion")
        mock?.cancelRecoveryFlowClosure = {
            expectation.fulfill()
        }
        
        // WHEN
        mock = nil
        
        // THEN
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func test_cancelRecoveryFlow_cancelsAllOperations() throws {
        // Prepare environment
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date(),
            createChannel: true
        )
        
        // Add active channel component
        let channelQuery = ChannelQuery(cid: .unique)
        let channelController = ChatChannelController(channelQuery: channelQuery, channelListQuery: nil, client: client)
        channelController.state = .remoteDataFetched
        _activeChannelControllers.add(channelController)
        
        // Add active channel list component
        let channelListController = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        channelListController.state = .remoteDataFetched
        _activeChannelListControllers.add(channelListController)

        // Sync local state
        var completionCalled = false
        repository.syncLocalState {
            completionCalled = true
        }
        
        // Wait for /sync to be called
        AssertAsync.willBeTrue(apiClient.recoveryRequest_completion != nil)
        
        // Let /sync operation to complete
        let syncResponse = Result<MissingEventsPayload, Error>.success(.init(eventPayloads: []))
        apiClient.test_simulateRecoveryResponse(syncResponse)
        apiClient.recoveryRequest_completion = nil
        
        // Wait for watch operation
        AssertAsync.willBeTrue(apiClient.recoveryRequest_completion != nil)
        
        // Cancel recovery flow
        repository.cancelRecoveryFlow()
        
        // Let watch operation to complete
        let watchResponse = Result<ChannelPayload, Error>.success(dummyPayload(with: channelQuery.cid!))
        apiClient.test_simulateRecoveryResponse(watchResponse)
        
        // Assert left operations are not executed
        AssertAsync {
            Assert.staysTrue(channelListController.recordedFunctions.isEmpty)
            Assert.staysFalse(completionCalled)
        }
    }
}

extension SyncRepository_Tests {
    func messageEventPayload(cid: ChannelId = .unique, with dates: [Date]) -> MissingEventsPayload {
        MissingEventsPayload(eventPayloads: dates.map {
            EventPayload(
                eventType: .messageNew,
                cid: cid,
                user: .dummy(userId: ""),
                message: .dummy(messageId: "\($0)", authorUserId: .unique, latestReactions: [], channel: .dummy(cid: cid)),
                createdAt: $0
            )
        })
    }

    private func prepareForSyncLocalStorage(
        createUser: Bool,
        lastSynchedEventDate: Date?,
        createChannel: Bool
    ) throws {
        if createUser {
            try database.createCurrentUser()
        }

        try database.writeSynchronously { session in
            if let lastSynchedEventDate = lastSynchedEventDate {
                session.currentUser?.lastSynchedEventDate = lastSynchedEventDate.bridgeDate
            }
            if createChannel {
                let query = ChannelListQuery(filter: .exists(.cid))
                try session.saveChannel(payload: self.dummyPayload(with: .unique, numberOfMessages: 0), query: query)
            }
        }
        database.writeSessionCounter = 0
    }

    private func waitForSyncLocalStateRun(requestResult: Result<MissingEventsPayload, Error>? = nil) {
        database.writeSessionCounter = 0
        apiClient.recordedFunctions.removeAll()
        
        let expectation = self.expectation(description: "syncLocalState completion")
        repository.syncLocalState {
            expectation.fulfill()
        }

        AssertAsync.willBeTrue(
            "enterRecoveryMode()".wasCalled(on: apiClient, times: 1)
        )
        
        if let result = requestResult {
            // Simulate API Failure
            AssertAsync.willBeTrue(apiClient.recoveryRequest_completion != nil)
            guard let callback = apiClient.recoveryRequest_completion as? (Result<MissingEventsPayload, Error>) -> Void else {
                XCTFail("A request for /sync should have been executed")
                return
            }
            callback(result)
        }

        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertCall("exitRecoveryMode()", on: apiClient)
    }
    
    private class CancelRecoveryFlowTracker: SyncRepository {
        var cancelRecoveryFlowClosure: () -> Void = {}
        
        override func cancelRecoveryFlow() {
            cancelRecoveryFlowClosure()
        }
    }
}
