//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SyncRepository_Tests: XCTestCase {
    var _activeChannelControllers: NSHashTable<ChatChannelController>!
    var _activeChannelListControllers: NSHashTable<ChatChannelListController>!
    var client: ChatClientMock!
    var channelRepository: ChannelListUpdaterMock!
    var offlineRequestsRepository: OfflineRequestsRepositoryMock!
    var database: DatabaseContainerMock!
    var apiClient: APIClientMock!

    var repository: SyncRepository!

    private var lastSyncAtValue: Date? {
        database.viewContext.currentUser?.lastSynchedEventDate
    }

    override func setUp() {
        super.setUp()

        _activeChannelControllers = NSHashTable<ChatChannelController>.weakObjects()
        _activeChannelListControllers = NSHashTable<ChatChannelListController>.weakObjects()
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = true
        client = ChatClientMock(config: config)
        channelRepository = ChannelListUpdaterMock(database: client.databaseContainer, apiClient: client.apiClient)
        let messageRepository = MessageRepositoryMock(database: client.databaseContainer, apiClient: client.apiClient)
        offlineRequestsRepository = OfflineRequestsRepositoryMock(
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
            channelRepository: channelRepository,
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
        client = nil
        channelRepository = nil
        offlineRequestsRepository = nil
        database = nil
        apiClient = nil
        repository = nil
    }

    // MARK: - Sync local state

    func test_syncLocalState_localStorageDisabled() throws {
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = false
        let client = ChatClientMock(config: config)
        repository = SyncRepository(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            channelRepository: channelRepository,
            offlineRequestsRepository: offlineRequestsRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )

        waitForSyncLocalStateRun()

        XCTAssertNil(lastSyncAtValue)
        XCTAssertEqual(database.writeSessionCounter, 0)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        // When isLocalStorageEnabled is false, we don't need to run any offline requests related task
        XCTAssertNotCall("runQueuedRequests(completion:)", on: offlineRequestsRepository)
    }

    func test_syncLocalState_localStorageEnabled_noChannels() throws {
        try database.createCurrentUser()

        waitForSyncLocalStateRun()

        XCTAssertNil(lastSyncAtValue)
        XCTAssertEqual(database.writeSessionCounter, 0)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        XCTAssertCall("runQueuedRequests(completion:)", on: offlineRequestsRepository, times: 1)
    }

    func test_syncLocalState_localStorageEnabled_channels_noLastSynchedEventDate() throws {
        try database.createCurrentUser()
        try prepareForSyncLocalStorage(
            createUser: true,
            lastSynchedEventDate: nil,
            createChannel: true
        )

        waitForSyncLocalStateRun()

        // Should set current date as last synched event value
        XCTAssertTrue(lastSyncAtValue?.isNearlySameDate(as: Date()) == true)
        // 1 to set last synched event
        XCTAssertEqual(database.writeSessionCounter, 1)
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

        let chatController = ChatChannelControllerMock(client: client)
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

        let chatListController = ChatChannelListController(query: .init(filter: .exists(.cid)), client: client)
        chatListController.state = .remoteDataFetched
        _activeChannelListControllers.add(chatListController)
        channelRepository.resetChannelsQueryResult = .success([])

        let eventDate = Date.unique
        waitForSyncLocalStateRun(requestResult: .success(messageEventPayload(with: [eventDate])))

        // Should use first event's created at date
        XCTAssertEqual(lastSyncAtValue, eventDate)
        // Write: API Response, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 2)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 1)
        XCTAssertCall(
            "resetChannelsQuery(for:watchedChannelIds:synchedChannelIds:completion:)", on: channelRepository, times: 1
        )
        XCTAssertEqual(apiClient.recoveryRequest_allRecordedCalls.count, 1)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
        XCTAssertCall("runQueuedRequests(completion:)", on: offlineRequestsRepository, times: 1)
    }

    // MARK: - Sync existing channels events

    func test_syncExistingChannelsEvents_localStorageEnabled_noChannels() throws {
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

        let lastSyncAt = lastSyncAtValue
        XCTAssertTrue(lastSyncAt.map(Calendar.current.isDateInToday) ?? false)
    }

    func test_syncExistingChannelsEvents_someChannels_lastSyncAt_TooEarly() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: .unique), query: query)
            session.currentUser?.lastSynchedEventDate = Date()
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
            session.currentUser?.lastSynchedEventDate = Date().addingTimeInterval(-3600)
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
            session.currentUser?.lastSynchedEventDate = Date().addingTimeInterval(-3600)
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: .dummy(cid: .unique), query: query)
        }

        let expectedError = ErrorPayload(code: 1, message: "Too many events", statusCode: 400)
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
            session.currentUser?.lastSynchedEventDate = Date().addingTimeInterval(-3600)
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

        waitForExpectations(timeout: 0.1, handler: nil)
        return receivedResult
    }

    // MARK: - Queue offline requests

    func test_queueOfflineRequest_localStorageDisabled() {
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = false
        let client = ChatClientMock(config: config)
        repository = SyncRepository(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            channelRepository: channelRepository,
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
        let client = ChatClientMock(config: config)
        repository = SyncRepository(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            channelRepository: channelRepository,
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
                session.currentUser?.lastSynchedEventDate = lastSynchedEventDate
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
        let expectation = self.expectation(description: "syncLocalState completion")
        repository.syncLocalState {
            expectation.fulfill()
        }

        XCTAssertCall("enterRecoveryMode()", on: apiClient, times: 1)

        if let result = requestResult {
            // Simulate API Failure
            AssertAsync.willBeTrue(apiClient.recoveryRequest_completion != nil)
            guard let callback = apiClient.recoveryRequest_completion as? (Result<MissingEventsPayload, Error>) -> Void else {
                XCTFail("A request for /sync should have been executed")
                return
            }
            callback(result)
        }

        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertCall("exitRecoveryMode()", on: apiClient, times: 1)
    }
}
