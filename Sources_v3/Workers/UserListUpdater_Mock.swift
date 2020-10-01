//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

/// Mock implementation of UserListUpdater
class UserListUpdaterMock<ExtraData: UserExtraData>: UserListUpdater<ExtraData> {
    @Atomic var update_query: UserListQuery?
    @Atomic var update_calls_counter = 0
    @Atomic var update_completion: ((Error?) -> Void)?
        
    override func update(userListQuery: UserListQuery, completion: ((Error?) -> Void)? = nil) {
        update_query = userListQuery
        update_completion = completion
        _update_calls_counter.mutate { $0 += 1 }
    }
}
