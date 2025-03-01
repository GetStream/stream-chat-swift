//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class SyncOperations_Tests: XCTestCase {
    var client: ChatClient_Mock!
    var syncRepository: SyncRepository_Mock!
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

    // MARK: - SyncEventsOperation

    func test_SyncEventsOperation_pendingDate_syncFailure_shouldRetry() throws {
        let context = SyncContext(lastSyncAt: .init())
        context.localChannelIds = [ChannelId.unique]
        try database.createCurrentUser()
        let originalDate = Date().addingTimeInterval(-3600)
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = originalDate.bridgeDate
        }
        let operation = SyncEventsOperation(syncRepository: syncRepository, context: context, recovery: false)
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
        context.localChannelIds = [ChannelId.unique]
        try database.createCurrentUser()
        try database.writeSynchronously { session in
            session.currentUser?.lastSynchedEventDate = DBDate().addingTimeInterval(-3600)
        }

        let operation = SyncEventsOperation(syncRepository: syncRepository, context: context, recovery: false)
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
        let operation = WatchChannelOperation(controller: controller, context: context, recovery: true)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 0)
        XCTAssertNotCall("recoverWatchedChannel(recovery:completion:)", on: controller)
    }

    func test_WatchChannelOperation_availableOnRemote_alreadySynched() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelController_Spy(client: client)
        controller.state = .remoteDataFetched
        context.synchedChannelIds.insert(controller.cid!)

        let operation = WatchChannelOperation(controller: controller, context: context, recovery: true)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 1)
        XCTAssertCall("recoverWatchedChannel(recovery:completion:)", on: controller)
    }

    func test_WatchChannelOperation_availableOnRemote_notSynched() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelController_Spy(client: client)
        controller.state = .remoteDataFetched

        let operation = WatchChannelOperation(controller: controller, context: context, recovery: true)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 1)
        XCTAssertEqual(context.synchedChannelIds.count, 0)
        XCTAssertCall("recoverWatchedChannel(recovery:completion:)", on: controller)
    }

    func test_WatchChannelOperation_availableOnRemote_notSynched_watchFailure_shouldRetry() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelController_Spy(client: client)
        controller.state = .remoteDataFetched
        controller.watchActiveChannelError = ClientError("")

        let operation = WatchChannelOperation(controller: controller, context: context, recovery: true)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 0)
        XCTAssertCall("recoverWatchedChannel(recovery:completion:)", on: controller, times: 3)
    }

    func test_WatchChannelOperation_availableOnRemote_notSynched_watchSuccess() {
        let context = SyncContext(lastSyncAt: .init())
        let controller = ChatChannelController_Spy(client: client)
        controller.state = .remoteDataFetched
        controller.watchActiveChannelError = nil

        let operation = WatchChannelOperation(controller: controller, context: context, recovery: true)

        operation.startAndWaitForCompletion()

        XCTAssertEqual(context.watchedAndSynchedChannelIds.count, 1)
        XCTAssertCall("recoverWatchedChannel(recovery:completion:)", on: controller, times: 1)
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
