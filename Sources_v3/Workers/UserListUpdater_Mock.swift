//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

/// Mock implementation of UserListUpdater
class UserListUpdaterMock<ExtraData: UserExtraData>: UserListUpdater<ExtraData> {
    @Atomic var update_queries: [UserListQuery] = []
    @Atomic var update_completion: ((Error?) -> Void)?
        
    override func update(userListQuery: UserListQuery, completion: ((Error?) -> Void)? = nil) {
        _update_queries.mutate { $0.append(userListQuery) }
        update_completion = completion
    }
}
