//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import XCTest

class ChatChannelListRouter_Mock<ExtraData: ExtraDataTypes>: _ChatChannelListRouter<ExtraData> {
    var openCurrentUserProfileCalled: Bool = false
    var openChat_channelId: ChannelId?
    var openCreateNewChannelCalled: Bool = false
    
    override open func showCurrentUserProfile() {
        openCurrentUserProfileCalled = true
    }

    override open func showMessageList(for cid: ChannelId) {
        openChat_channelId = cid
    }
}
