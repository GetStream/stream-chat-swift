//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelGetOrCreateRequest: Codable, Hashable {
    public var connectionId: String? = nil
    public var hideForCreator: Bool? = nil
    public var presence: Bool? = nil
    public var state: Bool? = nil
    public var watch: Bool? = nil
    public var data: ChannelRequest? = nil
    public var members: PaginationParamsRequest? = nil
    public var messages: MessagePaginationParamsRequest? = nil
    public var watchers: PaginationParamsRequest? = nil

    public init(connectionId: String? = nil, hideForCreator: Bool? = nil, presence: Bool? = nil, state: Bool? = nil, watch: Bool? = nil, data: ChannelRequest? = nil, members: PaginationParamsRequest? = nil, messages: MessagePaginationParamsRequest? = nil, watchers: PaginationParamsRequest? = nil) {
        self.connectionId = connectionId
        self.hideForCreator = hideForCreator
        self.presence = presence
        self.state = state
        self.watch = watch
        self.data = data
        self.members = members
        self.messages = messages
        self.watchers = watchers
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case hideForCreator = "hide_for_creator"
        case presence
        case state
        case watch
        case data
        case members
        case messages
        case watchers
    }
}
