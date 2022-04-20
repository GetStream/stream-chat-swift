//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class CurrentChatUserController_Mock: CurrentChatUserController {
    public static func mock() -> CurrentChatUserController_Mock {
        .init(client: .mock())
    }
    
    public var currentUser_mock: CurrentChatUser?
    override public var currentUser: CurrentChatUser? {
        currentUser_mock
    }
}
