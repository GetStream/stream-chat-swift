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
    case channel(ChannelQuery)
    case thread(Message, Pagination)
    case sendMessage(Message, Channel)
    case sendMessageAction(MessageAction)
    case deleteMessage(Message)
    case sendRead(Channel)
    case addReaction(_ reactionType: String, Message)
    case deleteReaction(_ reactionType: String, Message)
    case sendEvent(EventType, Channel)
}

extension ChatEndpoint {
    var method: Client.Method {
        switch self {
        case .channels, .thread:
            return .get
        case .deleteMessage, .deleteReaction:
            return .delete
        default:
            return .post
        }
    }
    
    var path: String {
        switch self {
        case .channels:
            return "channels"
        case .channel(let query):
            return path(with: query.channel).appending("query")
        case .thread(let message, _):
            return path(with: message).appending("replies")
        case .sendMessage(_, let channel):
            return path(with: channel).appending("message")
        case .sendMessageAction(let messageAction):
            return path(with: messageAction.message).appending("action")
        case .deleteMessage(let message):
            return path(with: message)
        case .sendRead(let channel):
            return path(with: channel).appending("read")
        case .addReaction(_, let message):
            return path(with: message).appending("reaction")
        case .deleteReaction(let reactionType, let message):
            return path(with: message).appending("reaction/\(reactionType)")
        case .sendEvent(_, let channel):
            return path(with: channel).appending("event")
        }
    }
    
    var queryItem: Encodable? {
        if case .thread(_, let pagination) = self {
            return pagination
        }
        
        return nil
    }
    
    var queryItems: [String: Encodable]? {
        if case .channels(let query) = self {
            return ["payload": query]
        }
        
        return nil
    }
    
    var body: Encodable? {
        switch self {
        case .channels,
             .thread,
             .deleteMessage,
             .deleteReaction:
            return nil
        case .channel(let query):
            return query
        case .sendMessage(let message, _):
            return ["message": message]
        case .sendMessageAction(let messageAction):
            return messageAction
        case .addReaction(let reactionType, _):
            return ["reaction": ["type": reactionType]]
        case .sendEvent(let event, _):
            return ["event": ["type": event]]
        case .sendRead:
            return Empty()
        }
    }
    
    private func path(with channel: Channel) -> String {
        return "channels/\(channel.type.rawValue)/\(channel.id)/"
    }
    
    private func path(with message: Message) -> String {
        return "messages/\(message.id)/"
    }
}

private struct Empty: Encodable {}
