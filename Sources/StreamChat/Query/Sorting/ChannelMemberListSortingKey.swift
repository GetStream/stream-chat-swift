//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChannelMemberListSortingKey` describes the keys by which you can get sorted channel members after query.
public enum ChannelMemberListSortingKey: String, SortingKey {
    case createdAt = "memberCreatedAt"
    
    /// Sort channel members by name.
    ///
    /// - Warning: This option is heavy for the backend and can slow down API requests' response time. If there's no explicit requirement for this sorting option consider using a different one.
    case name = "user.name"
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value: String
        
        switch self {
        /// Sort channel members by date they were created.
        case .createdAt: value = "created_at"
        case .name: value = "name"
        }
        
        try container.encode(value)
    }
}

extension ChannelMemberListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<MemberDTO, Date> = \MemberDTO.memberCreatedAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()
    
    static let lastActiveSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<MemberDTO, Date?> = \MemberDTO.user.lastActivityAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()
    
    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor {
        .init(key: rawValue, ascending: isAscending)
    }
}
