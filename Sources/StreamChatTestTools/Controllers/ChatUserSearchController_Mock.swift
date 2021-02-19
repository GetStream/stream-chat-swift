//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatUserSearchController_Mock<ExtraData: ExtraDataTypes>: _ChatUserSearchController<ExtraData> {
    public static func mock() -> ChatUserSearchController_Mock<ExtraData> {
        .init(client: .mock())
    }
    
    public var users_mock: [_ChatUser<ExtraData.User>]?
    override public var users: LazyCachedMapCollection<_ChatUser<ExtraData.User>> {
        users_mock.map { $0.lazyCachedMap { $0 } } ?? super.users
    }
}
