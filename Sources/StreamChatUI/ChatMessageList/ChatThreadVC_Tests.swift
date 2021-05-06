//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
import StreamChatUI
import XCTest

final class ChatThreadVC_Tests: XCTestCase {
    private var subject: ChatThreadVC!
    private var channelController: ChatChannelController_Mock<NoExtraData>!
    private var messageController: ChatMessageController_Mock<NoExtraData>!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        channelController = .mock()
        messageController = .mock()
        
        subject = .init()
        subject.channelController = channelController
        subject.messageController = messageController
    }
    
    // MARK: - Tests
    
    func test_threadVC_loadsInitialReplies() {
        // we need `viewDidLoad` to be called as replies are loaded there
        subject.loadViewIfNeeded()
        
        XCTAssertTrue(messageController.loadNextReplies_called)
    }
    
    func test_threadVC_hasStickyHeader() {
        XCTAssertTrue(subject.messageListLayout.hasStickyTopItem)
    }
}
