//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// A mock for `ChatChannelMemberListController`.
final class ChatChannelMemberListController_Mock: ChatChannelMemberListController {
    @Atomic var members_simulated: [ChatChannelMember]?
    override var members: LazyCachedMapCollection<ChatChannelMember> {
        members_simulated.map { $0.lazyCachedMap { $0 } } ?? super.members
    }
    
    @Atomic var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
}
