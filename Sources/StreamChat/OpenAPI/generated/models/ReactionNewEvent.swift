//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ReactionNewEvent: Codable, Hashable, Event {
    public var channelId: String
    public var channelType: String
    public var cid: String
    public var createdAt: Date
    public var type: String
    public var team: String? = nil
    public var threadParticipants: [UserObject]? = nil
    public var message: Message? = nil
    public var reaction: Reaction? = nil
    public var user: UserObject? = nil

    public init(channelId: String, channelType: String, cid: String, createdAt: Date, type: String, team: String? = nil, threadParticipants: [UserObject]? = nil, message: Message? = nil, reaction: Reaction? = nil, user: UserObject? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.type = type
        self.team = team
        self.threadParticipants = threadParticipants
        self.message = message
        self.reaction = reaction
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case type
        case team
        case threadParticipants = "thread_participants"
        case message
        case reaction
        case user
    }
}

extension ReactionNewEvent: EventContainsCreationDate {}
extension ReactionNewEvent: EventContainsMessage {}
extension ReactionNewEvent: EventContainsUser {}
