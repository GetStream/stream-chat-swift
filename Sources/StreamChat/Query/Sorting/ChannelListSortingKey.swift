//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChannelListSortingKey` is keys by which you can get sorted channels after query.
public struct ChannelListSortingKey: SortingKey, Equatable {
    /// The default sorting is by the last massage date or a channel created date. The same as by `updatedDate`.
    public static let `default` = Self(
        keyPath: \.defaultSortingAt,
        localKey: #keyPath(ChannelDTO.defaultSortingAt),
        remoteKey: ChannelCodingKeys.updatedAt.rawValue
    )

    /// Sort channels by date they were created.
    public static let createdAt = Self(
        keyPath: \.createdAt,
        localKey: #keyPath(ChannelDTO.createdAt),
        remoteKey: ChannelCodingKeys.createdAt.rawValue
    )

    /// Sort channels by date they were updated.
    public static let updatedAt = Self(
        keyPath: \.updatedAt,
        localKey: #keyPath(ChannelDTO.updatedAt),
        remoteKey: ChannelCodingKeys.updatedAt.rawValue
    )

    /// Sort channels by the last message date..
    public static let lastMessageAt = Self(
        keyPath: \.lastMessageAt,
        localKey: #keyPath(ChannelDTO.lastMessageAt),
        remoteKey: ChannelCodingKeys.lastMessageAt.rawValue
    )

    /// Sort channels by number of members.
    public static let memberCount = Self(
        keyPath: \.memberCount,
        localKey: #keyPath(ChannelDTO.memberCount),
        remoteKey: ChannelCodingKeys.memberCount.rawValue
    )

    /// Sort channels by `cid`.
    /// **Note**: This sorting option can extend your response waiting time if used as primary one.
    public static let cid = Self(
        keyPath: \.cid,
        localKey: #keyPath(ChannelDTO.cid),
        remoteKey: ChannelCodingKeys.cid.rawValue
    )

    /// Sort channels by unread state. When using this sorting key, every unread channel weighs the same,
    /// so they're sorted by `updatedAt`
    public static let hasUnread = Self(
        keyPath: \.hasUnread,
        localKey: nil,
        remoteKey: "has_unread"
    )

    /// Sort channels by their unread count.
    public static let unreadCount = Self(
        keyPath: \.unreadCount,
        localKey: nil,
        remoteKey: "unread_count"
    )

    public static func custom<T>(keyPath: KeyPath<ChatChannel, T>, key: String) -> Self {
        .init(keyPath: keyPath, localKey: nil, remoteKey: key)
    }

    let keyPath: PartialKeyPath<ChatChannel>
    let localKey: String?
    let remoteKey: String
    var requiresRuntimeSorting: Bool {
        localKey == nil
    }

    init<T>(keyPath: KeyPath<ChatChannel, T>, localKey: String?, remoteKey: String) {
        self.keyPath = keyPath
        self.localKey = localKey
        self.remoteKey = remoteKey
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(remoteKey)
    }
}

extension ChannelListSortingKey: CustomDebugStringConvertible {
    public var debugDescription: String {
        remoteKey
    }
}

extension ChannelListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<ChannelDTO, DBDate> = \ChannelDTO.defaultSortingAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()

    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        guard let localKey = self.localKey else {
            return nil
        }
        return .init(key: localKey, ascending: isAscending)
    }
}

extension Array where Element == Sorting<ChannelListSortingKey> {
    var runtimeSorting: [SortValue<ChatChannel>] {
        var requiresRuntime = false
        let sortValues: [SortValue<ChatChannel>] = compactMap {
            if $0.key.requiresRuntimeSorting {
                requiresRuntime = true
            }
            return $0.sortValue
        }

        return requiresRuntime ? sortValues : []
    }
}

private extension Sorting where Key == ChannelListSortingKey {
    var sortValue: SortValue<ChatChannel>? {
        SortValue(keyPath: key.keyPath, isAscending: isAscending)
    }
}

extension ChatChannel {
    var defaultSortingAt: Date {
        lastMessageAt ?? createdAt
    }
}
