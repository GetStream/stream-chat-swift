//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SyncRepository_Tests: XCTestCase {
    var _activeChannelControllers = NSHashTable<ChatChannelController>.weakObjects()
    var _activeChannelListControllers = NSHashTable<ChatChannelListController>.weakObjects()
    var client: ChatClientMock!
    var channelRepository: ChannelListUpdaterMock!
    var database: DatabaseContainerMock!
    var apiClient: APIClientMock!

    var repository: SyncRepository!

    override func setUp() {
        super.setUp()
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = true
        client = ChatClientMock(config: config)
        channelRepository = ChannelListUpdaterMock(database: client.databaseContainer, apiClient: client.apiClient)
        database = client.mockDatabaseContainer
        apiClient = client.mockAPIClient

        repository = SyncRepository(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            channelRepository: channelRepository,
            eventNotificationCenter: client.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )
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
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )

        waitForSyncLocalStateRun()

        XCTAssertFalse(hasUpdatedLastSyncAtNow)
        XCTAssertEqual(database.writeSessionCounter, 0)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
    }

    func test_syncLocalState_localStorageEnabled_noPendingConnectionDate() throws {
        waitForSyncLocalStateRun()

        XCTAssertFalse(hasUpdatedLastSyncAtNow)
        XCTAssertEqual(database.writeSessionCounter, 1)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
    }

    func test_syncLocalState_localStorageEnabled_pendingConnectionDate_noChannels() throws {
        try database.createCurrentUser()
        try database.writeSynchronously { session in
            session.currentUser?.lastPendingConnectionDate = Date().addingTimeInterval(-3600)
        }
        database.writeSessionCounter = 0

        waitForSyncLocalStateRun()

        XCTAssertTrue(hasUpdatedLastSyncAtNow)
        XCTAssertEqual(database.writeSessionCounter, 2)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 0)
    }

    func test_syncLocalState_localStorageEnabled_pendingConnectionDate_channels() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastPendingConnection: Date().addingTimeInterval(-3600),
            createChannel: true
        )

        try waitForSyncLocalStateRun(requestResult: .success(messageEventPayload()))

        XCTAssertTrue(hasUpdatedLastSyncAtNow)
        // Write: API Response, lastPendingConnectionDate, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 3)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 1)
    }

    func test_syncLocalState_localStorageEnabled_pendingConnectionDate_channels_activeRemoteChannelController() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastPendingConnection: Date().addingTimeInterval(-3600),
            createChannel: true
        )

        let chatController = ChatChannelControllerMock(client: client)
        chatController.state = .remoteDataFetched
        _activeChannelControllers.add(chatController)

        try waitForSyncLocalStateRun(requestResult: .success(messageEventPayload()))

        XCTAssertTrue(hasUpdatedLastSyncAtNow)
        // Write: API Response, lastPendingConnectionDate, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 3)
        XCTAssertEqual(repository.activeChannelControllers.count, 1)
        XCTAssertCall("watchActiveChannel(completion:)", on: chatController, times: 1)
        XCTAssertEqual(repository.activeChannelListControllers.count, 0)
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 1)
    }

    func test_syncLocalState_localStorageEnabled_pendingConnectionDate_channels_activeRemoteChannelListController() throws {
        try prepareForSyncLocalStorage(
            createUser: true,
            lastPendingConnection: Date().addingTimeInterval(-3600),
            createChannel: true
        )

        let chatListController = ChatChannelListController(query: .init(filter: .exists(.cid)), client: client)
        chatListController.state = .remoteDataFetched
        _activeChannelListControllers.add(chatListController)
        channelRepository.resetChannelsQueryResult = .success([])

        try waitForSyncLocalStateRun(requestResult: .success(messageEventPayload()))

        XCTAssertTrue(hasUpdatedLastSyncAtNow)
        // Write: API Response, lastPendingConnectionDate, lastSyncAt
        XCTAssertEqual(database.writeSessionCounter, 3)
        XCTAssertEqual(repository.activeChannelControllers.count, 0)
        XCTAssertEqual(repository.activeChannelListControllers.count, 1)
        XCTAssertCall(
            "resetChannelsQuery(for:watchedChannelIds:synchedChannelIds:completion:)", on: channelRepository, times: 1
        )
        XCTAssertEqual(apiClient.request_allRecordedCalls.count, 1)
    }

    private var hasUpdatedLastSyncAtNow: Bool {
        guard let lastSyncAt = database.viewContext.currentUser?.lastSyncAt else { return false }
        return lastSyncAt.isNearlySameDate(as: Date())
    }

    func messageEventPayload() throws -> MissingEventsPayload {
        let json = XCTestCase.mockData(fromFile: "MissingEventsPayload")
        return try JSONDecoder.default.decode(MissingEventsPayload.self, from: json)
    }

    private func prepareForSyncLocalStorage(
        createUser: Bool,
        lastPendingConnection: Date?,
        createChannel: Bool
    ) throws {
        if createUser {
            try database.createCurrentUser()
        }

        try database.writeSynchronously { session in
            if let lastPendingConnection = lastPendingConnection {
                session.currentUser?.lastPendingConnectionDate = lastPendingConnection
            }
            if createChannel {
                let query = ChannelListQuery(filter: .exists(.cid))
                try session.saveChannel(payload: self.dummyPayload(with: .unique, numberOfMessages: 0), query: query)
            }
        }
        database.writeSessionCounter = 0
    }

    private func waitForSyncLocalStateRun(requestResult: Result<MissingEventsPayload, Error>? = nil) {
        let expectation = self.expectation(description: "syncLocalState completion")
        repository.syncLocalState {
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
    }

    // MARK: - Update last connection date

    func test_updateLastConnectionDate_shouldUpdateDateWhenEmpty() throws {
        try database.createCurrentUser(id: "123")
        XCTAssertNil(database.viewContext.currentUser?.lastPendingConnectionDate)

        let expectation = self.expectation(description: "Update last connection completion")
        let date = Date()
        repository.updateLastConnectionDate(with: date) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)

        XCTAssertEqual(database.viewContext.currentUser?.lastPendingConnectionDate, date)
    }

    func test_updateLastConnectionDate_shouldNotUpdateDateWhenTheresAPendingDate() throws {
        try database.createCurrentUser(id: "123")
        let originalDate = Date()
        try database.writeSynchronously { session in
            session.currentUser?.lastPendingConnectionDate = originalDate
        }
        XCTAssertNotNil(database.viewContext.currentUser?.lastPendingConnectionDate)

        let expectation = self.expectation(description: "Update last connection completion")
        let date = Date()
        repository.updateLastConnectionDate(with: date) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)

        XCTAssertEqual(database.viewContext.currentUser?.lastPendingConnectionDate, originalDate)
        XCTAssertNotEqual(database.viewContext.currentUser?.lastPendingConnectionDate, date)
    }

    // MARK: - Sync existing channels events

    func test_syncExistingChannelsEvents_noUser() {
        let result = getSyncExistingChannelEventsResult()

        guard case .noNeedToSync = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }
    }

    func test_syncExistingChannelsEvents_userNoLastSyncAt() throws {
        try database.createCurrentUser(id: "123")
        XCTAssertNil(database.viewContext.currentUser?.lastSyncAt)

        let result = getSyncExistingChannelEventsResult()

        guard case .noNeedToSync = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }

        let lastSyncAt = database.viewContext.currentUser?.lastSyncAt
        XCTAssertTrue(lastSyncAt.map(Calendar.current.isDateInToday) ?? false)
    }

    func test_syncExistingChannelsEvents_lastSyncAt_TooEarly() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            session.currentUser?.lastSyncAt = Date()
        }
        let result = getSyncExistingChannelEventsResult()

        guard case .noNeedToSync = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }
    }

    func test_syncExistingChannelsEvents_localStorageDisabled() throws {
        var config = ChatClientConfig(apiKeyString: .unique)
        config.isLocalStorageEnabled = false
        let client = ChatClientMock(config: config)
        repository = SyncRepository(
            config: client.config,
            activeChannelControllers: _activeChannelControllers,
            activeChannelListControllers: _activeChannelListControllers,
            channelRepository: channelRepository,
            eventNotificationCenter: repository.eventNotificationCenter,
            database: database,
            apiClient: apiClient
        )

        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            session.currentUser?.lastSyncAt = Date().addingTimeInterval(-3600)
        }
        let result = getSyncExistingChannelEventsResult()

        guard case .localStorageDisabled = result.error else {
            XCTFail("Should return .noNeedToSync")
            return
        }
    }

    func test_syncExistingChannelsEvents_localStorageEnabled_noChannels() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            session.currentUser?.lastSyncAt = Date().addingTimeInterval(-3600)
        }
        let result = getSyncExistingChannelEventsResult()

        guard let value = result.value else {
            XCTFail("Should return an empty array")
            return
        }

        XCTAssertEqual(value, [])
    }

    func test_syncExistingChannelsEvents_localStorageEnabled_someChannels_apiFailure() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            session.currentUser?.lastSyncAt = Date().addingTimeInterval(-3600)
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

    func test_syncExistingChannelsEvents_localStorageEnabled_someChannels_tooManyEventsError() throws {
        try database.createCurrentUser(id: "123")
        try database.writeSynchronously { session in
            session.currentUser?.lastSyncAt = Date().addingTimeInterval(-3600)
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

    func test_syncExistingChannelsEvents_localStorageEnabled_someChannels_apiSuccess_shouldStoreEvents() throws {
        try database.createCurrentUser(id: "123")
        let cid = try ChannelId(cid: "messaging:A2F4393C-D656-46B8-9A43-6148E9E62D7F")
        try database.writeSynchronously { session in
            session.currentUser?.lastSyncAt = Date().addingTimeInterval(-3600)
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: 0), query: query)
        }

        XCTAssertEqual(ChannelDTO.load(cid: cid, context: database.viewContext)?.messages.count, 0)

        let json = XCTestCase.mockData(fromFile: "MissingEventsPayload")
        let payload = try JSONDecoder.default.decode(MissingEventsPayload.self, from: json)
        let result = getSyncExistingChannelEventsResult(requestResult: .success(payload))

        guard let channelIds = result.value else {
            XCTFail("Should return an empty array")
            return
        }

        let channel = ChannelDTO.load(cid: cid, context: database.viewContext)
        XCTAssertEqual(channel?.messages.count, 1)
        XCTAssertEqual(channelIds.count, 1)
        XCTAssertEqual(channelIds.first, cid)
        XCTAssertEqual(database.viewContext.currentUser?.lastSyncAt, payload.eventPayloads.first?.createdAt)
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
}
