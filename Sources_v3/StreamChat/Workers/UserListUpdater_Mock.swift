//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of UserListUpdater
class UserListUpdaterMock<ExtraData: UserExtraData>: UserListUpdater<ExtraData> {
    @Atomic var update_queries: [UserListQuery<ExtraData>] = []
    @Atomic var update_completion: ((Error?) -> Void)?
        
    override func update(userListQuery: UserListQuery<ExtraData>, completion: ((Error?) -> Void)? = nil) {
        _update_queries.mutate { $0.append(userListQuery) }
        update_completion = completion
    }
}
