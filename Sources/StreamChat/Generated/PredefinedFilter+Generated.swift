// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// Run `make generate` after changing channel-list FilterKey or ChannelListSortingKey members.

import Foundation

extension ChannelListFilterScope {
    /// Enrichment closures keyed by server-side `rawValue`; each re-attaches a `FilterKey`'s local
    /// wiring (key path, value/predicate mappers) to a decoded predefined-filter leaf. Stored as
    /// closures because the keys differ in their generic `Value` type.
    static let predefinedFilterKeyMapping: [String: @Sendable (Filter<ChannelListFilterScope>) -> Filter<ChannelListFilterScope>] = {
        func map<Value: FilterValue>(_ key: FilterKey<ChannelListFilterScope, Value>) -> (String, @Sendable (Filter<ChannelListFilterScope>) -> Filter<ChannelListFilterScope>) {
            (
                key.rawValue,
                { filter in
                    Filter(
                        operator: filter.operator,
                        key: filter.key,
                        value: filter.value,
                        valueMapper: key.valueMapper,
                        keyPathString: key.keyPathString,
                        isCollectionFilter: key.isCollectionFilter,
                        predicateMapper: key.predicateMapper
                    )
                }
            )
        }
        return Dictionary(uniqueKeysWithValues: [
            map(.archived),
            map(.blocked),
            map(.channelRole),
            map(.cid),
            map(.createdAt),
            map(.createdBy),
            map(.deletedAt),
            map(.disabled),
            map(.filterTags),
            map(.frozen),
            map(.hasUnread),
            map(.hidden),
            map(.id),
            map(.imageURL),
            map(.invite),
            map(.joined),
            map(.lastMessageAt),
            map(.lastUpdatedAt),
            map(.memberCount),
            map(.memberName),
            map(.members),
            map(.muted),
            map(.name),
            map(.pinned),
            map(.team),
            map(.type),
            map(.updatedAt),
        ])
    }()
}

extension ChannelListSortingKey {
    static let predefinedSortingKeyMapping: [String: Self] = {
        func map(_ key: Self) -> (String, Self) { (key.remoteKey, key) }
        return Dictionary(uniqueKeysWithValues: [
            map(.default),
            map(.cid),
            map(.createdAt),
            map(.hasUnread),
            map(.lastMessageAt),
            map(.memberCount),
            map(.pinnedAt),
            map(.unreadCount),
            map(.updatedAt),
        ])
    }()
}
