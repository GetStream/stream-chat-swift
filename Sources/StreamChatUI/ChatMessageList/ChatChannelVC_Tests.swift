//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

// ====== Example test only ====

class ChatChannelVC_Tests: XCTestCase {
    var vc: ChatChannelVC<DefaultUIExtraData>!
    var channelController: ChatChannelController_Mock<DefaultUIExtraData>!
    
    override func setUp() {
        super.setUp()
        channelController = .mock()
        vc = ChatChannelVC()
        vc.controller = channelController
        
        // Load default data
        let cid = ChannelId(type: .messaging, id: "test")
        let message: _ChatMessage<DefaultUIExtraData> = .mock(
            id: UUID().uuidString,
            text: "This is a test message",
            author: .init(id: "luke", name: "Luke Skywalker", imageURL: nil)
        )
        let channel: _ChatChannel<DefaultUIExtraData> = .mock(cid: cid, extraData: .init(name: "Family chat", imageURL: nil))
        
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
        XCTAssertEqual(vc.collectionView.numberOfItems(inSection: 0), 1)
    }
}
