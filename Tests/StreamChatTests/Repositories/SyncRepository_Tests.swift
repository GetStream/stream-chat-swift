//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class SyncRepositoryV2_Tests: SyncRepository_Tests {
    override func setUp() {
        super.setUp()
        repository.usesV2Sync = true
    }
    
    func test_syncLocalEvents_bySkippingAlreadyFetchedChannelIds() throws {
        let lastSyncDate = Date()
        let cid = ChannelId.unique
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: lastSyncDate,
            createChannel: true,
            cid: cid
        )
        
        // One channel list controller which fetches the state for cid
        let chatListController = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        chatListController.state_mock = .remoteDataFetched
        chatListController.channels_mock = [.mock(cid: cid)]
        repository.startTrackingChannelListController(chatListController)
        chatListController.refreshLoadedChannelsResult = .success(Set([cid]))
        
        // If it fails, it means /sync was called but we expect it to be skipped because channel list refresh already refreshed the channel
        waitForSyncLocalStateRun()
    }
}

class SyncRepository_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var offlineRequestsRepository: OfflineRequestsRepository_Mock!
    var database: DatabaseContainer_Spy!
    var apiClient: APIClient_Spy!
    var channelListUpdater: ChannelListUpdater_Spy!

    var repository: SyncRepository!

    private var lastSyncAtValue: Date? {
        database.viewContext.currentUser?.lastSynchedEventDate?.bridgeDate
    }

    override func setUp() {
        super.setUp()

        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = true
        client = ChatClient_Mock(config: config)
        let messageRepository = MessageRepository_Mock(database: client.databaseContainer, apiClient: client.apiClient)
        offlineRequestsRepository = OfflineRequestsRepository_Mock(
            messageRepository: messageRepository,
            database: client.databaseContainer,
            apiClient: client.apiClient
        )
        database = client.mockDatabaseContainer
        apiClient = client.mockAPIClient
        channelListUpdater = client.mockChannelListUpdater

        repository = SyncRepository(
            config: client.config,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: client.eventNotificationCenter,
            database: database,
            apiClient: apiClient,
            channelListUpdater: channelListUpdater
        )
        repository.usesV2Sync = false
    }

    override func tearDown() {
        super.tearDown()
        client.cleanUp()
        client = nil
        offlineRequestsRepository.clear()
        offlineRequestsRepository = nil
        database = nil
        apiClient.cleanUp()
        apiClient = nil
        channelListUpdater.cleanUp()
        channelListUpdater = nil
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
        waitForExpectations(timeout: defaultTimeout, handler: nil)

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
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient,
            channelListUpdater: channelListUpdater
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
        waitForExpectations(timeout: defaultTimeout, handler: nil)

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
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient,
            channelListUpdater: channelListUpdater
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
        try XCTSkipIf(repository.usesV2Sync, "V2 only syncs if there are active controllers")
        
        let channelId = ChannelId.unique
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-3600),
            createChannel: true,
            cid: channelId
        )

        let firstEventDate = Date.unique
        let secondEventDate = Date.unique
        let payload = messageEventPayload(cid: channelId, with: [firstEventDate, secondEventDate])
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
        let cid = ChannelId.unique
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-3600),
            createChannel: true,
            cid: cid
        )

        let chatController = ChatChannelController_Spy(client: client)
        chatController.state = .remoteDataFetched
        repository.startTrackingChannelController(chatController)
        
        let chat = Chat_Mock(
            chatClient: client,
            channelQuery: .init(cid: Chat_Mock.cid),
            channelListQuery: nil
        )
        repository.startTrackingChat(chat)

        let eventDate = Date.unique
        waitForSyncLocalStateRun(requestResult: .success(messageEventPayload(cid: cid, with: [eventDate])))

        // Should use first event's created at date
        XCTAssertEqual(lastSyncAtValue, eventDate)
        // Write: API Response, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 2)
        XCTAssertEqual(repository.activeChannelControllers.count, 1)
        if repository.usesV2Sync {
            XCTAssertCall("watch()", on: chat, times: 1)
        } else {
            XCTAssertCall("recoverWatchedChannel(recovery:completion:)", on: chatController, times: 1)
        }
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        if repository.usesV2Sync {
            XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
            XCTAssertEqual(apiClient.request_allRecordedCalls.count, 1)
        } else {
            XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
            XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        }
        XCTAssertCall("runQueuedRequests(completion:)", on: offlineRequestsRepository, times: 1)
    }

    func test_syncLocalState_localStorageEnabled_pendingConnectionDate_channels_activeRemoteChannelListController() throws {
        let cid = ChannelId.unique
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-3600),
            createChannel: true,
            cid: cid
        )

        let chatListController = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        chatListController.state_mock = .remoteDataFetched
        chatListController.channels_mock = [.mock(cid: cid)]
        repository.startTrackingChannelListController(chatListController)
        if repository.usesV2Sync {
            chatListController.refreshLoadedChannelsResult = .success(Set())
        } else {
            chatListController.resetChannelsQueryResult = .success(([], []))
        }

        let eventDate = Date.unique
        waitForSyncLocalStateRun(requestResult: .success(messageEventPayload(cid: cid, with: [eventDate])))

        // Should use first event's created at date
        XCTAssertEqual(lastSyncAtValue, eventDate)
        // Write: API Response, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 2)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 1)
        if repository.usesV2Sync {
            XCTAssertCall(
                "refreshLoadedChannels(completion:)", on: chatListController,
                times: 1
            )
            XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
            XCTAssertEqual(apiClient.request_allRecordedCalls.count, 1)
        } else {
            XCTAssertCall(
                "resetQuery(watchedAndSynchedChannelIds:synchedChannelIds:completion:)", on: chatListController,
                times: 1
            )
            XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
            XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        }
        XCTAssertCall("runQueuedRequests(completion:)", on: offlineRequestsRepository, times: 1)
    }

    func test_syncLocalState_localStorageEnabled_pendingConnectionDate_channels_activeRemoteChannelListController_unwantedChannels(
    ) throws {
        try XCTSkipIf(repository.usesV2Sync, "V2 does not handle unwanted channels")

        let cid = ChannelId.unique
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-3600),
            createChannel: true,
            cid: cid
        )

        let chatListController = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        chatListController.state_mock = .remoteDataFetched
        repository.startTrackingChannelListController(chatListController)
        let unwantedId = ChannelId.unique
        chatListController.resetChannelsQueryResult = .success(([], [unwantedId]))

        let eventDate = Date.unique
        waitForSyncLocalStateRun(requestResult: .success(messageEventPayload(cid: cid, with: [eventDate])))

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
        let cid = ChannelId.unique
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: lastSyncDate,
            createChannel: true,
            cid: cid
        )
        
        let channelController = ChatChannelController_Mock(channelQuery: ChannelQuery(cid: .unique), channelListQuery: nil, client: client)
        if repository.usesV2Sync {
            repository.startTrackingChannelController(channelController)
        }

        let firstDate = lastSyncDate.addingTimeInterval(1)
        let secondDate = lastSyncDate.addingTimeInterval(2)
        let eventsPayload1 = messageEventPayload(cid: cid, with: [firstDate, secondDate])
        waitForSyncLocalStateRun(requestResult: .success(eventsPayload1))

        XCTAssertNearlySameDate(lastSyncAtValue, secondDate)

        let thirdDate = secondDate.addingTimeInterval(1)
        let eventsPayload2 = messageEventPayload(cid: cid, with: [thirdDate])
        waitForSyncLocalStateRun(requestResult: .success(eventsPayload2))

        XCTAssertNearlySameDate(lastSyncAtValue, thirdDate)
        
        repository.stopTrackingChannelController(channelController)
    }

    // MARK: - Sync existing channels events

    func test_syncExistingChannelsEvents_whenMoreThan30DaysHavePassed_shouldNotProceedToSync() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: Date().addingTimeInterval(-60 * 60 * 24 * 31),
            createChannel: false
        )

        let result = getSyncExistingChannelEventsResult()

        guard let value = result.value else {
            XCTFail("Should return an empty array")
            return
        }

        // Should update lastSyncAt
        XCTAssertNearlySameDate(database.viewContext.currentUser?.lastSynchedEventDate?.bridgeDate, Date())
        XCTAssertEqual(value, [])
        XCTAssertNil(apiClient.request_endpoint)
    }

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

        XCTAssertNil(apiClient.request_endpoint)
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
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_syncExistingChannelsEvents_someChannels_noUser() throws {
        try database.writeSynchronously { session in
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: .unique), query: query, cache: nil)
        }

        let result = getSyncExistingChannelEventsResult()

        guard case .noNeedToSync = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_syncExistingChannelsEvents_someChannels_userNoLastSyncAt() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: .unique), query: query, cache: nil)
        }
        XCTAssertNil(lastSyncAtValue)

        let result = getSyncExistingChannelEventsResult()

        guard case .noNeedToSync = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }
        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_syncExistingChannelsEvents_someChannels_lastSyncAt_TooEarly() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: .unique), query: query, cache: nil)
            session.currentUser?.lastSynchedEventDate = DBDate()
        }
        let result = getSyncExistingChannelEventsResult()

        guard case .noNeedToSync = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }

        XCTAssertNil(apiClient.request_endpoint)
    }

    func test_syncExistingChannelsEvents_someChannels_apiFailure() throws {
        let mockedLastSyncAt = Date().addingTimeInterval(-3600)
        let mockedCid = ChannelId.unique
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = mockedLastSyncAt.bridgeDate
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: mockedCid), query: query, cache: nil)
        }

        let result = getSyncExistingChannelEventsResult(requestResult: .failure(ClientError("something went wrong")))

        guard case let .syncEndpointFailed(error) = result.error, let clientError = error as? ClientError else {
            XCTFail("Should return .syncEndpointFailed")
            return
        }
        XCTAssertEqual(clientError.localizedDescription, "something went wrong")
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(Endpoint<MissingEventsPayload>.missingEvents(since: mockedLastSyncAt, cids: [mockedCid]))
        )
    }

    func test_syncExistingChannelsEvents_someChannels_tooManyEventsError() throws {
        let mockedLastSyncAt = Date().addingTimeInterval(-3600)
        let mockedCid = ChannelId.unique
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = mockedLastSyncAt.bridgeDate
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: mockedCid), query: query, cache: nil)
        }

        let expectedError = ErrorPayload(code: 1, message: "Too many events", statusCode: 400)
        let result = getSyncExistingChannelEventsResult(requestResult: .failure(ClientError(with: expectedError)))

        guard let value = result.value else {
            XCTFail("Should return an empty array")
            return
        }

        XCTAssertEqual(value, [])
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(Endpoint<MissingEventsPayload>.missingEvents(since: mockedLastSyncAt, cids: [mockedCid]))
        )

        // Should update lastSyncAt
        XCTAssertNearlySameDate(database.viewContext.currentUser?.lastSynchedEventDate?.bridgeDate, Date())
    }

    func test_syncExistingChannelsEvents_someChannels_apiSuccess_shouldStoreEvents() throws {
        let mockedLastSyncAt = Date().addingTimeInterval(-3600)
        let cid = try ChannelId(cid: "messaging:A2F4393C-D656-46B8-9A43-6148E9E62D7F")
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = DBDate().addingTimeInterval(-3600)
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0), query: query, cache: nil)
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
        XCTAssertEqual(
            apiClient.request_endpoint,
            AnyEndpoint(Endpoint<MissingEventsPayload>.missingEvents(since: mockedLastSyncAt, cids: [cid]))
        )
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

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        return receivedResult
    }

    // MARK: - Queue offline requests

    func test_queueOfflineRequest_localStorageDisabled() {
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = false
        let client = ChatClient_Mock(config: config)
        repository = SyncRepository(
            config: client.config,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient,
            channelListUpdater: channelListUpdater
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
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient,
            channelListUpdater: channelListUpdater
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
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient,
            channelListUpdater: channelListUpdater
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
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient,
            channelListUpdater: channelListUpdater
        )

        let expectation = expectation(description: "cancelRecoveryFlow completion")
        mock?.cancelRecoveryFlowClosure = {
            expectation.fulfill()
        }

        // WHEN
        mock = nil

        // THEN
        waitForExpectations(timeout: defaultTimeout, handler: nil)
    }

    func test_cancelRecoveryFlow_cancelsAllOperations() throws {
        try XCTSkipIf(repository.usesV2Sync, "V2 has different implementation")
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
        repository.startTrackingChannelController(channelController)

        // Add active channel list component
        let channelListController = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        channelListController.state_mock = .remoteDataFetched
        repository.startTrackingChannelListController(channelListController)

        // Sync local state
        var completionCalled = false
        repository.syncLocalState {
            completionCalled = true
        }

        // Wait for /sync to be called
        if repository.usesV2Sync {
            apiClient.waitForRequest()
        } else {
            apiClient.waitForRecoveryRequest()
        }

        // Let /sync operation to complete
        let syncResponse = Result<MissingEventsPayload, Error>.success(.init(eventPayloads: []))
        apiClient.test_simulateRecoveryResponse(syncResponse)
        apiClient.recoveryRequest_completion = nil

        // Wait for watch operation
        if !repository.usesV2Sync {
            AssertAsync.willBeTrue(apiClient.recoveryRequest_completion != nil)
        }

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
    
    // MARK: - Tracking

    func test_startTrackingChannelController() {
        let controller = ChatChannelController_Mock.mock()
        repository.startTrackingChannelController(controller)

        XCTAssertTrue(repository.activeChannelControllers.allObjects.first === controller)
    }

    func test_startTrackingChannelController_whenAlreadyExists_thenDoNotDuplicate() {
        let controller = ChatChannelController_Mock.mock()
        repository.startTrackingChannelController(controller)
        repository.startTrackingChannelController(controller)

        XCTAssertTrue(repository.activeChannelControllers.allObjects.first === controller)
        XCTAssertEqual(repository.activeChannelControllers.allObjects.count, 1)
    }

    func test_stopTrackingChannelController() {
        let controller = ChatChannelController_Mock.mock()
        repository.startTrackingChannelController(controller)
        XCTAssertEqual(repository.activeChannelControllers.allObjects.count, 1)

        repository.stopTrackingChannelController(controller)

        XCTAssertTrue(repository.activeChannelControllers.allObjects.isEmpty)
    }

    func test_startTrackingChannelListController() {
        let controller = ChatChannelListController_Mock.mock()
        repository.startTrackingChannelListController(controller)

        XCTAssertTrue(repository.activeChannelListControllers.allObjects.first === controller)
    }

    func test_startTrackingChannelListController_whenAlreadyExists_thenDoNotDuplicate() {
        let controller = ChatChannelListController_Mock.mock()
        repository.startTrackingChannelListController(controller)
        repository.startTrackingChannelListController(controller)

        XCTAssertTrue(repository.activeChannelListControllers.allObjects.first === controller)
        XCTAssertEqual(repository.activeChannelListControllers.allObjects.count, 1)
    }

    func test_stopTrackingChannelListController() {
        let controller = ChatChannelListController_Mock.mock()
        repository.startTrackingChannelListController(controller)
        XCTAssertEqual(repository.activeChannelListControllers.allObjects.count, 1)

        repository.stopTrackingChannelListController(controller)

        XCTAssertTrue(repository.activeChannelListControllers.allObjects.isEmpty)
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

    func prepareForSyncLocalStorage(
        createUser: Bool,
        lastSynchedEventDate: Date?,
        createChannel: Bool,
        cid: ChannelId? = nil
    ) throws {
        if createUser {
            try database.createCurrentUser()
        }

        try database.writeSynchronously { session in
            if let lastSynchedEventDate = lastSynchedEventDate {
                session.currentUser?.lastSynchedEventDate = lastSynchedEventDate.bridgeDate
            }
            if createChannel, let channelId = cid {
                let query = ChannelListQuery(filter: .exists(.cid))
                try session.saveChannel(payload: self.dummyPayload(with: channelId, numberOfMessages: 0), query: query, cache: nil)
            }
        }
        database.writeSessionCounter = 0
    }

    func waitForSyncLocalStateRun(requestResult: Result<MissingEventsPayload, Error>? = nil) {
        database.writeSessionCounter = 0
        apiClient.clear()

        let expectation = self.expectation(description: "syncLocalState completion")
        repository.syncLocalState {
            expectation.fulfill()
        }

        if !repository.usesV2Sync {
            AssertAsync.willBeTrue(
                "enterRecoveryMode()".wasCalled(on: apiClient, times: 1)
            )
        }

        if let result = requestResult {
            if repository.usesV2Sync {
                apiClient.waitForRequest()
                guard let callback = apiClient.request_completion as? (Result<MissingEventsPayload, Error>) -> Void else {
                    XCTFail("A request for /sync should have been executed")
                    return
                }
                callback(result)
            } else {
                apiClient.waitForRecoveryRequest()
                guard let callback = apiClient.recoveryRequest_completion as? (Result<MissingEventsPayload, Error>) -> Void else {
                    XCTFail("A request for /sync should have been executed")
                    return
                }
                callback(result)
            }
        }

        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertCall("exitRecoveryMode()", on: apiClient)
    }

    private class CancelRecoveryFlowTracker: SyncRepository {
        var cancelRecoveryFlowClosure: () -> Void = {}

        override func cancelRecoveryFlow() {
            cancelRecoveryFlowClosure()
        }
    }
}
