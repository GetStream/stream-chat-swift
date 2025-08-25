//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

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
        XCTAssertCall("watch()", on: chat, times: 1)
        
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 1)
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
        chatListController.refreshLoadedChannelsResult = .success(Set())

        let eventDate = Date.unique
        waitForSyncLocalStateRun(requestResult: .success(messageEventPayload(cid: cid, with: [eventDate])))

        // Should use first event's created at date
        XCTAssertEqual(lastSyncAtValue, eventDate)
        // Write: API Response, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 2)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 1)
        XCTAssertCall(
            "refreshLoadedChannels(completion:)", on: chatListController,
            times: 1
        )
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 1)
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
        repository.startTrackingChannelController(channelController)

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

    func test_startTrackingLivestreamController() {
        let controller = LivestreamChannelController(
            channelQuery: ChannelQuery(cid: .unique),
            client: client
        )
        repository.startTrackingLivestreamController(controller)

        XCTAssertTrue(repository.activeLivestreamControllers.allObjects.first === controller)
    }

    func test_startTrackingLivestreamController_whenAlreadyExists_thenDoNotDuplicate() {
        let controller = LivestreamChannelController(
            channelQuery: ChannelQuery(cid: .unique),
            client: client
        )
        repository.startTrackingLivestreamController(controller)
        repository.startTrackingLivestreamController(controller)

        XCTAssertTrue(repository.activeLivestreamControllers.allObjects.first === controller)
        XCTAssertEqual(repository.activeLivestreamControllers.allObjects.count, 1)
    }

    func test_stopTrackingLivestreamController() {
        let controller = LivestreamChannelController(
            channelQuery: ChannelQuery(cid: .unique),
            client: client
        )
        repository.startTrackingLivestreamController(controller)
        XCTAssertEqual(repository.activeLivestreamControllers.allObjects.count, 1)

        repository.stopTrackingLivestreamController(controller)

        XCTAssertTrue(repository.activeLivestreamControllers.allObjects.isEmpty)
    }

    func test_removeAllTracked_includesLivestreamControllers() {
        let channelController = ChatChannelController_Mock.mock()
        let channelListController = ChatChannelListController_Mock.mock()
        let livestreamController = LivestreamChannelController(
            channelQuery: ChannelQuery(cid: .unique),
            client: client
        )

        repository.startTrackingChannelController(channelController)
        repository.startTrackingChannelListController(channelListController)
        repository.startTrackingLivestreamController(livestreamController)

        XCTAssertEqual(repository.activeChannelControllers.allObjects.count, 1)
        XCTAssertEqual(repository.activeChannelListControllers.allObjects.count, 1)
        XCTAssertEqual(repository.activeLivestreamControllers.allObjects.count, 1)

        repository.removeAllTracked()

        XCTAssertTrue(repository.activeChannelControllers.allObjects.isEmpty)
        XCTAssertTrue(repository.activeChannelListControllers.allObjects.isEmpty)
        XCTAssertTrue(repository.activeLivestreamControllers.allObjects.isEmpty)
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

        if let result = requestResult {
            apiClient.waitForRequest()
            guard let callback = apiClient.request_completion as? (Result<MissingEventsPayload, Error>) -> Void else {
                XCTFail("A request for /sync should have been executed")
                return
            }
            callback(result)
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
