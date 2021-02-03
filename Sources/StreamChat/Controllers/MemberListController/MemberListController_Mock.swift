//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// A mock for `ChatChannelMemberListController`.
final class ChatChannelMemberListControllerMock: ChatChannelMemberListController {
    @Atomic var members_simulated: [_ChatChannelMember<NoExtraData>]?
    override var members: LazyCachedMapCollection<_ChatChannelMember<NoExtraData>> {
        members_simulated.map { $0.lazyCachedMap { $0 } } ?? super.members
    }
    
    @Atomic var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
}
