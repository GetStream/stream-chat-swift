//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

extension ChannelMemberListPayload {
    static func mock() -> ChannelMemberListPayload {
        let json = XCTestCase.mockData(fromFile: "ChannelMembersQuery", extension: "json")
        let payload = try! JSONDecoder.default.decode(ChannelMemberListPayload.self, from: json)
        return payload
    }
}

/// A mock for `ChatChannelMemberListController`.
final class ChatChannelMemberListControllerMock: ChatChannelMemberListController {
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
