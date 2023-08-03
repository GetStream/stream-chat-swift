//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChannelListSortingKey` is keys by which you can get sorted channels after query.
public struct ChannelListSortingKey: SortingKey, Equatable {
    /// The default sorting is by the last massage date or a channel created date. The same as by `updatedDate`.
    public static let `default` = Self(keyPath: \.defaultSortingAt, localKey: "defaultSortingAt", remoteKey: "updated_at", requiresRuntimeSorting: false)
    /// Sort channels by date they were created.
    public static let createdAt = Self(keyPath: \.createdAt, remoteKey: "created_at", requiresRuntimeSorting: false)
    /// Sort channels by date they were updated.
    public static let updatedAt = Self(keyPath: \.updatedAt, remoteKey: "updated_at", requiresRuntimeSorting: false)
    /// Sort channels by the last message date..
    public static let lastMessageAt = Self(keyPath: \.lastMessageAt, remoteKey: "last_message_at", requiresRuntimeSorting: false)
    /// Sort channels by number of members.
    public static let memberCount = Self(keyPath: \.memberCount, remoteKey: "member_count", requiresRuntimeSorting: false)
    /// Sort channels by `cid`.
    /// **Note**: This sorting option can extend your response waiting time if used as primary one.
    public static let cid = Self(keyPath: \.cid, remoteKey: "cid", requiresRuntimeSorting: false)
    /// Sort channels by unread state. When using this sorting key, every unread channel weighs the same,
    /// so they're sorted by `updatedAt`
    public static let hasUnread = Self(keyPath: \.hasUnread, remoteKey: "has_unread", requiresRuntimeSorting: true)
    /// Sort channels by their unread count.
    public static let unreadCount = Self(keyPath: \.unreadCount, remoteKey: "unread_count", requiresRuntimeSorting: true)

    public static func custom<T>(keyPath: KeyPath<ChatChannel, T>, key: String) -> Self {
        .init(keyPath: keyPath, remoteKey: key, requiresRuntimeSorting: true)
    }

    let keyPath: PartialKeyPath<ChatChannel>
    let localKey: String
    let remoteKey: String
    let requiresRuntimeSorting: Bool

    init<T>(keyPath: KeyPath<ChatChannel, T>, localKey: String? = nil, remoteKey: String, requiresRuntimeSorting: Bool) {
        self.keyPath = keyPath
        self.localKey = localKey ?? keyPath.stringValue
        self.remoteKey = remoteKey
        self.requiresRuntimeSorting = requiresRuntimeSorting
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(remoteKey)
    }
}

extension ChannelListSortingKey: CustomDebugStringConvertible {
    public var debugDescription: String {
        localKey
    }
}

extension ChannelListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<ChannelDTO, DBDate> = \ChannelDTO.defaultSortingAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()

    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        requiresRuntimeSorting ? nil : .init(key: localKey, ascending: isAscending)
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

private extension KeyPath where Root == ChatChannel {
    var stringValue: String {
        let value = String(describing: self)
        let root = String(describing: Self.rootType)
        return value.replacingOccurrences(of: "\\\(root).", with: "")
    }
}

extension ChatChannel {
    var defaultSortingAt: Date {
        lastMessageAt ?? createdAt
    }
}
