//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatUserSearchController_Mock: ChatUserSearchController {
    public static func mock() -> ChatUserSearchController_Mock {
        .init(client: .mock())
    }
    
    public var users_mock: [ChatUser]?
    override public var users: LazyCachedMapCollection<ChatUser> {
        users_mock.map { $0.lazyCachedMap { $0 } } ?? super.users
    }
}
