//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageListVC_Tests: XCTestCase {
    var vc: ChatMessageListVC!
    var channelControllerMock: ChatChannelController_Mock<NoExtraData>!
    
    override func setUp() {
        super.setUp()
        vc = ChatMessageListVC()
        channelControllerMock = ChatChannelController_Mock.mock()
        vc.channelController = channelControllerMock
    }

    override func tearDown() {
        super.tearDown()
        vc = nil
        channelControllerMock = nil
    }
    
    func test_emptyAppearance() {
        AssertSnapshot(vc, isEmbeddedInNavigationController: true)
    }
    
    func test_defaultAppearance() {
        channelControllerMock.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(id: .unique, text: "One", author: .mock(id: .unique)),
                .mock(id: .unique, text: "Two", author: .mock(id: .unique)),
                .mock(id: .unique, text: "Three", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )
        AssertSnapshot(
            vc,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }
}
