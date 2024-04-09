//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

@available(iOS 13.0, *)
public class UserSearch_Mock: UserSearch {

    var searchCallCount = 0

    public static func mock(client: ChatClient? = nil) -> UserSearch_Mock {
        .init(client: client ?? .mock(bundle: Bundle(for: Self.self)))
    }
    
    public func setUsers(_ users: [ChatUser]) {
        self.state.users = StreamCollection(users)
    }
    
    public override func loadNextUsers(limit: Int? = nil) async throws -> [ChatUser] {
        Array(state.users)
    }

    override public func search(term: String?) async throws -> [ChatUser] {
        searchCallCount += 1
        let users = state.users.filter { user in
            if let term {
                return user.name?.contains(term) ?? true
            } else {
                return true
            }
        }
        setUsers(users)
        return users
    }

    override public func search(query: UserListQuery) async throws -> [ChatUser] {
        searchCallCount += 1
        return Array(state.users)
    }
}
