//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public struct TestMemberEvent: MemberEvent, ChannelSpecificEvent, Hashable {
    public static var unique: TestMemberEvent { .init(cid: .unique, memberUserId: .unique) }

    public let cid: ChannelId
    public let memberUserId: UserId
}

public struct OtherEvent: Event {}
