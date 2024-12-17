//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChannelMemberListSortingKey` describes the keys by which you can get sorted channel members after query.
public enum ChannelMemberListSortingKey: String, SortingKey {
    /// Sort channels by creation date.
    case createdAt = "memberCreatedAt"

    /// Sort channels by user id.
    case userId = "user.id"
    
    /// Sort channel members by name.
    ///
    /// - Warning: This option is heavy for the backend and can slow down API requests' response time. If there's no explicit requirement for this sorting option consider using a different one.
    case name = "user.name"
    
    /// Sort channel members by their role (`channel_role`).
    case role = "channelRoleRaw"

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value: String

        switch self {
        case .createdAt: value = "created_at"
        case .name: value = "name"
        case .role: value = "channel_role"
        case .userId: value = "user_id"
        }

        try container.encode(value)
    }
}

extension ChannelMemberListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<MemberDTO, DBDate> = \MemberDTO.memberCreatedAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()

    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor {
        .init(key: rawValue, ascending: isAscending)
    }
}
