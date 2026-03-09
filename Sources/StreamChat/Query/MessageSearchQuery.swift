//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Keys that you can use to sort Message search results.
public enum MessageSearchSortingKey: String, SortingKey {
    /// Sort messages by their relevance to the query.
    /// - Warning: This sorting key will not take effect on iOS SDK. We suggest using other sorting keys for now.
    case relevance

    /// Sort messages by their `id`.
    case id

    /// Sort messages by their `created_at` dates.
    case createdAt

    /// Sort messages by their `updated_at` dates.
    case updatedAt

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value: String

        switch self {
        case .createdAt: value = "created_at"
        case .updatedAt: value = "updated_at"
        case .relevance: value = "relevance"
        case .id: value = "id"
        }

        try container.encode(value)
    }

    private var canUseAsSortDescriptor: Bool {
        switch self {
        case .relevance: return false
        case .id: return true
        case .createdAt: return true
        case .updatedAt: return true
        }
    }

    /// Default sort descriptor for Message search. Corresponds to `created_at`
    static var defaultSortDescriptor: NSSortDescriptor {
        NSSortDescriptor(keyPath: \MessageDTO.defaultSortingKey, ascending: true)
    }

    func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
        canUseAsSortDescriptor ? .init(key: rawValue, ascending: isAscending) : nil
    }
}

public protocol AnyMessageSearchFilterScope {}

public struct MessageSearchFilterScope: FilterScope, AnyMessageSearchFilterScope {}

public extension FilterKey where Scope == MessageSearchFilterScope {
    static var text: FilterKey<Scope, String> { "text" }
    static var authorId: FilterKey<Scope, UserId> { "user.id" }
    static var hasAttachmentsOfType: FilterKey<Scope, AttachmentType> { "attachments.type" }
}

public extension Filter where Scope == MessageSearchFilterScope {
    static func queryText(_ text: String) -> Filter<Scope> {
        .query(.text, text: text)
    }

    // Filter messages with the given attachment types.
    static func withAttachments(_ types: Set<AttachmentType>) -> Filter<Scope> {
        .in(.hasAttachmentsOfType, values: .init(types))
    }

    // Filter messages which contain attachments.
    static var withAttachments: Filter<Scope> {
        .exists(FilterKey<Scope, String>(stringLiteral: "attachments"))
    }

    // Filter messages that don't contain attachments.
    static var withoutAttachments: Filter<Scope> {
        .exists(FilterKey<Scope, String>(stringLiteral: "attachments"), exists: false)
    }
}

public struct MessageSearchQuery: Encodable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case query
        case channelFilter = "filter_conditions"
        case messageFilter = "message_filter_conditions"
        case sort
    }

    public let channelFilter: Filter<ChannelListFilterScope>

    public let messageFilter: Filter<MessageSearchFilterScope>

    public let sort: [Sorting<MessageSearchSortingKey>]

    public var pagination: Pagination?

    var filterHash: String

    public init(
        channelFilter: Filter<ChannelListFilterScope>,
        messageFilter: Filter<MessageSearchFilterScope>,
        sort: [Sorting<MessageSearchSortingKey>] = [.init(key: .createdAt, isAscending: false)],
        pageSize: Int = .messagesPageSize
    ) {
        self.channelFilter = channelFilter
        self.messageFilter = messageFilter
        self.sort = sort
        pagination = Pagination(pageSize: pageSize)
        filterHash = messageFilter.filterHash + channelFilter.filterHash
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(messageFilter, forKey: .messageFilter)

        try container.encodeIfPresent(channelFilter, forKey: .channelFilter)

        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }

        try pagination.map { try $0.encode(to: encoder) }
    }
}

// MARK: - Channel list sort mapping

extension MessageSearchQuery {
    /// Converts channel list sort order to message search sort order so that message search
    /// can respect the same ordering as the channel list (e.g. when searching from the channel list UI).
    ///
    /// Mapped keys: `last_updated` / `last_message_at` → `createdAt`; `created_at` → `createdAt`; `updated_at` → `updatedAt`.
    /// Iterates over the channel list sort to find the first mappable key; if none is found, returns `createdAt` descending.
    public static func messageSearchSort(fromChannelListSort channelListSort: [Sorting<ChannelListSortingKey>]) -> [Sorting<MessageSearchSortingKey>] {
        let mappableRemoteKeys: Set<String> = ["last_updated", "last_message_at", "created_at", "updated_at"]
        guard let entry = channelListSort.first(where: { mappableRemoteKeys.contains($0.key.remoteKey) }) else {
            return [.init(key: .createdAt, isAscending: false)]
        }
        let messageKey: MessageSearchSortingKey = entry.key.remoteKey == "updated_at" ? .updatedAt : .createdAt
        return [.init(key: messageKey, isAscending: entry.isAscending)]
    }
}
