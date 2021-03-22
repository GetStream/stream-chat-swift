//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import XCTest

final class ChatChannelVC_Tests: XCTestCase {
    func testChatClientChannelVC() {
        let client = ChatClient(
            config: .init(apiKeyString: "test"),
            tokenProvider: .anonymous
        )
        
        let channelId: ChannelId = .unique
        let channelVC = client.channelVC(cid: channelId)
        XCTAssertEqual(channelVC.channelController.cid, channelId)
    }
}
