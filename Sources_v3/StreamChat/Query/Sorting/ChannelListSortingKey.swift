//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

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
