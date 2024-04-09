//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of UserListUpdater
final class UserListUpdater_Mock: UserListUpdater {
    @Atomic var update_queries: [UserListQuery] = []
    @Atomic var update_policy: UpdatePolicy?
    @Atomic var update_completion: ((Result<[ChatUser], Error>) -> Void)?

    @Atomic var fetch_queries: [UserListQuery] = []
    @Atomic var fetch_completions: [(Result<UserListPayload, Error>) -> Void] = []
    @Atomic var fetch_query_called: (UserListQuery) -> Void = { _ in }
    
    @Atomic var fetch_completion: ((Result<UserListPayload, Error>) -> Void)?
    @Atomic var fetch_completion_result: Result<UserListPayload, Error>?

    func cleanUp() {
        update_queries.removeAll()
        update_policy = nil
        update_completion = nil

        fetch_queries.removeAll()
        fetch_completions.removeAll()
        fetch_completion = nil
        fetch_completion_result = nil
    }

    override func update(
        userListQuery: UserListQuery,
        policy: UpdatePolicy = .merge,
        completion: ((Result<[ChatUser], Error>) -> Void)? = nil
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
        _fetch_completions.mutate { $0.append(completion) }
        fetch_query_called(userListQuery)
        fetch_completion = completion
        fetch_completion_result?.invoke(with: completion)
    }
}
