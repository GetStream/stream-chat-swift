//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import XCTest

class ChatChannelListRouter_Mock<ExtraData: ExtraDataTypes>: _ChatChannelListRouter<ExtraData> {
    var openCurrentUserProfile_currentUser: _CurrentChatUser<ExtraData.User>?
    var openChat_channel: _ChatChannel<ExtraData>?
    var openCreateNewChannelCalled: Bool = false
    
    override open func openCurrentUserProfile(for currentUser: _CurrentChatUser<ExtraData.User>) {
        openCurrentUserProfile_currentUser = currentUser
    }
    
    override open func openChat(for channel: _ChatChannel<ExtraData>) {
        openChat_channel = channel
    }
        
    override open func openCreateNewChannel() {
        openCreateNewChannelCalled = true
    }
}
