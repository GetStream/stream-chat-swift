//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageDeletedEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var hardDelete: Bool
    public var type: String
    public var team: String? = nil
    public var threadParticipants: [UserObject]? = nil
    public var message: Message? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, hardDelete: Bool, type: String, team: String? = nil, threadParticipants: [UserObject]? = nil, message: Message? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.hardDelete = hardDelete
        self.type = type
        self.team = team
        self.threadParticipants = threadParticipants
        self.message = message
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case hardDelete = "hard_delete"
        case type
        case team
        case threadParticipants = "thread_participants"
        case message
        case user
    }
}

extension MessageDeletedEvent: EventContainsCreationDate {}
extension MessageDeletedEvent: EventContainsOptionalMessage {}
extension MessageDeletedEvent: EventContainsUser {}
