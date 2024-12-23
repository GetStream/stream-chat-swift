//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DataStore_Tests: XCTestCase {
    var _client: ChatClient!

    override func setUp() {
        super.setUp()
        _client = ChatClient.mock
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&_client)
        (_client as? ChatClient_Mock)?.cleanUp()
        _client = nil
        super.tearDown()
    }

    func test_userIsLoaded() throws {
        let userId: UserId = .unique
        XCTAssertNil(dataStore.user(id: userId))
        try _client.databaseContainer.createUser(id: userId)
        XCTAssertNotNil(dataStore.user(id: userId))
        
        DispatchQueue.global().sync {
            XCTAssertNotNil(dataStore.user(id: userId))
        }
    }

    func test_currentUserIsLoaded() throws {
        XCTAssertNil(dataStore.currentUser())
        try _client.databaseContainer.createCurrentUser()
        XCTAssertNotNil(dataStore.currentUser)
        
        DispatchQueue.global().sync {
            XCTAssertNotNil(dataStore.currentUser)
        }
    }

    func test_channelIsLoaded() throws {
        let cid: ChannelId = .unique
        XCTAssertNil(dataStore.channel(cid: cid))
        try _client.databaseContainer.createChannel(cid: cid)
        XCTAssertNotNil(dataStore.channel(cid: cid))
        
        DispatchQueue.global().sync {
            XCTAssertNotNil(dataStore.channel(cid: cid))
        }
    }

    func test_messageIsLoaded() throws {
        let id: MessageId = .unique
        XCTAssertNil(dataStore.message(id: id))
        try _client.databaseContainer.createMessage(id: id)
        XCTAssertNotNil(dataStore.message(id: id))
        
        DispatchQueue.global().sync {
            XCTAssertNotNil(dataStore.message(id: id))
        }
    }
    
    func test_threadIsLoaded() throws {
        let parentMessageId: MessageId = .unique
        XCTAssertNil(dataStore.message(id: parentMessageId))
        try _client.databaseContainer.writeSynchronously { session in
            let payload = ThreadPayload.dummy(parentMessageId: parentMessageId)
            try session.saveThread(payload: payload, cache: nil)
        }
        XCTAssertNotNil(dataStore.thread(parentMessageId: parentMessageId))
        
        DispatchQueue.global().sync {
            XCTAssertNotNil(dataStore.thread(parentMessageId: parentMessageId))
        }
    }
}

// Make `DataStore_Tests` to test is the same way we will use it.
extension DataStore_Tests: DataStoreProvider {
    var client: ChatClient { _client }
}
