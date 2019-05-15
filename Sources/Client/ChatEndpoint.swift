//
//  ChatEndpoint.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

enum ChatEndpoint: EndpointProtocol {
    case channels(ChannelsQuery)
    case query(Query)
    case sendMessage(Message, Channel)
    case sendMessageAction(MessageAction)
    case addReaction(_ reactionType: String, Message)
    case deleteReaction(_ reactionType: String, Message)
    case sendEvent(EventType, Channel)
}

extension ChatEndpoint {
    var method: Client.Method {
        if case .channels = self {
            return .get
        }
        
        if case .deleteReaction = self {
            return .delete
        }
        
        return .post
    }
    
    var path: String {
        switch self {
        case .channels:
            return "channels"
        case .query(let query):
            return path(with: query.channel).appending("query")
        case .sendMessage(_, let channel):
            return path(with: channel).appending("message")
        case .sendMessageAction(let messageAction):
            return path(with: messageAction.message).appending("action")
        case .addReaction(_, let message):
            return path(with: message).appending("reaction")
        case .deleteReaction(let reactionType, let message):
            return path(with: message).appending("reaction/\(reactionType)")
        case .sendEvent(_, let channel):
            return path(with: channel).appending("event")
        }
    }
    
    var queryItems: [String: Encodable]? {
        if case .channels(let query) = self {
            return ["payload": query]
        }
        
        return nil
    }
    
    var body: Encodable? {
        switch self {
        case .channels:
            return nil
        case .query(let query):
            return query
        case .sendMessage(let message, _):
            return ["message": message]
        case .sendMessageAction(let messageAction):
            return messageAction
        case .addReaction(let reactionType, _):
            return ["reaction": ["type": reactionType]]
        case .deleteReaction:
            return nil
        case .sendEvent(let event, _):
            return ["event": ["type": event]]
        }
    }
    
    private func path(with channel: Channel) -> String {
        return "channels/\(channel.type.rawValue)/\(channel.id)/"
    }
    
    private func path(with message: Message) -> String {
        return "messages/\(message.id)/"
    }
}

struct ChannelsQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case user = "user_details"
        case state
        case watch
        case presence
        case offset
    }
    
    let filter: Filter
    let sort: [Sorting]
    let user: User
    let state = true
    let watch = true
    let presence = false
    let offset = 0
}

extension ChannelsQuery {
    struct Filter: Encodable {
        let type: ChannelType
    }
    
    enum Sorting: Encodable {
        private enum CodingKeys: String, CodingKey {
            case field
            case direction
        }
        
        case lastMessage(isAscending: Bool)
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .lastMessage(let isAscending):
                try container.encode("last_message_at", forKey: .field)
                try container.encode(isAscending ? 1 : -1, forKey: .direction)
            }
        }
    }
}
