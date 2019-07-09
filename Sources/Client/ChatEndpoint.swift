//
//  ChatEndpoint.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

enum ChatEndpoint {
    case guestToken(User)
    case channels(ChannelsQuery)
    case channel(ChannelQuery)
    case createChannel(Channel)
    case thread(Message, Pagination)
    case sendMessage(Message, Channel)
    case sendMessageAction(MessageAction)
    case deleteMessage(Message)
    case sendRead(Channel)
    case addReaction(_ reactionType: String, Message)
    case deleteReaction(_ reactionType: String, Message)
    case sendEvent(EventType, Channel)
    case sendImage(_ fileName: String, _ mimeType: String, Data, Channel)
    case sendFile(_ fileName: String, _ mimeType: String, Data, Channel)
}

extension ChatEndpoint {
    var method: Client.Method {
        switch self {
        case .channels,
             .thread:
            return .get
        case .deleteMessage,
             .deleteReaction:
            return .delete
        default:
            return .post
        }
    }
    
    var path: String {
        switch self {
        case .guestToken:
            return "guest"
        case .channels:
            return "channels"
        case .channel(let query):
            return path(to: query.channel, "query")
        case .createChannel(let channel):
            return path(to: channel)
        case .thread(let message, _):
            return path(to: message, "replies")
            
        case let .sendMessage(message, channel):
            if message.id.isEmpty {
                return path(to: channel, "message")
            }
            
            return path(to: message)
            
        case .sendMessageAction(let messageAction):
            return path(to: messageAction.message, "action")
        case .deleteMessage(let message):
            return path(to: message)
        case .sendRead(let channel):
            return path(to: channel, "read")
        case .addReaction(_, let message):
            return path(to: message, "reaction")
        case .deleteReaction(let reactionType, let message):
            return path(to: message, "reaction/\(reactionType)")
        case .sendEvent(_, let channel):
            return path(to: channel, "event")
        case .sendImage(_, _, _, let channel):
            return path(to: channel, "image")
        case .sendFile(_, _, _, let channel):
            return path(to: channel, "file")
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
             .deleteReaction,
             .sendImage,
             .sendFile:
            return nil
        case .guestToken(let user):
            return ["user": user]
        case .channel(let query):
            return query
        case .createChannel(let channel):
            return channel
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
    
    var isUploading: Bool {
        switch self {
        case .sendImage,
             .sendFile:
            return true
        default:
            return false
        }
    }
    
    private func path(to channel: Channel, _ subPath: String? = nil) -> String {
        return "channels/\(channel.type.rawValue)/\(channel.id)\(subPath == nil ? "" : "/\(subPath ?? "")")"
    }
    
    private func path(to message: Message, _ subPath: String? = nil) -> String {
        return "messages/\(message.id)\(subPath == nil ? "" : "/\(subPath ?? "")")"
    }
}
