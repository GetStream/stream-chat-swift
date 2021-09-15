//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChannelListSortingKey` is keys by which you can get sorted channels after query.
public enum ChannelListSortingKey: String, SortingKey {
    /// Sort channels by date they were created.
    case createdAt = "created_at"
    /// Sort channels by date they were updated.
    case updatedAt = "updated_at"
    /// Sort channels by the last message date..
    case lastMessageAt = "last_message_at"
    /// Sort channels by number of members.
    case memberCount = "member_count"
    /// Sort channels by `cid`.
    /// **Note**: This sorting option can extend your response waiting time if used as primary one.
    case cid
}

extension ChannelListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<ChannelDTO, Date> = \ChannelDTO.defaultSortingAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()
    
    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor {
        .init(key: sortDescriptorKey, ascending: isAscending)
    }
    
    var sortDescriptorKey: String {
        switch self {
        case .updatedAt: return "updatedAt"
        case .createdAt: return "createdAt"
        case .memberCount: return "memberCount"
        case .lastMessageAt: return "lastMessageAt"
        case .cid: return "cid"
        }
    }
}

/// In case elements have same or `nil` target sorting values it's not possible to guarantee that order of elements will be the same
/// all the time. So we need to additionally provide safe sorting option.
extension Array where Element == Sorting<ChannelListSortingKey> {
    func appendingCidSortingKey() -> [Sorting<ChannelListSortingKey>] {
        guard !contains(where: { $0.key == .cid }), !isEmpty else {
            return self
        }
        
        return self + [.init(key: .cid)]
    }
}
