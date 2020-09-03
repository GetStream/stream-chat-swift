//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class DataStore_Tests: StressTestCase {
    // We use `_` because `Client<ExtraData>!` doesn't conform to `DataStoreProvider`
    var _client: Client<DefaultDataTypes>!
    
    override func setUp() {
        super.setUp()
        _client = Client.mock
    }
    
    func test_userIsLoaded() throws {
        let userId: UserId = .unique
        XCTAssertNil(dataStore.user(id: userId))
        try _client.databaseContainer.createUser(id: userId)
        XCTAssertNotNil(dataStore.user(id: userId))
    }
    
    func test_currentUserIsLoaded() throws {
        XCTAssertNil(dataStore.currentUser())
        try _client.databaseContainer.createCurrentUser()
        XCTAssertNotNil(dataStore.currentUser())
    }

    func test_channelIsLoaded() throws {
        let cid: ChannelId = .unique
        XCTAssertNil(dataStore.channel(cid: cid))
        try _client.databaseContainer.createChannel(cid: cid)
        XCTAssertNotNil(dataStore.channel(cid: cid))
    }
    
    func test_messageIsLoaded() throws {
        let id: MessageId = .unique
        XCTAssertNil(dataStore.message(id: id))
        try _client.databaseContainer.createMessage(id: id)
        XCTAssertNotNil(dataStore.message(id: id))
    }
}

// Make `DataStore_Tests` to test is the same way we will use it.
extension DataStore_Tests: DataStoreProvider {
    var client: Client<DefaultDataTypes> { _client }
}
