//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SyncOperations_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var syncRepository: SyncRepository_Spy!
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        client = ChatClient_Mock(config: ChatClientConfig(apiKeyString: .unique))
        database = client.mockDatabaseContainer
        syncRepository = client.mockSyncRepository
    }

    override func tearDown() {
        super.tearDown()
        client = nil
        syncRepository = nil
        database = nil
    }

    // MARK: - GetChannelIdsOperation

    func test_GetChannelIdsOperation_noChannels() {
        let context = SyncContext(lastSyncAt: .init())
        let operation = GetChannelIdsOperation(database: database, context: context, activeChannelIds: [])
        operation.startAndWaitForCompletion()
        XCTAssertEqual(context.localChannelIds.count, 0)
    }

    func test_GetChannelIdsOperation_withChannels() throws {
        try database.writeSynchronously { session in
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: self.dummyPayload(with: .unique, numberOfMessages: 0), query: query, cache: nil)
        }

        let context = SyncContext(lastSyncAt: .init())
        let operation = GetChannelIdsOperation(database: database, context: context, activeChannelIds: [])
        operation.startAndWaitForCompletion()
        
        XCTAssertEqual(context.localChannelIds.count, 1)
    }
    
    func test_GetChannelIdsOperation_withActiveChannels() throws {
        let context = SyncContext(lastSyncAt: .init())
        let activeChannelIds: [ChannelId] = [.unique]
        let operation = GetChannelIdsOperation(database: database, context: context, activeChannelIds: activeChannelIds)
        operation.startAndWaitForCompletion()
        
        XCTAssertEqual(context.localChannelIds.count, 1)
    }
    
    func test_GetChannelIdsOperation_withDuplicates() throws {
        let channelId = ChannelId.unique
        try database.writeSynchronously { session in
            let query = ChannelListQuery(filter: .exists(.cid))
            try session.saveChannel(payload: self.dummyPayload(with: channelId, numberOfMessages: 0), query: query, cache: nil)
        }
        
        let context = SyncContext(lastSyncAt: .init())
        let activeChannelIds: [ChannelId] = [channelId]
        let operation = GetChannelIdsOperation(database: database, context: context, activeChannelIds: activeChannelIds)
        operation.startAndWaitForCompletion()
        
        XCTAssertEqual(context.localChannelIds.count, 1)
    }

    // MARK: - SyncEventsOperation

    func test_SyncEventsOperation_pendingDate_syncFailure_shouldRetry() throws {
        let context = SyncContext(lastSyncAt: .init())
        try database.createCurrentUser()
        let originalDate = Date().addingTimeInterval(-3600)
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = originalDate.bridgeDate
        }
        let operation = SyncEventsOperation(syncRepository: syncRepository, context: context)
        syncRepository.syncMissingEventsResult = .failure(.syncEndpointFailed(ClientError("")))

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.synchedChannelIds.count, 0)
        XCTAssertNearlySameDate(database.viewContext.currentUser?.lastSynchedEventDate?.bridgeDate, originalDate)
        XCTAssertCall(
            "syncChannelsEvents(channelIds:lastSyncAt:isRecovery:completion:)",
            on: syncRepository,
            times: 3
        )
    }

    func test_SyncEventsOperation_pendingDate_syncSuccess_shouldUpdateLastPendingConnectionDate() throws {
        let context = SyncContext(lastSyncAt: .init())
        try database.createCurrentUser()
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = DBDate().addingTimeInterval(-3600)
        }

        let operation = SyncEventsOperation(syncRepository: syncRepository, context: context)
        syncRepository.syncMissingEventsResult = .success([.unique, .unique])

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.synchedChannelIds.count, 2)
        XCTAssertCall(
            "syncChannelsEvents(channelIds:lastSyncAt:isRecovery:completion:)",
            on: syncRepository,
            times: 1
        )
    }

    // MARK: - WatchChannelOperation

    func test_WatchChannelOperation_notAvailableOnRemote() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelController_Spy(client: client)
        controller.state = .initialized
        let operation = WatchChannelOperation(controller: controller, context: context)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 0)
        XCTAssertNotCall("recoverWatchedChannel(completion:)", on: controller)
    }

    func test_WatchChannelOperation_availableOnRemote_alreadySynched() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelController_Spy(client: client)
        controller.state = .remoteDataFetched
        context.synchedChannelIds.insert(controller.cid!)

        let operation = WatchChannelOperation(controller: controller, context: context)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 1)
        XCTAssertCall("recoverWatchedChannel(completion:)", on: controller)
    }
    
    func test_WatchChannelOperation_availableOnRemote_notSynched() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelController_Spy(client: client)
        controller.state = .remoteDataFetched
        context.localChannelIds.insert(controller.cid!, at: 0)

        let operation = WatchChannelOperation(controller: controller, context: context)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 1)
        XCTAssertEqual(context.synchedChannelIds.count, 0)
        XCTAssertCall("recoverWatchedChannel(completion:)", on: controller)
    }

    func test_WatchChannelOperation_availableOnRemote_notSynched_watchFailure_shouldRetry() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelController_Spy(client: client)
        controller.state = .remoteDataFetched
        controller.watchActiveChannelError = ClientError("")

        let operation = WatchChannelOperation(controller: controller, context: context)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 0)
        XCTAssertCall("recoverWatchedChannel(completion:)", on: controller, times: 3)
    }

    func test_WatchChannelOperation_availableOnRemote_notSynched_watchSuccess() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelController_Spy(client: client)
        controller.state = .remoteDataFetched
        controller.watchActiveChannelError = nil

        let operation = WatchChannelOperation(controller: controller, context: context)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 1)
        XCTAssertCall("recoverWatchedChannel(completion:)", on: controller, times: 1)
    }

    // MARK: - RefetchChannelListQueryOperation

    func test_RefetchChannelListQueryOperation_notAvailableOnRemote() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        controller.state = .initialized
        let operation = RefetchChannelListQueryOperation(
            controller: controller,
            context: context
        )

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.synchedChannelIds.count, 0)
        XCTAssertNotCall(
            "resetQuery(watchedAndSynchedChannelIds:synchedChannelIds:completion:)",
            on: controller
        )
    }

    func test_RefetchChannelListQueryOperation_availableOnRemote_resetFailure_shouldRetry() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        controller.state = .remoteDataFetched
        let operation = RefetchChannelListQueryOperation(
            controller: controller,
            context: context
        )
        controller.resetChannelsQueryResult = .failure(ClientError(""))

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.synchedChannelIds.count, 0)
        XCTAssertCall(
            "resetQuery(watchedAndSynchedChannelIds:synchedChannelIds:completion:)", on: controller,
            times: 3
        )
    }

    func test_RefetchChannelListQueryOperation_availableOnRemote_resetSuccess_shouldAddToContext() throws {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        controller.state = .remoteDataFetched
        let channelId = ChannelId.unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: channelId))
        }

        let channel = try XCTUnwrap(database.viewContext.channel(cid: channelId)).asModel()
        let unwantedChannelId = ChannelId.unique
        context.watchedAndSynchedChannelIds = [ChannelId.unique, ChannelId.unique]
        context.unwantedChannelIds = [ChannelId.unique]

        let operation = RefetchChannelListQueryOperation(
            controller: controller,
            context: context
        )
        controller.resetChannelsQueryResult = .success(([channel], [unwantedChannelId]))

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 3)
        XCTAssertTrue(context.watchedAndSynchedChannelIds.contains { $0.id == channelId.id })
        XCTAssertEqual(context.unwantedChannelIds.count, 2)
        XCTAssertTrue(context.unwantedChannelIds.contains { $0.id == unwantedChannelId.id })
        XCTAssertCall(
            "resetQuery(watchedAndSynchedChannelIds:synchedChannelIds:completion:)", on: controller,
            times: 1
        )
    }

    func test_RefetchChannelListQueryOperation_availableOnRemote_resetSuccess_shouldNotAddToContextWhenAlreadyExisting() throws {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelListController_Mock(query: .init(filter: .exists(.cid)), client: client)
        controller.state = .remoteDataFetched
        let channelId = ChannelId.unique
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: channelId))
        }

        let channel = try XCTUnwrap(database.viewContext.channel(cid: channelId)).asModel()
        let unwantedChannelId = ChannelId.unique
        context.synchedChannelIds = [channelId]
        context.unwantedChannelIds = [unwantedChannelId]

        let operation = RefetchChannelListQueryOperation(
            controller: controller,
            context: context
        )
        controller.resetChannelsQueryResult = .success(([channel], [unwantedChannelId]))

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.synchedChannelIds.count, 1)
        XCTAssertTrue(context.synchedChannelIds.contains { $0.id == channelId.id })
        XCTAssertEqual(context.unwantedChannelIds.count, 1)
        XCTAssertTrue(context.unwantedChannelIds.contains { $0.id == unwantedChannelId.id })
        XCTAssertCall(
            "resetQuery(watchedAndSynchedChannelIds:synchedChannelIds:completion:)", on: controller,
            times: 1
        )
    }

    // MARK: - DeleteUnwantedChannelsOperation

    func test_DeleteUnwantedChannelsOperation_noUnwantedChannels() throws {
        let context = SyncContext(lastSyncAt: .init())

        try addChannel(with: ChannelId.unique, numberOfMessages: 3)

        let operation = DeleteUnwantedChannelsOperation(database: database, context: context)
        operation.startAndWaitForCompletion()

        XCTAssertEqual(database.writeSessionCounter, 0)
    }

    func test_DeleteUnwantedChannelsOperation_unwantedChannels_failure() throws {
        let channelId = ChannelId.unique
        let context = SyncContext(lastSyncAt: .init())
        context.unwantedChannelIds = [channelId]
        database.write_errorResponse = ClientError.ChannelDoesNotExist(cid: channelId)

        let operation = DeleteUnwantedChannelsOperation(database: database, context: context)
        operation.startAndWaitForCompletion()

        XCTAssertEqual(database.writeSessionCounter, 3)
    }

    func test_DeleteUnwantedChannelsOperation_unwantedChannels_success() throws {
        let channelId = ChannelId.unique
        let context = SyncContext(lastSyncAt: .init())
        context.unwantedChannelIds = [channelId]

        try addChannel(with: channelId, numberOfMessages: 3)
        let originalChannels = try allChannels()
        XCTAssertEqual(originalChannels.count, 1)
        XCTAssertEqual(originalChannels.first?.messages.count, 3)

        let operation = DeleteUnwantedChannelsOperation(database: database, context: context)
        operation.startAndWaitForCompletion()

        XCTAssertEqual(database.writeSessionCounter, 1)
        let channels = try allChannels()
        XCTAssertEqual(channels.count, 0)
    }

    private func allChannels() throws -> [ChannelDTO] {
        try database.viewContext.fetch(ChannelDTO.allChannelsFetchRequest)
    }

    private func addChannel(with cid: ChannelId, numberOfMessages: Int) throws {
        try database.writeSynchronously { session in
            try session.saveChannel(payload: self.dummyPayload(with: cid, numberOfMessages: numberOfMessages))
        }
        database.writeSessionCounter = 0
    }
}

extension Operation {
    fileprivate func startAndWaitForCompletion() {
        start()
        waitUntilFinished()
    }
}
