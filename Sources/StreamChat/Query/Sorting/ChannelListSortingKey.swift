//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChannelListSortingKey` is keys by which you can get sorted channels after query.
public struct ChannelListSortingKey: SortingKey, Equatable {
    /// The default sorting is by the last massage date or a channel created date. The same as by `updatedDate`.
    public static let `default` = Self(keyPath: \.defaultSortingAt, localKey: "defaultSortingAt", remoteKey: "updated_at", canUseAsDBSortDescriptor: true)
    /// Sort channels by date they were created.
    public static let createdAt = Self(keyPath: \.createdAt, remoteKey: "created_at", canUseAsDBSortDescriptor: true)
    /// Sort channels by date they were updated.
    public static let updatedAt = Self(keyPath: \.updatedAt, remoteKey: "updated_at", canUseAsDBSortDescriptor: true)
    /// Sort channels by the last message date..
    public static let lastMessageAt = Self(keyPath: \.lastMessageAt, remoteKey: "last_message_at", canUseAsDBSortDescriptor: true)
    /// Sort channels by number of members.
    public static let memberCount = Self(keyPath: \.memberCount, remoteKey: "member_count", canUseAsDBSortDescriptor: true)
    /// Sort channels by `cid`.
    /// **Note**: This sorting option can extend your response waiting time if used as primary one.
    public static let cid = Self(keyPath: \.cid, remoteKey: "cid", canUseAsDBSortDescriptor: true)
    /// Sort channels by unread state. When using this sorting key, every unread channel weighs the same,
    /// so they're sorted by `updatedAt`
    public static let hasUnread = Self(keyPath: \.hasUnread, remoteKey: "has_unread", canUseAsDBSortDescriptor: false)
    /// Sort channels by their unread count.
    public static let unreadCount = Self(keyPath: \.unreadCount, remoteKey: "unread_count", canUseAsDBSortDescriptor: false)

    public static func custom<T>(keyPath: KeyPath<ChatChannel, T>, key: String) -> Self {
        .init(keyPath: keyPath, remoteKey: key, canUseAsDBSortDescriptor: false, isCustom: true)
    }

    let keyPath: PartialKeyPath<ChatChannel>
    let localKey: String
    let remoteKey: String
    let canUseAsDBSortDescriptor: Bool
    let isCustom: Bool

    init<T>(keyPath: KeyPath<ChatChannel, T>, localKey: String? = nil, remoteKey: String, canUseAsDBSortDescriptor: Bool, isCustom: Bool = false) {
        self.keyPath = keyPath
        self.localKey = localKey ?? keyPath.stringValue
        self.remoteKey = remoteKey
        self.canUseAsDBSortDescriptor = canUseAsDBSortDescriptor
        self.isCustom = isCustom
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(remoteKey)
    }
}

extension ChannelListSortingKey {
    static let defaultSortDescriptor: NSSortDescriptor = {
        let dateKeyPath: KeyPath<ChannelDTO, DBDate> = \ChannelDTO.defaultSortingAt
        return .init(keyPath: dateKeyPath, ascending: false)
    }()

    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        canUseAsDBSortDescriptor ? .init(key: localKey, ascending: isAscending) : nil
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

    var customSorting: [SortValue<ChatChannel>] {
        var hasCustom = false
        let sortValues = compactMap {
            if $0.key.isCustom {
                hasCustom = true
            }
            return $0.sortValue
        }

        return hasCustom ? sortValues : []
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
