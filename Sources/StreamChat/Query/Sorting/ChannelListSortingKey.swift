//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    /// Sort channels by `cid`.
    /// **Note**: This sorting option can extend your response waiting time if used as primary one.
    case cid
    /// Sort channels by unread state. When using this sorting key, every unread channel weighs the same,
    /// so they're sorted by `updatedAt`
    case hasUnread
    /// Sort channels by their unread count.
    case unreadCount
    
    private var canUseAsSortDescriptor: Bool {
        switch self {
        case .createdAt: return true
        case .updatedAt: return true
        case .lastMessageAt: return true
        case .memberCount: return true
        case .cid: return true
        case .hasUnread: return false
        case .unreadCount: return false
        case .default: return true
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value: String
        
        switch self {
        case .default: value = "updated_at"
        case .createdAt: value = "created_at"
        case .updatedAt: value = "updated_at"
        case .lastMessageAt: value = "last_message_at"
        case .memberCount: value = "member_count"
        case .cid: value = "cid"
        case .hasUnread: value = "has_unread"
        case .unreadCount: value = "unread_count"
        }
        
        try container.encode(value)
    }
}

extension ChannelListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<ChannelDTO, DBDate> = \ChannelDTO.defaultSortingAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()
    
    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        canUseAsSortDescriptor ? .init(key: rawValue, ascending: isAscending) : nil
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
