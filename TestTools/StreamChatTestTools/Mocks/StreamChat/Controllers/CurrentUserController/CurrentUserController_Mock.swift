//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class CurrentUserController_Mock: CurrentChatUserController {
    var currentUser_simulated: CurrentChatUser?
    override var currentUser: CurrentChatUser? {
        currentUser_simulated ?? super.currentUser
    }

    var unreadCount_simulated: UnreadCount?
    override var unreadCount: UnreadCount {
        unreadCount_simulated ?? super.unreadCount
    }

    init() {
        super.init(client: .mock)
    }
}
