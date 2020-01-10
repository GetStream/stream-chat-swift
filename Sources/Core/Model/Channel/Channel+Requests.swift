//
//  Channel+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Channel {
    
    /// Create a channel.
    /// - Returns: an observable channel response.
    func create(_ completion: @escaping ClientCompletion<ChannelResponse>) -> Subscription {
        return rx.create().bind(to: completion)
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc
    ///
    /// - Parameters:
    ///   - pagination: a pagination for messages (see `Pagination`).
    ///   - options: a query options. All by default (see `QueryOptions`).
    /// - Returns: an observable channel response.
    func query(pagination: Pagination = .none,
                      options: QueryOptions = [],
                      _ completion: @escaping ClientCompletion<ChannelResponse>) -> Subscription {
        return rx.query(pagination: pagination, options: options).bind(to: completion)
    }
    
    /// Loads the initial channel state and watches for changes.
    /// - Parameter options: an additional channel options, e.g. `.presence`
    /// - Returns: an observable channel response.
    func watch(options: QueryOptions = [], _ completion: @escaping ClientCompletion<ChannelResponse>) -> Subscription {
        return rx.watch(options: options).bind(to: completion)
    }
    
    /// Stop watching the channel for a state changes.
    func stopWatching(_ completion: @escaping EmptyClientCompletion) -> Subscription {
        return rx.stopWatching().bind(to: completion)
    }
    
    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - user: the current user.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    func hide(for user: User? = User.current,
              clearHistory: Bool = false,
              _ completion: @escaping EmptyClientCompletion) -> Subscription {
        return rx.hide(for: user, clearHistory: clearHistory).bind(to: completion)
    }
    
    /// Removes the hidden status for a channel.
    /// - Parameter user: the current user.
    func show(for user: User? = User.current, _ completion: @escaping EmptyClientCompletion) -> Subscription {
        return rx.show(for: user).bind(to: completion)
    }
    
    /// Update channel data.
    /// - Parameter name: a channel name.
    /// - Parameter imageURL: an image URL.
    /// - Parameter extraData: a custom extra data.
    func update(name: String? = nil,
                imageURL: URL? = nil,
                extraData: Codable? = nil,
                _ completion: @escaping ClientCompletion<ChannelResponse>) -> Subscription {
        return rx.update(name: name, imageURL: imageURL, extraData: extraData).bind(to: completion)
    }
    
    /// Delete the channel.
    ///
    /// - Returns: an observable completion.
    func delete(_ completion: @escaping ClientCompletion<ChannelDeletedResponse>) -> Subscription {
        return rx.delete().bind(to: completion)
    }
    
    /// Send a new message or update with a given `message.id`.
    /// - Parameter message: a message.
    /// - Returns: a created/updated message response.
    func send(message: Message, _ completion: @escaping ClientCompletion<MessageResponse>) -> Subscription {
        return rx.send(message: message).bind(to: completion)
    }
    
    /// Send a message action for a given ephemeral message.
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    /// - Returns: a result message.
    func send(action: Attachment.Action,
              for ephemeralMessage: Message,
              _ completion: @escaping ClientCompletion<MessageResponse>) -> Subscription {
        return rx.send(action: action, for: ephemeralMessage).bind(to: completion)
    }
    
    /// Mark messages in the channel as readed.
    ///
    /// - Returns: an observable event response.
    func markRead(_ completion: @escaping ClientCompletion<Event>) -> Subscription {
        return rx.markRead().bind(to: completion)
    }
    
    /// Send an event.
    ///
    /// - Parameter eventType: an event type.
    /// - Returns: an observable event.
    func send(eventType: EventType, _ completion: @escaping ClientCompletion<Event>) -> Subscription {
        return rx.send(eventType: eventType).bind(to: completion)
    }
    
    /// Add a member to the channel.
    /// - Parameter member: a member.
    func add(_ member: Member, _ completion: @escaping ClientCompletion<ChannelResponse>) -> Subscription {
        return rx.add(member).bind(to: completion)
    }
    
    /// Add members to the channel.
    /// - Parameter members: members.
    func add(_ members: Set<Member>, _ completion: @escaping ClientCompletion<ChannelResponse>) -> Subscription {
        return rx.add(members).bind(to: completion)
    }
    
    /// Remove a member from the channel.
    /// - Parameter member: a member.
    func remove(_ member: Member, _ completion: @escaping ClientCompletion<ChannelResponse>) -> Subscription {
        return rx.remove(member).bind(to: completion)
    }
    
    /// Remove members from the channel.
    /// - Parameter members: members.
    func remove(_ members: Set<Member>, _ completion: @escaping ClientCompletion<ChannelResponse>) -> Subscription {
        return rx.remove(members).bind(to: completion)
    }
    
    /// Ban a user.
    /// - Parameter user: a user.
    func ban(user: User,
             timeoutInMinutes: Int? = nil,
             reason: String? = nil,
             _ completion: @escaping EmptyClientCompletion) -> Subscription {
        return rx.ban(user: user, timeoutInMinutes: timeoutInMinutes, reason: reason).bind(to: completion)
    }
    
    /// Invite a member to the channel.
    /// - Parameter member: a member.
    /// - Returns: an observable channel response.
    func invite(_ member: Member, _ completion: @escaping ClientCompletion<ChannelResponse>) -> Subscription {
        return rx.invite(member).bind(to: completion)
    }
    
    /// Invite members to the channel.
    /// - Parameter members: a list of members.
    /// - Returns: an observable channel response.
    func invite(_ members: [Member], _ completion: @escaping ClientCompletion<ChannelResponse>) -> Subscription {
        return rx.invite(members).bind(to: completion)
    }
    
    /// Accept an invite to the channel.
    ///
    /// - Parameter message: an additional message.
    /// - Returns: an observable channel response.
    func acceptInvite(with message: Message? = nil,
                      _ completion: @escaping ClientCompletion<ChannelInviteResponse>) -> Subscription {
        return rx.acceptInvite(with: message).bind(to: completion)
    }
    
    /// Reject an invite to the channel.
    ///
    /// - Parameter message: an additional message.
    /// - Returns: an observable channel response.
    func rejectInvite(with message: Message? = nil,
                      _ completion: @escaping ClientCompletion<ChannelInviteResponse>) -> Subscription {
        return rx.rejectInvite(with: message).bind(to: completion)
    }
    
    /// Upload an image to the channel.
    ///
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    /// - Returns: an observable file upload response.
    func sendImage(fileName: String,
                   mimeType: String,
                   imageData: Data,
                   _ completion: @escaping ClientCompletion<ProgressResponse<URL>>) -> Subscription {
        return rx.sendImage(fileName: fileName, mimeType: mimeType, imageData: imageData).bind(to: completion)
    }
    
    /// Upload a file to the channel.
    ///
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    /// - Returns: an observable file upload response.
    func sendFile(fileName: String,
                  mimeType: String,
                  fileData: Data,
                  _ completion: @escaping ClientCompletion<ProgressResponse<URL>>) -> Subscription {
        return rx.sendFile(fileName: fileName, mimeType: mimeType, fileData: fileData).bind(to: completion)
    }
    
    /// Delete an image with a given URL.
    ///
    /// - Parameter url: an image URL.
    /// - Returns: an empty observable result.
    func deleteImage(url: URL, _ completion: @escaping EmptyClientCompletion) -> Subscription {
        return rx.deleteImage(url: url).bind(to: completion)
    }
    
    /// Delete a file with a given URL.
    ///
    /// - Parameter url: a file URL.
    /// - Returns: an empty observable result.
    func deleteFile(url: URL, _ completion: @escaping EmptyClientCompletion) -> Subscription {
        return rx.deleteFile(url: url).bind(to: completion)
    }
    
    /// Delete a message.
    ///
    /// - Parameter message: a message.
    /// - Returns: an observable message response.
    func delete(message: Message, _ completion: @escaping ClientCompletion<MessageResponse>) -> Subscription {
        return rx.delete(message: message).bind(to: completion)
    }
    
    /// Add a reaction to a message.
    ///
    /// - Parameters:
    ///   - reactionType: a reaction type, e.g. like.
    ///   - message: a message.
    /// - Returns: an observable message response.
    func addReaction(_ reactionType: ReactionType,
                     to message: Message,
                     _ completion: @escaping ClientCompletion<MessageResponse>) -> Subscription {
        return rx.addReaction(reactionType, to: message).bind(to: completion)
    }
    
    /// Delete a reaction to the message.
    ///
    /// - Parameters:
    ///     - reactionType: a reaction type, e.g. like.
    ///     - message: a message.
    /// - Returns: an observable message response.
    func deleteReaction(_ reactionType: ReactionType,
                        from message: Message,
                        _ completion: @escaping ClientCompletion<MessageResponse>) -> Subscription {
        return rx.deleteReaction(reactionType, from: message).bind(to: completion)
    }
    
    /// Send a request for reply messages.
    ///
    /// - Parameters:
    ///     - parentMessage: a parent message of replies.
    ///     - pagination: a pagination (see `Pagination`).
    /// - Returns: an observable message response.
    func replies(for parentMessage: Message,
                 pagination: Pagination,
                 _ completion: @escaping ClientCompletion<[Message]>) -> Subscription {
        return rx.replies(for: parentMessage, pagination: pagination).bind(to: completion)
    }
    
    /// Flag a message.
    ///
    /// - Parameter message: a message.
    /// - Returns: an observable flag message response.
    func flag(message: Message, _ completion: @escaping ClientCompletion<FlagMessageResponse>) -> Subscription {
        return rx.flag(message: message).bind(to: completion)
    }
    
    /// Unflag a message.
    ///
    /// - Parameter message: a message.
    /// - Returns: an observable flag message response.
    func unflag(message: Message, _ completion: @escaping ClientCompletion<FlagMessageResponse>) -> Subscription {
        return rx.unflag(message: message).bind(to: completion)
    }
}
