//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13.0, *)
final class StateLayerDatabaseObserver_Tests: XCTestCase {
    private var client: ChatClient_Mock!
    private var channelId: ChannelId!

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
        try observer.startObserving(onContextDidChange: { _ in
            changeCount += 1
            expectation.fulfill()
        })
        
        let firstPayload = makeChannelPayload(name: "first")
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: firstPayload)
        }
        
        try await waitForDuplicateCallbacks()
        
        #if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: defaultTimeout)
        #else
        wait(for: [expectation], timeout: defaultTimeout)
        #endif
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
        try observer.startObserving(onContextDidChange: { _ in
            changeCount += 1
            expectation.fulfill()
        })
        
        let secondPayload = makeChannelPayload(name: "second")
        try await client.mockDatabaseContainer.write { session in
            session.removeChannels(cids: Set([self.channelId]))
            try session.saveChannel(payload: secondPayload)
        }
        
        try await waitForDuplicateCallbacks()
        
        #if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: defaultTimeout)
        #else
        wait(for: [expectation], timeout: defaultTimeout)
        #endif
        XCTAssertEqual("second", observer.item?.name)
        XCTAssertEqual(1, changeCount)
    }
    
    func test_entityDidChangeCount_whenTwoContextsChange_thenTwoDidChange() async throws {
        let expectation = XCTestExpectation()
        var changeCount = 0
        let observer = makeChannelObserver()
        try observer.startObserving(onContextDidChange: { _ in
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
        
        #if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: defaultTimeout)
        #else
        wait(for: [expectation], timeout: defaultTimeout)
        #endif
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
        try observer.startObserving(onContextDidChange: { _ in
            changeCount += 1
            expectation.fulfill()
        })
        
        let secondPayload = makeChannelPayload(messageCount: 3, createdAtOffset: 5)
        try await client.mockDatabaseContainer.write { session in
            try session.saveChannel(payload: secondPayload)
        }
        
        try await waitForDuplicateCallbacks()
        
        #if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: defaultTimeout)
        #else
        wait(for: [expectation], timeout: defaultTimeout)
        #endif
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
        try observer.startObserving(onContextDidChange: { _ in
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
        
        #if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: defaultTimeout)
        #else
        wait(for: [expectation], timeout: defaultTimeout)
        #endif
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
        try observer.startObserving(onContextDidChange: { _ in
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
        
        #if swift(>=5.8)
        await fulfillment(of: [expectation], timeout: defaultTimeout)
        #else
        wait(for: [expectation], timeout: defaultTimeout)
        #endif
        XCTAssertEqual(11, observer.items.count)
        let expectedIds = (firstPayload.messages + secondPayload.messages + thirdPayload.messages).map(\.id)
        XCTAssertEqual(expectedIds, observer.items.map(\.id))
        XCTAssertEqual(2, changeCount)
    }
    
    // MARK: -
    
    private func makeChannelObserver() -> StateLayerDatabaseObserver<EntityResult, ChatChannel, ChannelDTO> {
        StateLayerDatabaseObserver(
            databaseContainer: client.mockDatabaseContainer,
            fetchRequest: ChannelDTO.fetchRequest(for: channelId),
            itemCreator: { try $0.asModel() as ChatChannel }
        )
    }
    
    private func makeMessagesListObserver() -> StateLayerDatabaseObserver<ListResult, ChatMessage, MessageDTO> {
        StateLayerDatabaseObserver(
            databaseContainer: client.mockDatabaseContainer,
            fetchRequest: MessageDTO.messagesFetchRequest(
                for: channelId,
                pageSize: 25,
                sortAscending: true,
                deletedMessagesVisibility: .alwaysVisible,
                shouldShowShadowedMessages: true
            ),
            itemCreator: { try $0.asModel() }
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

@available(iOS 13.0, *)
private extension XCTestCase {
    func waitForDuplicateCallbacks(nanoseconds: UInt64 = 50000) async throws {
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
