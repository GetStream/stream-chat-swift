//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

/// A mock for `ChatChannelMemberListController`.
final class ChatChannelMemberListControllerMock: ChatChannelMemberListController {
    @Atomic var members_simulated: [_ChatChannelMember<DefaultExtraData.User>]?
    override var members: [_ChatChannelMember<DefaultExtraData.User>] {
        members_simulated ?? super.members
    }
    
    @Atomic var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
}
