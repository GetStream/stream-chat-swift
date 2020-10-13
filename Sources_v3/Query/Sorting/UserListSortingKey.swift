//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// `UserListSortingKey` is keys by which you can get sorted users after query.
public enum UserListSortingKey: String, SortingKey {
    /// Sort users by id.
    case id
    /// Sort users by role. (`user`, `admin`, `guest`, `anonymous`)
    case role = "userRoleRaw"
    /// Sort users by ban status.
    case isBanned
    /// Sort users by last activity date.
    case lastActivityAt
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value: String
        
        switch self {
        case .id: value = "id"
        case .role: value = "role"
        case .isBanned: value = "banned"
        case .lastActivityAt: value = "last_active"
        }
        
        try container.encode(value)
    }
}

extension UserListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let stringKeyPath: KeyPath<UserDTO, String> = \UserDTO.id
        return .init(keyPath: stringKeyPath, ascending: false)
    }()
    
    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        .init(key: rawValue, ascending: isAscending)
    }
}
