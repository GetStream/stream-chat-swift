//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class StateLayerDatabaseObserver_Tests: XCTestCase {
    private var client: ChatClient_Mock!
    private var channelId: ChannelId!
    @Atomic private var messageItemCreatorCounter = 0

    override func setUpWithError() throws {
        client = ChatClient_Mock(
            config: ChatClient_Mock.defaultMockedConfig
        )
        channelId = .unique
    }

    override func tearDownWithError() throws {
        client.cleanUp()
        channelId = nil
        client = nil
    }

    // MARK: Observing a Single Entity
    
    func test_entityDidChangeCount_whenInserting_thenSingleDidChange() async throws {
        let expectation = XCTestExpectation()
        var changeCount = 0
        let observer = makeChannelObserver()
        _ = try observer.startObserving(onContextDidChange: { _, _ in
            changeCount += 1
            expectation.fulfill()
        })
        
        let firstPayload = makeChannelPayload(name: "first")
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: firstPayload)
        }
        
        try await waitForDuplicateCallbacks()
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)

        XCTAssertEqual("first", observer.item?.name)
        XCTAssertEqual(1, changeCount)
    }
    
    func test_entityDidChangeCount_whenDeletingAndInserting_thenSingleDidChange() async throws {
        let firstPayload = makeChannelPayload(name: "first")
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: firstPayload)
        }
        
        let expectation = XCTestExpectation()
        var changeCount = 0
        let observer = makeChannelObserver()
        _ = try observer.startObserving(onContextDidChange: { _, _ in
            changeCount += 1
            expectation.fulfill()
        })
        
        let secondPayload = makeChannelPayload(name: "second")
        try await client.mockDatabaseContainer.write { session in
            session.removeChannels(cids: Set([self.channelId]))
            try session.saveChannel(payload: secondPayload)
        }
        
        try await waitForDuplicateCallbacks()
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)

        XCTAssertEqual("second", observer.item?.name)
        XCTAssertEqual(1, changeCount)
    }
    
    func test_entityDidChangeCount_whenTwoContextsChange_thenTwoDidChange() async throws {
        let expectation = XCTestExpectation()
        var changeCount = 0
        let observer = makeChannelObserver()
        _ = try observer.startObserving(onContextDidChange: { _, _ in
            changeCount += 1
            expectation.fulfill()
        })
        
        let firstPayload = makeChannelPayload(name: "first", team: "team1")
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: firstPayload)
        }
        let secondPayload = makeChannelPayload(name: "second", team: "team2")
        try await MainActor.run {
            let session = client.mockDatabaseContainer.viewContext
            try session.saveChannel(payload: secondPayload)
            try session.save()
        }
        
        try await waitForDuplicateCallbacks()
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)

        XCTAssertEqual("second", observer.item?.name)
        XCTAssertEqual("team2", observer.item?.team)
        XCTAssertEqual(2, changeCount)
    }
    
    // MARK: Observing List
    
    func test_listDidChangeCount_whenInserting_thenSingleDidChange() async throws {
        let firstPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 0)
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: firstPayload)
        }
        
        let expectation = XCTestExpectation()
        var changeCount = 0
        let observer = makeMessagesListObserver()
        _ = try observer.startObserving(onContextDidChange: { _, _ in
            changeCount += 1
            expectation.fulfill()
        })
        
        let secondPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 5)
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: secondPayload)
        }
        
        try await waitForDuplicateCallbacks()
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)

        XCTAssertEqual(8, observer.items.count)
        let expectedIds = (firstPayload.messages + secondPayload.messages).map(\.id)
        XCTAssertEqual(expectedIds, observer.items.map(\.id))
        XCTAssertEqual(1, changeCount)
    }
    
    func test_listDidChangeCount_whenDeletingAndInserting_thenSingleDidChange() async throws {
        let firstPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 0)
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: firstPayload)
        }
        
        let expectation = XCTestExpectation()
        var changeCount = 0
        let observer = makeMessagesListObserver()
        _ = try observer.startObserving(onContextDidChange: { _, _ in
            changeCount += 1
            expectation.fulfill()
        })
        
        let secondPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 5)
        try await client.mockDatabaseContainer.write { session in
            for messageId in firstPayload.messages.map(\.id) {
                let message = try XCTUnwrap(session.message(id: messageId))
                session.delete(message: message)
            }
            try session.saveChannel(payload: secondPayload)
        }
        
        try await waitForDuplicateCallbacks()
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)
        
        XCTAssertEqual(3, observer.items.count)
        XCTAssertEqual(secondPayload.messages.map(\.id), observer.items.map(\.id))
        XCTAssertEqual(1, changeCount)
    }
    
    func test_listDidChangeCount_whenTwoContextsChange_thenTwoDidChange() async throws {
        let firstPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 0)
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: firstPayload)
        }
        
        let expectation = XCTestExpectation()
        var changeCount = 0
        let observer = makeMessagesListObserver()
        _ = try observer.startObserving(onContextDidChange: { _, _ in
            changeCount += 1
            expectation.fulfill()
        })
        
        let secondPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 5)
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: secondPayload)
        }
        let thirdPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 8)
        try await MainActor.run {
            let session = client.mockDatabaseContainer.viewContext
            try session.saveChannel(payload: thirdPayload)
            try session.save()
        }
        
        try await waitForDuplicateCallbacks()
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)

        XCTAssertEqual(11, observer.items.count)
        let expectedIds = (firstPayload.messages + secondPayload.messages + thirdPayload.messages).map(\.id)
        XCTAssertEqual(expectedIds, observer.items.map(\.id))
        XCTAssertEqual(2, changeCount)
    }
    
    // MARK: - Reusing Existing Items
    
    func test_reuseChannels_whenSomeChange_thenOthersAreReused() async throws {
        let memberId = UserId.unique
        let memberPayload = MemberPayload.dummy(user: .dummy(userId: memberId))
        let query = ChannelListQuery(
            filter: .in(.members, values: [memberId]),
            sort: [.init(key: .createdAt, isAscending: true)]
        )
        let makePayload: (Int) -> ChannelListPayload = { count in
            let channelPayloads = (0..<count)
                .map {
                    self.dummyPayload(
                        with: ChannelId(type: .messaging, id: "\($0)"),
                        members: [memberPayload],
                        createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0))
                    )
                }
            return ChannelListPayload(channels: channelPayloads)
        }
        
        try await client.mockDatabaseContainer.write { session in
            session.saveChannelList(payload: makePayload(5), query: query)
        }
        
        let expectation = XCTestExpectation()
        var itemCreatorCounter = 0
        let channelListObserver = StateLayerDatabaseObserver(
            database: client.mockDatabaseContainer,
            fetchRequest: ChannelDTO.channelListFetchRequest(
                query: query,
                chatClientConfig: client.config
            ),
            itemCreator: {
                itemCreatorCounter += 1
                return try $0.asModel()
            },
            itemReuseKeyPaths: (\ChatChannel.cid.rawValue, \ChannelDTO.cid),
            sorting: query.sort.runtimeSorting
        )
        _ = try channelListObserver.startObserving(onContextDidChange: { _, _ in
            expectation.fulfill()
        })
        XCTAssertEqual(5, itemCreatorCounter)
        
        // Change 1 existing
        try await client.mockDatabaseContainer.write { session in
            let channelPayload = makePayload(1).channels[0]
            try session.saveChannel(payload: channelPayload, query: query, cache: nil)
        }
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)

        // 4 are reused, 1 is created
        XCTAssertEqual(6, itemCreatorCounter)
    }
    
    func test_reuseMessages_whenSomeChange_thenOthersAreReused() async throws {
        let firstPayload = makeChannelPayload(messageCount: 10, createdAtOffset: 0)
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: firstPayload)
        }
        
        let expectation = XCTestExpectation()
        let observer = makeMessagesListObserver()
        _ = try observer.startObserving(onContextDidChange: { _, _ in
            expectation.fulfill()
        })
        XCTAssertEqual(10, messageItemCreatorCounter)
        
        // Change 5 existing messages
        let secondPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 0)
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: secondPayload)
        }
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)

        // 5 are reused, 5 are created
        XCTAssertEqual(15, messageItemCreatorCounter)
    }
    
    func test_reuseReactions_whenSomeChange_thenOthersAreReused() async throws {
        let channelPayload = makeChannelPayload(messageCount: 5, createdAtOffset: 0)
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: channelPayload)
        }
        let messageId = try XCTUnwrap(channelPayload.messages.first?.id)
        let makePayload: (Int) -> MessageReactionsPayload = { count in
            let reactions = (0..<count)
                .reversed() // last updated ones first
                .map {
                    MessageReactionPayload.dummy(
                        messageId: messageId,
                        createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0)),
                        updatedAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0)),
                        user: .dummy(userId: .unique)
                    )
                }
            return MessageReactionsPayload(reactions: reactions)
        }
        let query = ReactionListQuery(messageId: messageId)
        try await client.databaseContainer.write { session in
            session.saveReactions(payload: makePayload(5), query: query)
        }
        let expectation = XCTestExpectation()
        var itemCreatorCounter = 0
        let reactionListObserver = StateLayerDatabaseObserver(
            database: client.mockDatabaseContainer,
            fetchRequest: MessageReactionDTO.reactionListFetchRequest(query: query),
            itemCreator: {
                itemCreatorCounter += 1
                return try $0.asModel()
            },
            itemReuseKeyPaths: (\ChatMessageReaction.id, \MessageReactionDTO.id)
        )
        _ = try reactionListObserver.startObserving(onContextDidChange: { _, _ in
            expectation.fulfill()
        })
        XCTAssertEqual(5, itemCreatorCounter)
        
        // Change 1 existing
        try await client.mockDatabaseContainer.write { session in
            try session.saveReaction(payload: makePayload(1).reactions[0], query: query, cache: nil)
        }
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)

        // 4 are reused, 1 is created
        XCTAssertEqual(6, itemCreatorCounter)
    }
    
    func test_reuseThreads_whenSomeChange_thenOthersAreReused() async throws {
        let makePayload: (Int) -> ThreadListPayload = { count in
            let threads = (0..<count)
                .map { ThreadPayload.dummy(parentMessageId: "\($0)") }
            return ThreadListPayload(threads: threads, next: nil)
        }
        try await client.databaseContainer.write { session in
            session.saveThreadList(payload: makePayload(5))
        }
        let expectation = XCTestExpectation()
        var itemCreatorCounter = 0
        let threadListObserver = StateLayerDatabaseObserver(
            database: client.mockDatabaseContainer,
            fetchRequest: ThreadDTO.threadListFetchRequest(),
            itemCreator: {
                itemCreatorCounter += 1
                return try $0.asModel()
            },
            itemReuseKeyPaths: (\ChatThread.reuseId, \ThreadDTO.reuseId)
        )
        _ = try threadListObserver.startObserving(onContextDidChange: { _, _ in
            expectation.fulfill()
        })
        XCTAssertEqual(5, itemCreatorCounter)
        
        // Change 1 existing
        try await client.mockDatabaseContainer.write { session in
            try session.saveThread(payload: makePayload(1).threads[0], cache: nil)
        }
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)

        // 4 are reused, 1 is created
        XCTAssertEqual(6, itemCreatorCounter)
    }
    
    func test_reuseUsers_whenSomeChange_thenOthersAreReused() async throws {
        let makePayload: (Int) -> UserListPayload = { count in
            let users = (0..<count)
                .map { UserPayload.dummy(userId: "\($0)", name: "name_\($0)") }
            return UserListPayload(users: users)
        }
        let query = UserListQuery(
            filter: .query(.id, text: .unique),
            sort: [.init(key: .id, isAscending: true)]
        )
        try await client.databaseContainer.write { session in
            session.saveUsers(payload: makePayload(5), query: query)
        }
        let expectation = XCTestExpectation()
        var itemCreatorCounter = 0
        let usersObserver = StateLayerDatabaseObserver(
            database: client.mockDatabaseContainer,
            fetchRequest: UserDTO.userListFetchRequest(query: query),
            itemCreator: {
                itemCreatorCounter += 1
                return try $0.asModel()
            },
            itemReuseKeyPaths: (\ChatUser.id, \UserDTO.id)
        )
        _ = try usersObserver.startObserving(onContextDidChange: { _, _ in
            expectation.fulfill()
        })
        XCTAssertEqual(5, itemCreatorCounter)
        
        // Change 1 existing
        try await client.mockDatabaseContainer.write { session in
            try session.saveUser(payload: makePayload(1).users[0])
        }
        
        await fulfillmentCompatibility(of: [expectation], timeout: defaultTimeout)

        // 4 are reused, 1 is created
        XCTAssertEqual(6, itemCreatorCounter)
    }
    
    // MARK: -
    
    private func makeChannelObserver() -> StateLayerDatabaseObserver<EntityResult, ChatChannel, ChannelDTO> {
        StateLayerDatabaseObserver(
            database: client.mockDatabaseContainer,
            fetchRequest: ChannelDTO.fetchRequest(for: channelId),
            itemCreator: { try $0.asModel() as ChatChannel }
        )
    }
    
    private func makeMessagesListObserver() -> StateLayerDatabaseObserver<ListResult, ChatMessage, MessageDTO> {
        StateLayerDatabaseObserver(
            database: client.mockDatabaseContainer,
            fetchRequest: MessageDTO.messagesFetchRequest(
                for: channelId,
                pageSize: 25,
                sortAscending: true,
                deletedMessagesVisibility: .alwaysVisible,
                shouldShowShadowedMessages: true
            ),
            itemCreator: { [weak self] in
                self?._messageItemCreatorCounter.mutate { $0 += 1 }
                return try $0.asModel()
            },
            itemReuseKeyPaths: (\ChatMessage.id, \MessageDTO.id)
        )
    }
    
    private func makeChannelPayload(name: String?, team: String? = nil) -> ChannelPayload {
        ChannelPayload.dummy(channel: .dummy(cid: channelId, name: name, team: team))
    }
    
    private func makeChannelPayload(messageCount: Int, createdAtOffset: Int) -> ChannelPayload {
        let messages: [MessagePayload] = (0..<messageCount)
            .map {
                .dummy(
                    messageId: "\($0 + createdAtOffset)",
                    createdAt: Date(timeIntervalSinceReferenceDate: TimeInterval($0 + createdAtOffset)),
                    cid: channelId
                )
            }
        return ChannelPayload.dummy(channel: .dummy(cid: channelId), messages: messages)
    }
}

private extension XCTestCase {
    func waitForDuplicateCallbacks(nanoseconds: UInt64 = 50000) async throws {
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
