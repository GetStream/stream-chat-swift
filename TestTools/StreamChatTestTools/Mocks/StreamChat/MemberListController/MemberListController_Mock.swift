//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// A mock for `ChatChannelMemberListController`.
final class ChatChannelMemberListController_Mock: ChatChannelMemberListController, @unchecked Sendable {
    @Atomic var members_simulated: [ChatChannelMember]?
    override var members: [ChatChannelMember] {
        members_simulated ?? super.members
    }

    @Atomic var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
}
