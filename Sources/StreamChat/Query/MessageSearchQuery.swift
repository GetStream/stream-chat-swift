//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public enum MessageSearchSortingKey: String, SortingKey {
    case relevance
    case id
}

public protocol AnyMessageSearchFilterScope {}

public struct MessageSearchFilterScope: FilterScope, AnyMessageSearchFilterScope {}

public extension FilterKey where Scope: AnyMessageSearchFilterScope {
    static var text: FilterKey<Scope, String> { "text" }
    static var authorId: FilterKey<Scope, UserId> { "user.id" }
}

public extension Filter where Scope: AnyMessageSearchFilterScope {
    static func queryText(_ text: String) -> Filter<Scope> {
        .query(.text, text: text)
    }
}

public struct MessageSearchQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case query
        case channelFilter = "filter_conditions"
        case messageFilter = "message_filter_conditions"
        case sort
    }
    
    public let channelFilter: Filter<ChannelListFilterScope>?
    
    public let messageFilter: Filter<MessageSearchFilterScope>
    
    public let sort: [Sorting<MessageSearchSortingKey>]
    
    public var pagination: Pagination?
    
    var filterHash: String
    
    public init(
        channelFilter: Filter<ChannelListFilterScope>? = nil,
        messageFilter: Filter<MessageSearchFilterScope>,
        sort: [Sorting<MessageSearchSortingKey>] = [],
        pageSize: Int = .messagesPageSize
    ) {
        self.channelFilter = channelFilter
        self.messageFilter = messageFilter
        self.sort = sort
        pagination = Pagination(pageSize: pageSize)
        filterHash = messageFilter.filterHash + (channelFilter?.filterHash ?? "")
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
