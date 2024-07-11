//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class UserSearch_Mock: UserSearch {

    var searchCallCount = 0

    public static func mock(client: ChatClient? = nil) -> UserSearch_Mock {
        .init(client: client ?? .mock(bundle: Bundle(for: Self.self)))
    }
    
    @MainActor public func setUsers(_ users: [ChatUser]) {
        self.state.users = StreamCollection(users)
    }
    
    public override func loadMoreUsers(limit: Int? = nil) async throws -> [ChatUser] {
        await Array(state.users)
    }

    override public func search(term: String?) async throws -> [ChatUser] {
        searchCallCount += 1
        let users = await state.users.filter { user in
            if let term {
                return user.name?.contains(term) ?? true
            } else {
                return true
            }
        }
        await setUsers(users)
        return users
    }

    override public func search(query: UserListQuery) async throws -> [ChatUser] {
        searchCallCount += 1
        return await Array(state.users)
    }
}
