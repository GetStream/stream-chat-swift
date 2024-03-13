//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelGetOrCreateRequest: Codable, Hashable {
    public var clientId: String? = nil
    public var connectionId: String? = nil
    public var hideForCreator: Bool? = nil
    public var presence: Bool? = nil
    public var state: Bool? = nil
    public var threadUnreadCounts: Bool? = nil
    public var watch: Bool? = nil
    public var data: ChannelRequest? = nil
    public var members: PaginationParamsRequest? = nil
    public var messages: MessagePaginationParamsRequest? = nil
    public var watchers: PaginationParamsRequest? = nil

    public init(clientId: String? = nil, connectionId: String? = nil, hideForCreator: Bool? = nil, presence: Bool? = nil, state: Bool? = nil, threadUnreadCounts: Bool? = nil, watch: Bool? = nil, data: ChannelRequest? = nil, members: PaginationParamsRequest? = nil, messages: MessagePaginationParamsRequest? = nil, watchers: PaginationParamsRequest? = nil) {
        self.clientId = clientId
        self.connectionId = connectionId
        self.hideForCreator = hideForCreator
        self.presence = presence
        self.state = state
        self.threadUnreadCounts = threadUnreadCounts
        self.watch = watch
        self.data = data
        self.members = members
        self.messages = messages
        self.watchers = watchers
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case clientId = "client_id"
        case connectionId = "connection_id"
        case hideForCreator = "hide_for_creator"
        case presence
        case state
        case threadUnreadCounts = "thread_unread_counts"
        case watch
        case data
        case members
        case messages
        case watchers
    }
}
