//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import XCTest

class ChatChannelListRouterMock: ChatChannelListRouter {
    var openCurrentUserProfileCalled: Bool = false
    var openChat_channelId: ChannelId?
    var openCreateNewChannelCalled: Bool = false

    override open func showCurrentUserProfile() {
        openCurrentUserProfileCalled = true
    }

    override open func showChannel(for cid: ChannelId) {
        openChat_channelId = cid
    }
}
