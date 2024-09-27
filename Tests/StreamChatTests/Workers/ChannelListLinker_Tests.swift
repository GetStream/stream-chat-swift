//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListLinker_Tests: XCTestCase {
    private var channelListLinker: ChannelListLinker!
    private var database: DatabaseContainer_Spy!
    private var eventNotificationCenter: EventNotificationCenter!
    private var loadedChannels: [ChatChannel]!
    private var memberId: UserId!
    private var worker: ChannelListUpdater_Spy!
    private let pageSize = 5
    
    override func setUpWithError() throws {
        database = DatabaseContainer_Spy()
        eventNotificationCenter = EventNotificationCenter(database: database)
        loadedChannels = []
        memberId = .unique
        worker = ChannelListUpdater_Spy(database: database, apiClient: APIClient_Spy())
        worker.startWatchingChannels_completion_result = .success(())
        worker.link_completion_result = .success(())
        worker.unlink_completion_result = .success(())
        setUpChannelListLinker(filter: nil)
    }

    override func tearDownWithError() throws {
        database = nil
        eventNotificationCenter = nil
        loadedChannels = nil
        memberId = nil
        worker = nil
    }
    
    // MARK: -
    
    func test_skippingLinking_whenNoFilterAndAutomaticFilteringDisabled() throws {
        let events = events(with: .mock(cid: .unique))
        for event in events {
            setUpChannelListLinker(filter: nil, automatic: false)
            let result = processEventAndWait(event)
            XCTAssertEqual(ChannelListLinker.LinkingAction.none, result, event.name)
        }
    }
    
    func test_linkingChannel_whenChannelOnTheLoadedPage_thenItIsLinked() throws {
        loadedChannels = try generateChannels(count: pageSize)
        let events = events(with: try generateChannel(index: -1))
        for event in events {
            setUpChannelListLinker(filter: nil)
            let result = processEventAndWait(event)
            XCTAssertEqual(ChannelListLinker.LinkingAction.link, result, event.name)
        }
    }
    
    func test_linkingChannel_whenChannelOnOlderPage_thenItIsNotLinked() throws {
        loadedChannels = try generateChannels(count: pageSize)
        let events = events(with: try generateChannel(index: 6))
        for event in events {
            setUpChannelListLinker(filter: nil)
            let result = processEventAndWait(event)
            XCTAssertEqual(ChannelListLinker.LinkingAction.none, result, event.name)
        }
    }
    
    func test_linkingChannel_notificationAddedToChannelEvent_whenLessThanRequestedIsLoaded_thenItIsLinked() throws {
        loadedChannels = try generateChannels(count: 0)
        let events = events(with: try generateChannel(index: 0))
        for event in events {
            setUpChannelListLinker(filter: nil)
            let result = processEventAndWait(event)
            XCTAssertEqual(ChannelListLinker.LinkingAction.link, result, event.name)
        }
    }
    
    func test_linkingChannel_channelUpdatedEvent_whenItMatchesTheFilter_thenItIsLinked() throws {
        loadedChannels = try generateChannels(count: pageSize)
        let events = events(with: try generateChannel(index: 0))
        for event in events {
            setUpChannelListLinker(filter: { _ in
                // simulate channel matching the query, e.g. extraData property based filtering
                true
            })
            let result = processEventAndWait(event)
            XCTAssertEqual(ChannelListLinker.LinkingAction.link, result, event.name)
        }
    }
    
    func test_unlinkingChannel_channelUpdatedEvent_whenItDoesNotMatchTheFilterAnymore_thenItIsUnlinked() throws {
        loadedChannels = try generateChannels(count: pageSize)
        let events = events(with: loadedChannels[0])
        for event in events {
            setUpChannelListLinker(filter: { _ in
                // simulate channel not matching the query anymore, e.g. extraData property based filtering
                false
            })
            let result = processEventAndWait(event)
            XCTAssertEqual(ChannelListLinker.LinkingAction.unlink, result, event.name)
        }
    }

    // MARK: - Test Data
    
    private func setUpChannelListLinker(filter: ((ChatChannel) -> Bool)?, automatic: Bool = true) {
        let query = ChannelListQuery(
            filter: .in(.members, values: [memberId]),
            sort: [.init(key: .createdAt, isAscending: true)],
            pageSize: pageSize
        )
        var config = ChatClientConfig(apiKeyString: "123")
        config.isChannelAutomaticFilteringEnabled = automatic
        channelListLinker = ChannelListLinker(
            query: query,
            filter: filter,
            loadedChannels: { StreamCollection(self.loadedChannels) },
            clientConfig: config,
            databaseContainer: database,
            worker: worker
        )
        channelListLinker.start(with: eventNotificationCenter)
    }
    
    private func events(with channel: ChatChannel) -> [Event] {
        [
            NotificationAddedToChannelEvent(
                channel: channel,
                unreadCount: nil,
                member: .mock(id: memberId),
                createdAt: Date()
            ),
            MessageNewEvent(
                user: .mock(id: memberId),
                message: .unique,
                channel: channel,
                createdAt: Date(),
                watcherCount: nil,
                unreadCount: nil
            ),
            NotificationMessageNewEvent(
                channel: channel,
                message: .unique,
                createdAt: Date(),
                unreadCount: nil
            ),
            ChannelUpdatedEvent(
                channel: channel,
                user: nil,
                message: nil,
                createdAt: Date()
            ),
            ChannelVisibleEvent(
                cid: channel.cid,
                user: .mock(id: memberId),
                createdAt: Date()
            )
        ]
    }
    
    private func generateChannel(index: Int) throws -> ChatChannel {
        let query = channelListLinker.query
        var model: ChatChannel!
        try database.writeSynchronously { session in
            let payload = ChannelPayload.dummy(
                channel: .dummy(
                    name: "Name \(index)",
                    createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval(index))
                )
            )
            let dto = try session.saveChannel(payload: payload, query: query, cache: nil)
            model = try dto.asModel()
        }
        return model
    }
    
    private func generateChannels(count: Int) throws -> [ChatChannel] {
        try (0..<count).map { try generateChannel(index: $0) }
    }
}

extension ChannelListLinker_Tests {
    func processEventAndWait(_ event: Event) -> ChannelListLinker.LinkingAction {
        let expectation = XCTestExpectation(description: "Handle \(event.name)")
        var action = ChannelListLinker.LinkingAction.none
        channelListLinker.didHandleChannel = { _, receivedAction in
            action = receivedAction
            expectation.fulfill()
        }
        eventNotificationCenter.process(event, postNotification: true)
        wait(for: [expectation], timeout: defaultTimeout)
        return action
    }
}
