//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SyncOperations_Tests: XCTestCase {
    var client: ChatClientMock!
    var syncRepository: SyncRepositoryMock!
    var channelRepository: ChannelListUpdaterMock!
    var database: DatabaseContainerMock!

    override func setUp() {
        super.setUp()
        client = ChatClientMock(config: ChatClientConfig(apiKeyString: .unique))
        channelRepository = ChannelListUpdaterMock(database: client.databaseContainer, apiClient: client.apiClient)
        database = client.mockDatabaseContainer
        syncRepository = SyncRepositoryMock(client: client)
    }

    override func tearDown() {
        super.tearDown()
        client = nil
        syncRepository = nil
        channelRepository = nil
        database = nil
    }

    // MARK: - GetChannelIdsOperation

    func test_GetChannelIdsOperation_noChannels() {
        let context = SyncContext()
        let operation = GetChannelIdsOperation(database: database, context: context)
        operation.startAndWaitForCompletion()
        XCTAssertEqual(context.localChannelIds.count, 0)
    }

    func test_GetChannelIdsOperation_withChannels() throws {
        try database.writeSynchronously { session in
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: self.dummyPayload(with: .unique, numberOfMessages: 0), query: query)
        }

        let context = SyncContext()
        let operation = GetChannelIdsOperation(database: database, context: context)
        operation.startAndWaitForCompletion()
        
        XCTAssertEqual(context.localChannelIds.count, 1)
    }

    // MARK: - SyncEventsOperation

    func test_SyncEventsOperation_pendingDate_syncFailure_shouldRetry() throws {
        let context = SyncContext()
        try database.createCurrentUser()
        let originalDate = Date().addingTimeInterval(-3600)
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = originalDate
        }
        let operation = SyncEventsOperation(syncRepository: syncRepository, context: context)
        syncRepository.syncMissingEventsResult = .failure(.syncEndpointFailed(ClientError("")))

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.synchedChannelIds.count, 0)
        XCTAssertEqual(database.viewContext.currentUser?.lastSynchedEventDate, originalDate)
        XCTAssertCall(
            "syncChannelsEvents(channelIds:isRecovery:completion:)",
            on: syncRepository,
            times: 3
        )
    }

    func test_SyncEventsOperation_pendingDate_syncSuccess_shouldUpdateLastPendingConnectionDate() throws {
        let context = SyncContext()
        try database.createCurrentUser()
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = Date().addingTimeInterval(-3600)
        }

        let operation = SyncEventsOperation(syncRepository: syncRepository, context: context)
        syncRepository.syncMissingEventsResult = .success([.unique, .unique])

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.synchedChannelIds.count, 2)
        XCTAssertCall(
            "syncChannelsEvents(channelIds:isRecovery:completion:)",
            on: syncRepository,
            times: 1
        )
    }

    // MARK: - WatchChannelOperation

    func test_WatchChannelOperation_notAvailableOnRemote() {
        let context = SyncContext()
        let controller = ChatChannelControllerMock(client: client)
        controller.state = .initialized
        let operation = WatchChannelOperation(controller: controller, context: context)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedChannelIds.count, 0)
        XCTAssertNotCall("recoverWatchedChannel(completion:)", on: controller)
    }

    func test_WatchChannelOperation_availableOnRemote_alreadySynched() {
        let context = SyncContext()
        let controller = ChatChannelControllerMock(client: client)
        controller.state = .remoteDataFetched
        context.synchedChannelIds.insert(controller.cid!)

        let operation = WatchChannelOperation(controller: controller, context: context)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedChannelIds.count, 0)
        XCTAssertNotCall("recoverWatchedChannel(completion:)", on: controller)
    }

    func test_WatchChannelOperation_availableOnRemote_notSynched_watchFailure_shouldRetry() {
        let context = SyncContext()
        let controller = ChatChannelControllerMock(client: client)
        controller.state = .remoteDataFetched
        controller.watchActiveChannelError = ClientError("")

        let operation = WatchChannelOperation(controller: controller, context: context)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedChannelIds.count, 0)
        XCTAssertCall("recoverWatchedChannel(completion:)", on: controller, times: 3)
    }

    func test_WatchChannelOperation_availableOnRemote_notSynched_watchSuccess() {
        let context = SyncContext()
        let controller = ChatChannelControllerMock(client: client)
        controller.state = .remoteDataFetched
        controller.watchActiveChannelError = nil

        let operation = WatchChannelOperation(controller: controller, context: context)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedChannelIds.count, 1)
        XCTAssertCall("recoverWatchedChannel(completion:)", on: controller, times: 1)
    }

    // MARK: - RefetchChannelListQueryOperation

    func test_RefetchChannelListQueryOperation_notAvailableOnRemote() {
        let context = SyncContext()
        let controller = ChatChannelListController(query: .init(filter: .exists(.cid)), client: client)
        controller.state = .initialized
        let operation = RefetchChannelListQueryOperation(
            controller: controller,
            channelRepository: channelRepository,
            context: context
        )

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.synchedChannelIds.count, 0)
        XCTAssertNotCall("resetChannelsQuery(for:watchedChannelIds:synchedChannelIds:completion:)", on: channelRepository)
    }

    func test_RefetchChannelListQueryOperation_availableOnRemote_resetFailure_shouldRetry() {
        let context = SyncContext()
        let controller = ChatChannelListController(query: .init(filter: .exists(.cid)), client: client)
        controller.state = .remoteDataFetched
        let operation = RefetchChannelListQueryOperation(
            controller: controller,
            channelRepository: channelRepository,
            context: context
        )
        channelRepository.resetChannelsQueryResult = .failure(ClientError(""))

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.synchedChannelIds.count, 0)
        XCTAssertCall(
            "resetChannelsQuery(for:watchedChannelIds:synchedChannelIds:completion:)", on: channelRepository, times: 3
        )
    }

    func test_RefetchChannelListQueryOperation_availableOnRemote_resetSuccess_shouldAddToSynched() throws {
        let context = SyncContext()
        let controller = ChatChannelListController(query: .init(filter: .exists(.cid)), client: client)
        controller.state = .remoteDataFetched
        let channelId = ChannelId.unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: channelId))
        }

        let channel: ChatChannel = database.viewContext.channel(cid: channelId)!.asModel()
        let operation = RefetchChannelListQueryOperation(
            controller: controller,
            channelRepository: channelRepository,
            context: context
        )
        channelRepository.resetChannelsQueryResult = .success([channel])

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.synchedChannelIds.count, 1)
        XCTAssertEqual(context.synchedChannelIds.first?.id, channelId.id)
        XCTAssertCall(
            "resetChannelsQuery(for:watchedChannelIds:synchedChannelIds:completion:)", on: channelRepository, times: 1
        )
    }
}

extension Operation {
    fileprivate func startAndWaitForCompletion() {
        start()
        waitUntilFinished()
    }
}
