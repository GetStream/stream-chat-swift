//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class ChatUserSearchController_Mock: ChatUserSearchController, @unchecked Sendable {
    var searchCallCount = 0

    static func mock(client: ChatClient? = nil) -> ChatUserSearchController_Mock {
        .init(client: client ?? .mock())
    }

    var users_mock: [ChatUser]?
    override var userArray: [ChatUser] {
        users_mock ?? super.userArray
    }

    override func search(query: UserListQuery, completion: (@MainActor (Error?) -> Void)? = nil) {
        searchCallCount += 1
        callback {
            completion?(nil)
        }
    }

    override func search(term: String?, completion: (@MainActor (Error?) -> Void)? = nil) {
        searchCallCount += 1
        users_mock = users_mock?.filter { user in
            user.name?.contains(term ?? "") ?? true
        }
        callback {
            completion?(nil)
        }
    }
}
