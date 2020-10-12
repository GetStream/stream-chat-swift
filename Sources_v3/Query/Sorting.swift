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
public enum UserListSortingKey: SortingKey {
    case createdAt
    case updatedAt
    case lastActiveAt
    case custom(String)
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value: String
        
        switch self {
        case .createdAt: value = "created_at"
        case .updatedAt: value = "updated_at"
        case .lastActiveAt: value = "lastActiveAt"
        case let .custom(string): value = string
        }
        
        try container.encode(value)
    }
}

extension UserListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<UserDTO, Date> = \UserDTO.userUpdatedAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()
    
    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        var dateKeyPath: KeyPath<UserDTO, Date>?
        var optionalDateKeyPath: KeyPath<UserDTO, Date?>?
        
        switch self {
        case .createdAt: dateKeyPath = \UserDTO.userCreatedAt
        case .updatedAt: dateKeyPath = \UserDTO.userUpdatedAt
        case .lastActiveAt: optionalDateKeyPath = \UserDTO.lastActivityAt
        case .custom: break
        }
        
        if let keyPath = dateKeyPath {
            return .init(keyPath: keyPath, ascending: isAscending)
        }
        
        if let keyPath = optionalDateKeyPath {
            return .init(keyPath: keyPath, ascending: isAscending)
        }
        
        return nil
    }
}

// MARK: - Members Sorting

/// `ChannelMemberListSortingKey` describes the keys by which you can get sorted channel members after query.
public struct ChannelMemberListSortingKey: RawRepresentable, Equatable, SortingKey {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension ChannelMemberListSortingKey {
    /// When used this key sorts the member list by member's `createdAt` field.
    static let createdAt = Self(rawValue: "created_at")
    
    /// When used this key sorts the member list by member's `updatedAt` field.
    static let updatedAt = Self(rawValue: "updated_at")
}

extension ChannelMemberListSortingKey {
    static var defaultSortDescriptor: NSSortDescriptor {
        .init(keyPath: \MemberDTO.memberUpdatedAt, ascending: false)
    }
    
    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        var keyPath: KeyPath<MemberDTO, Date>? {
            switch self {
            case .createdAt:
                return \.memberCreatedAt
            case .updatedAt:
                return \.memberUpdatedAt
            default:
                return nil
            }
        }
        
        return keyPath.flatMap {
            .init(keyPath: $0, ascending: isAscending)
        }
    }
}
