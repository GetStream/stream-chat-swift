//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of UserListUpdater
class UserListUpdaterMock<ExtraData: UserExtraData>: UserListUpdater<ExtraData> {
    @Atomic var update_queries: [UserListQuery] = []
    @Atomic var update_policy: UpdatePolicy?
    @Atomic var update_completion: ((Error?) -> Void)?
    
    func cleanUp() {
        update_queries.removeAll()
        update_policy = nil
        update_completion = nil
    }
        
    override func update(
        userListQuery: UserListQuery,
        policy: UpdatePolicy = .merge,
        completion: ((Error?) -> Void)? = nil
    ) {
        _update_queries.mutate { $0.append(userListQuery) }
        update_policy = policy
        update_completion = completion
    }
}
