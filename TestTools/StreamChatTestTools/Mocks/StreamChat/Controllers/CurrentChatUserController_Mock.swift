//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class CurrentChatUserController_Mock: CurrentChatUserController, @unchecked Sendable {
    static func mock(client: ChatClient? = nil) -> CurrentChatUserController_Mock {
        .init(client: client ?? .mock())
    }

    @Atomic var currentUser_mock: CurrentChatUser?
    override var currentUser: CurrentChatUser? {
        currentUser_mock
    }
}
