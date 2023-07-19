//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// `ChannelListSortingKey` is keys by which you can get sorted channels after query.
public struct ChannelListSortingKey: SortingKey, Equatable {
    public typealias Object = ChatChannel

    /// The default sorting is by the last massage date or a channel created date. The same as by `updatedDate`.
    public static let `default` = Self.updatedAt
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
        .init(keyPath: keyPath, remoteKey: key, canUseAsDBSortDescriptor: false)
    }

    let keyPath: PartialKeyPath<ChatChannel>
    private let dbKey: String
    private let remoteKey: String
    private let canUseAsDBSortDescriptor: Bool

    init<T>(keyPath: KeyPath<ChatChannel, T>, remoteKey: String, canUseAsDBSortDescriptor: Bool) {
        self.keyPath = keyPath
        dbKey = keyPath.stringValue
        self.remoteKey = dbKey
        self.canUseAsDBSortDescriptor = canUseAsDBSortDescriptor
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
        canUseAsDBSortDescriptor ? .init(key: dbKey, ascending: isAscending) : nil
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

private extension KeyPath where Root == ChatChannel {
    var stringValue: String {
        NSExpression(forKeyPath: self).keyPath
    }
}

private extension ChatChannel {
    var hasUnread: Bool {
        unreadCount.messages > 0
    }
}
