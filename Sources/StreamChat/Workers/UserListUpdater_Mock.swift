//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of UserListUpdater
class UserListUpdaterMock: UserListUpdater {
    @Atomic var update_queries: [UserListQuery] = []
    @Atomic var update_policy: UpdatePolicy?
    @Atomic var update_completion: ((Error?) -> Void)?
    
    @Atomic var fetch_queries: [UserListQuery] = []
    @Atomic var fetch_completion: ((Result<UserListPayload, Error>) -> Void)?
    
    func cleanUp() {
        update_queries.removeAll()
        update_policy = nil
        update_completion = nil
        
        fetch_queries.removeAll()
        fetch_completion = nil
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
    
    override func fetch(
        userListQuery: UserListQuery,
        completion: @escaping (Result<UserListPayload, Error>) -> Void
    ) {
        _fetch_queries.mutate { $0.append(userListQuery) }
        fetch_completion = completion
    }
}
