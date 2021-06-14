//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChannelMemberListSortingKey` describes the keys by which you can get sorted channel members after query.
public enum ChannelMemberListSortingKey: String, SortingKey {
    case createdAt = "memberCreatedAt"
    
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
    
    static let lastActiveSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<MemberDTO, Date?> = \MemberDTO.user.lastActivityAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()
    
    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor {
        .init(key: rawValue, ascending: isAscending)
    }
}
