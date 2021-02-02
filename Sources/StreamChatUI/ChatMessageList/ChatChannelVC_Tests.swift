//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//
import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

// ====== Example test only ====
class ChatChannelVC_Tests: XCTestCase {
    var vc: ChatChannelVC!
    var channelController: ChatChannelController_Mock<NoExtraData>!
    var userSuggestionSearchController: ChatUserSearchController_Mock<NoExtraData>!
    
    override func setUp() {
        super.setUp()
        channelController = .mock()
        userSuggestionSearchController = .mock()
        vc = ChatChannelVC()
        vc.channelController = channelController
        vc.userSuggestionSearchController = userSuggestionSearchController
        // Load default data
        let cid = ChannelId(type: .messaging, id: "test")
        let message: _ChatMessage = _ChatMessage<NoExtraData>.mock(
            id: UUID().uuidString,
            text: "This is a test message",
            author: _ChatUser.mock(
                id: "ID",
                extraData: NoExtraData.defaultValue
            )
        )
        
        let channel = _ChatChannel<NoExtraData>.mock(cid: cid, name: "Family Chat")
        channelController.simulateInitial(channel: channel, messages: [message], state: .remoteDataFetched)
    }
    
    override func tearDown() {
        vc = nil
        channelController = nil
        super.tearDown()
    }
    
    func test_allMessagesAreLoaded() {
        // load view
        vc.loadViewIfNeeded()
        XCTAssertEqual(vc.numberOfMessagesInChatMessageListVC(.init()), 1)
    }
}
