//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A sorting key protocol.
public protocol SortingKey: Encodable {}

/// Sorting options.
///
/// For example:
/// ```
/// // Sort channels by the last message date:
/// let sorting = Sorting("lastMessageDate")
/// ```
public struct Sorting<Key: SortingKey>: Encodable, CustomStringConvertible {
    /// A sorting field name.
    public let key: Key
    /// A sorting direction.
    public let direction: Int
    
    private enum CodingKeys: String, CodingKey {
        case key = "field"
        case direction
    }
    
    /// True if the sorting in ascending order, otherwise false.
    public var isAscending: Bool { direction == 1 }
    
    public var description: String { "\(key):\(direction)" }
    
    /// Init sorting options.
    ///
    /// - Parameters:
    ///     - key: a sorting key.
    ///     - isAscending: a direction of the sorting.
    public init(key: Key, isAscending: Bool = false) {
        self.key = key
        direction = isAscending ? 1 : -1
    }
}

// MARK: Channel List Sorting Key

/// `ChannelListSortingKey` is keys by which you can get sorted channels after query.
public enum ChannelListSortingKey: String, SortingKey {
    /// The default sorting is by the last massage date or a channel created date. The same as by `updatedDate`.
    case `default` = "defaultSortingAt"
    /// Sort channels by date they were created.
    case createdAt
    /// Sort channels by date they were updated.
    case updatedAt
    /// Sort channels by the last message date..
    case lastMessageAt
    /// Sort channels by number of members.
    case memberCount
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value: String
        
        switch self {
        case .default: value = "updated_at"
        case .createdAt: value = "created_at"
        case .updatedAt: value = "updated_at"
        case .lastMessageAt: value = "last_message_at"
        case .memberCount: value = "member_count"
        }
        
        try container.encode(value)
    }
}

extension ChannelListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<ChannelDTO, Date> = \ChannelDTO.defaultSortingAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()
    
    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        .init(key: rawValue, ascending: isAscending)
    }
}

// MARK: User List Sorting Key

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

// MARK: - Members Sorting

/// `ChannelMemberListSortingKey` describes the keys by which you can get sorted channel members after query.
public enum ChannelMemberListSortingKey: String, SortingKey {
    case createdAt
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value: String
        
        switch self {
        /// Sort channel members by date they were created.
        case .createdAt: value = "created_at"
        }
        
        try container.encode(value)
    }
}

extension ChannelMemberListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<MemberDTO, Date> = \MemberDTO.memberCreatedAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()
    
    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        .init(key: rawValue, ascending: isAscending)
    }
}
