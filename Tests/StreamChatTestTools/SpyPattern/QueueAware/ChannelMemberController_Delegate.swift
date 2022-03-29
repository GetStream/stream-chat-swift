//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `ChatChannelMemberControllerDelegate` implementation allowing capturing the delegate calls
final class ChannelMemberController_Delegate: QueueAwareDelegate, ChatChannelMemberControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didUpdateMember_change: EntityChange<ChatChannelMember>?

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        validateQueue()
        self.state = state
    }

    func memberController(_ controller: ChatChannelMemberController, didUpdateMember change: EntityChange<ChatChannelMember>) {
        validateQueue()
        didUpdateMember_change = change
    }
}
