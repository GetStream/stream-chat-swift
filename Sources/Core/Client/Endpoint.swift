//
//  Endpoint.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// Chat endpoints.
public enum Endpoint {
    // MARK: - Client Endpoints
    
    /// Get a guest token.
    case guestToken(User)
    
    // MARK: - Device Endpoints
    
    /// Add a device with a given identifier for Push Notifications.
    case addDevice(deviceId: String, User)
    /// Get a list of devices.
    case devices(User)
    /// Remove a device with a given identifier.
    case removeDevice(deviceId: String, User)
    
    // MARK: - Channels Endpoints
    
    /// Get a list of channels.
    case channels(ChannelsQuery)
    
    // MARK: - Channel Endpoints
    
    /// Get a channel data.
    case channel(ChannelQuery)
    /// Stop watching a channel.
    case stopWatching(Channel)
    /// Delete a channel.
    case deleteChannel(Channel)
    /// Hide a channel.
    case hideChannel(Channel, User?)
    /// Show a channel if it was hidden.
    case showChannel(Channel, User?)
    /// Send a message to a channel.
    case sendMessage(Message, Channel)
    /// Upload an image to a channel.
    case sendImage(_ fileName: String, _ mimeType: String, Data, Channel)
    /// Upload a file to a channel.
    case sendFile(_ fileName: String, _ mimeType: String, Data, Channel)
    // Delete an uploaded image.
    case deleteImage(URL, Channel)
    // Delete an uploaded file.
    case deleteFile(URL, Channel)
    /// Send a read event.
    case markRead(Channel)
    /// Send an event to a channel.
    case sendEvent(EventType, Channel)
    /// Send a message action.
    case sendMessageAction(MessageAction)
    /// Send an answer for an invite.
    case inviteAnswer(ChannelInviteAnswer)

    // MARK: - Message Endpoints
    
    /// Get a thread data.
    case replies(Message, Pagination)
    /// Delete a message.
    case deleteMessage(Message)
    /// Add a reaction to the message.
    case addReaction(ReactionType, Message)
    /// Delete a reaction from the message.
    case deleteReaction(ReactionType, Message)
    /// Flag a message.
    case flagMessage(Message)
    /// Unflag a message.
    case unflagMessage(Message)
    
    // MARK: - User Endpoints
    
    /// Get a list of users.
    case users(UsersQuery)
    /// Update a user.
    case updateUsers([User])
    /// Mute a use.
    case muteUser(User)
    /// Unmute a user.
    case unmuteUser(User)
}

extension Endpoint {
    var method: Client.Method {
        switch self {
        case .channels, .replies, .users, .devices:
            return .get
        case .removeDevice, .deleteChannel, .deleteMessage, .deleteReaction, .deleteImage, .deleteFile:
            return .delete
        default:
            return .post
        }
    }
    
    var path: String {
        switch self {
        case .guestToken:
            return "guest"
        case .addDevice,
             .devices,
             .removeDevice:
            return "devices"
        case .channels:
            return "channels"
        case .channel(let query):
            return path(to: query.channel, "query")
        case .stopWatching(let channel):
            return path(to: channel, "stop-watching")
        case .deleteChannel(let channel):
            return path(to: channel)
        case .showChannel(let channel, _):
            return path(to: channel, "show")
        case .hideChannel(let channel, _):
            return path(to: channel, "hide")
        case .replies(let message, _):
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
        case .markRead(let channel):
            return path(to: channel, "read")
        case .addReaction(_, let message):
            return path(to: message, "reaction")
        case .deleteReaction(let reactionType, let message):
            return path(to: message, "reaction/\(reactionType.rawValue)")
        case .sendEvent(_, let channel):
            return path(to: channel, "event")
        case .sendImage(_, _, _, let channel):
            return path(to: channel, "image")
        case .sendFile(_, _, _, let channel):
            return path(to: channel, "file")
        case .deleteImage(_, let channel):
            return path(to: channel, "image")
        case .deleteFile(_, let channel):
            return path(to: channel, "file")
        case .users, .updateUsers:
            return "users"
        case .muteUser:
            return "moderation/mute"
        case .unmuteUser:
            return "moderation/unmute"
        case .flagMessage:
            return "moderation/flag"
        case .unflagMessage:
            return "moderation/unflag"
        case .inviteAnswer(let answer):
            return path(to: answer.channel)
        }
    }
    
    var queryItem: Encodable? {
        switch self {
        case .removeDevice(deviceId: let deviceId, let user):
            return ["id": deviceId, "user_id": user.id]
        case .replies(_, let pagination):
            return pagination
        case .deleteImage(let url, _), .deleteFile(let url, _):
            return ["url": url]
        default:
            return nil
        }
    }
    
    var jsonQueryItems: [String: Encodable]? {
        let payload: Encodable
        
        switch self {
        case .channels(let query):
            payload = query
        case .users(let query):
            payload = query
        default:
            return nil
        }
        
        return ["payload": payload]
    }
    
    var body: Encodable? {
        switch self {
        case .removeDevice,
             .channels,
             .deleteChannel,
             .replies,
             .deleteMessage,
             .deleteReaction,
             .sendImage,
             .sendFile,
             .deleteImage,
             .deleteFile,
             .users:
            return nil
            
        case .stopWatching,
             .markRead:
            return EmptyData()
            
        case .guestToken(let user):
            return ["user": user]
            
        case .addDevice(deviceId: let deviceId, let user):
            return ["id": deviceId, "push_provider": "apn", "user_id": user.id]
            
        case .devices(let user):
            return ["user_id": user.id]
            
        case .channel(let query):
            return query
            
        case .showChannel(_, let user),
             .hideChannel(_, let user):
            if let user = user {
                return ["user_id": user.id]
            }
            
            return nil
            
        case .sendMessage(let message, _):
            return ["message": message]
            
        case .sendMessageAction(let messageAction):
            return messageAction
            
        case .addReaction(let reactionType, _):
            return ["reaction": ["type": reactionType.rawValue]]
            
        case .sendEvent(let event, _):
            return ["event": ["type": event]]
            
        case .updateUsers(let users):
            let usersById: [String: User] = users.reduce([:]) { usersById, user in
                var usersById = usersById
                usersById[user.id] = user
                return usersById
            }
            
            return ["users": usersById]
            
        case .muteUser(let user), .unmuteUser(let user):
            return ["target_id": user.id]
            
        case .flagMessage(let message), .unflagMessage(let message):
            return ["target_message_id": message.id]
            
        case .inviteAnswer(let answer):
            return answer
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
        return "channels/\(channel.type.rawValue)\(channel.id.isEmpty ? "" : "/\(channel.id)")\(subPath == nil ? "" : "/\(subPath ?? "")")"
    }
    
    private func path(to message: Message, _ subPath: String? = nil) -> String {
        return "messages/\(message.id)\(subPath == nil ? "" : "/\(subPath ?? "")")"
    }
}
