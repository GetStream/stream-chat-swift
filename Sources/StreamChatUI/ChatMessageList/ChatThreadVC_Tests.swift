//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatThreadVC_Tests: XCTestCase {
    var vc: ChatThreadVC!
    var channelControllerMock: ChatChannelController_Mock!
    var messageControllerMock: ChatMessageController_Mock!
    
    override func setUp() {
        super.setUp()
        vc = ChatThreadVC()
        channelControllerMock = ChatChannelController_Mock.mock()
        messageControllerMock = ChatMessageController_Mock.mock()
        vc.channelController = channelControllerMock
        vc.messageController = messageControllerMock
    }

    override func tearDown() {
        super.tearDown()
        vc = nil
        channelControllerMock = nil
        messageControllerMock = nil
    }
    
    func test_emptyAppearance() {
        messageControllerMock.simulateInitial(
            message: .mock(id: .unique, cid: .unique, text: "First message", author: .mock(id: .unique)),
            replies: [],
            state: .localDataFetched
        )
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }
    
    func test_defaultAppearance() {
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [],
            state: .remoteDataFetched
        )
        messageControllerMock.simulateInitial(
            message: .mock(id: .unique, cid: .unique, text: "First message", author: .mock(id: .unique)),
            replies: [
                .mock(
                    id: .unique,
                    cid: .unique,
                    text: "First reply",
                    author: .mock(id: .unique, name: "Author author")
                ),
                .mock(id: .unique, cid: .unique, text: "Second reply", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Third reply", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )
        messageControllerMock.simulate(state: .remoteDataFetched)
        vc.view.layoutIfNeeded()
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }
}
