//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class ChatUserSearchController_Mock: ChatUserSearchController {

    var searchCallCount = 0

    static func mock(client: ChatClient? = nil) -> ChatUserSearchController_Mock {
        .init(client: client ?? .mock())
    }

    var users_mock: [ChatUser]?
    override var userArray: [ChatUser] {
        users_mock ?? super.userArray
    }

    override func search(query: UserListQuery, completion: ((Error?) -> Void)? = nil) {
        searchCallCount += 1
        completion?(nil)
    }

    override func search(term: String?, completion: ((Error?) -> Void)? = nil) {
        searchCallCount += 1
        users_mock = users_mock?.filter { user in
            user.name?.contains(term ?? "") ?? true
        }
        completion?(nil)
    }
}
