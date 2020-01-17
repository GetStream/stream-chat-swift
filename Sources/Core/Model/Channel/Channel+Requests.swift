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
    /// - Parameter completion: a completion block with `ChannelResponse`.
    func create(_ completion: @escaping Client.Completion<ChannelResponse>) {
        return rx.create().bindOnce(to: completion)
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc
    /// - Parameters:
    ///   - pagination: a pagination for messages (see `Pagination`).
    ///   - options: a query options. All by default (see `QueryOptions`), e.g. `.watch`.
    ///   - completion: a completion block with `ChannelResponse`.
    func query(pagination: Pagination = .none,
               options: QueryOptions = [],
               _ completion: @escaping Client.Completion<ChannelResponse>) {
        return rx.query(pagination: pagination, options: options).bindOnce(to: completion)
    }
    
    /// Loads the initial channel state and watches for changes.
    /// - Parameters:
    ///   - options: an additional channel options, e.g. `.presence`
    ///   - completion: a completion block with `ChannelResponse`.
    func watch(options: QueryOptions = [], _ completion: @escaping Client.Completion<ChannelResponse>) {
        return rx.watch(options: options).bindOnce(to: completion)
    }
    
    /// Stop watching the channel for a state changes.
    /// - Parameter completion: an empty completion block.
    func stopWatching(_ completion: @escaping Client.Completion<Void> = { _ in }) {
        return rx.stopWatching().bindOnce(to: completion)
    }
    
    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - user: the current user.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    ///   - completion: an empty completion block.
    func hide(for user: User? = User.current,
              clearHistory: Bool = false,
              _ completion: @escaping Client.Completion<Void> = { _ in }) {
        return rx.hide(for: user, clearHistory: clearHistory).bindOnce(to: completion)
    }
    
    /// Removes the hidden status for a channel.
    /// - Parameters:
    ///   - user: the current user.
    ///   - completion: an empty completion block.
    func show(for user: User? = User.current, _ completion: @escaping Client.Completion<Void> = { _ in }) {
        return rx.show(for: user).bindOnce(to: completion)
    }
    
    /// Update channel data.
    /// - Parameters:
    ///   - name: a channel name.
    ///   - imageURL: an image URL.
    ///   - extraData: a custom extra data.
    ///   - completion: a completion block with `ChannelResponse`.
    func update(name: String? = nil,
                imageURL: URL? = nil,
                extraData: Codable? = nil,
                _ completion: @escaping Client.Completion<ChannelResponse>) {
        return rx.update(name: name, imageURL: imageURL, extraData: extraData).bindOnce(to: completion)
    }
    
    /// Delete the channel.
    /// - Parameter completion: a completion block with `Channel`.
    func delete(_ completion: @escaping Client.Completion<Channel>) {
        return rx.delete().bindOnce(to: completion)
    }
    
    /// Send a new message or update with a given `message.id`.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `MessageResponse`.
    func send(message: Message, _ completion: @escaping Client.Completion<MessageResponse>) {
        return rx.send(message: message).bindOnce(to: completion)
    }
    
    /// Send a message action for a given ephemeral message.
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    ///   - completion: a completion block with `MessageResponse`.
    func send(action: Attachment.Action,
              for ephemeralMessage: Message,
              _ completion: @escaping Client.Completion<MessageResponse>) {
        return rx.send(action: action, for: ephemeralMessage).bindOnce(to: completion)
    }
    
    /// Mark messages in the channel as readed.
    /// - Parameter completion: a completion block with `Event`.
    func markRead(_ completion: @escaping Client.Completion<Event>) {
        return rx.markRead().bindOnce(to: completion)
    }
    
    /// Send an event.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - completion: a completion block with `Event`.
    func send(eventType: EventType, _ completion: @escaping Client.Completion<Event>) {
        return rx.send(eventType: eventType).bindOnce(to: completion)
    }
    
    /// Add a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - completion: a completion block with `ChannelResponse`.
    func add(_ member: Member, _ completion: @escaping Client.Completion<ChannelResponse>) {
        return rx.add(member).bindOnce(to: completion)
    }
    
    /// Add members to the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - completion: a completion block with `ChannelResponse`.
    func add(_ members: Set<Member>, _ completion: @escaping Client.Completion<ChannelResponse>) {
        return rx.add(members).bindOnce(to: completion)
    }
    
    /// Remove a member from the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - completion: a completion block with `ChannelResponse`.
    func remove(_ member: Member, _ completion: @escaping Client.Completion<ChannelResponse>) {
        return rx.remove(member).bindOnce(to: completion)
    }
    
    /// Remove members from the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - completion: a completion block with `ChannelResponse`.
    func remove(_ members: Set<Member>, _ completion: @escaping Client.Completion<ChannelResponse>) {
        return rx.remove(members).bindOnce(to: completion)
    }
    
    /// Ban a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - timeoutInMinutes: for a timeout in minutes.
    ///   - completion: an empty completion block.
    func ban(user: User,
             timeoutInMinutes: Int? = nil,
             reason: String? = nil,
             _ completion: @escaping Client.Completion<Void> = { _ in }) {
        return rx.ban(user: user, timeoutInMinutes: timeoutInMinutes, reason: reason).bindOnce(to: completion)
    }
    
    /// Invite a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - completion: a completion block with `ChannelResponse`.
    func invite(_ member: Member, _ completion: @escaping Client.Completion<ChannelResponse>) {
        return rx.invite(member).bindOnce(to: completion)
    }
    
    /// Invite members to the channel.
    /// - Parameters:
    ///   - members: a list of members.
    ///   - completion: a completion block with `ChannelResponse`.
    func invite(_ members: [Member], _ completion: @escaping Client.Completion<ChannelResponse>) {
        return rx.invite(members).bindOnce(to: completion)
    }
    
    /// Accept an invite to the channel.
    ///
    /// - Parameters:
    ///   - message: an additional message.
    ///   - completion: a completion block with `ChannelInviteResponse`.
    func acceptInvite(with message: Message? = nil,
                      _ completion: @escaping Client.Completion<ChannelInviteResponse>) {
        return rx.acceptInvite(with: message).bindOnce(to: completion)
    }
    
    /// Reject an invite to the channel.
    /// - Parameters:
    ///   - message: an additional message.
    ///   - completion: a completion block with `ChannelInviteResponse`.
    func rejectInvite(with message: Message? = nil,
                      _ completion: @escaping Client.Completion<ChannelInviteResponse>) {
        return rx.rejectInvite(with: message).bindOnce(to: completion)
    }
    
    /// Upload an image to the channel.
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - completion: a completion block with `ProgressResponse<URL>`.
    func sendImage(fileName: String,
                   mimeType: String,
                   imageData: Data,
                   _ completion: @escaping Client.Completion<ProgressResponse<URL>>) {
        return rx.sendImage(fileName: fileName, mimeType: mimeType, imageData: imageData).bindOnce(to: completion)
    }
    
    /// Upload a file to the channel.
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - completion: a completion block with `ProgressResponse<URL>`.
    func sendFile(fileName: String,
                  mimeType: String,
                  fileData: Data,
                  _ completion: @escaping Client.Completion<ProgressResponse<URL>>) {
        return rx.sendFile(fileName: fileName, mimeType: mimeType, fileData: fileData).bindOnce(to: completion)
    }
    
    /// Delete an image with a given URL.
    /// - Parameters:
    ///   - url: an image URL.
    ///   - completion: an empty completion block.
    func deleteImage(url: URL, _ completion: @escaping Client.Completion<Void> = { _ in }) {
        return rx.deleteImage(url: url).bindOnce(to: completion)
    }
    
    /// Delete a file with a given URL.
    /// - Parameters:
    ///   - url: a file URL.
    ///   - completion: an empty completion block.
    func deleteFile(url: URL, _ completion: @escaping Client.Completion<Void> = { _ in }) {
        return rx.deleteFile(url: url).bindOnce(to: completion)
    }
    
    /// Delete a message.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `MessageResponse`.
    func delete(message: Message, _ completion: @escaping Client.Completion<MessageResponse>) {
        return rx.delete(message: message).bindOnce(to: completion)
    }
    
    /// Add a reaction to a message.
    /// - Parameters:
    ///   - reactionType: a reaction type, e.g. like.
    ///   - message: a message.
    ///   - completion: a completion block with `MessageResponse`.
    func addReaction(_ reactionType: ReactionType,
                     to message: Message,
                     _ completion: @escaping Client.Completion<MessageResponse>) {
        return rx.addReaction(reactionType, to: message).bindOnce(to: completion)
    }
    
    /// Delete a reaction to the message.
    /// - Parameters:
    ///   - reactionType: a reaction type, e.g. like.
    ///   - message: a message.
    ///   - completion: a completion block with `MessageResponse`.
    func deleteReaction(_ reactionType: ReactionType,
                        from message: Message,
                        _ completion: @escaping Client.Completion<MessageResponse>) {
        return rx.deleteReaction(reactionType, from: message).bindOnce(to: completion)
    }
    
    /// Send a request for reply messages.
    /// - Parameters:
    ///   - parentMessage: a parent message of replies.
    ///   - pagination: a pagination (see `Pagination`).
    ///   - completion: a completion block with `[Message]`.
    func replies(for parentMessage: Message,
                 pagination: Pagination,
                 _ completion: @escaping Client.Completion<[Message]>) {
        return rx.replies(for: parentMessage, pagination: pagination).bindOnce(to: completion)
    }
    
    /// Flag a message.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `FlagMessageResponse`.
    func flag(message: Message, _ completion: @escaping Client.Completion<FlagMessageResponse>) {
        return rx.flag(message: message).bindOnce(to: completion)
    }
    
    /// Unflag a message.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `FlagMessageResponse`.
    func unflag(message: Message, _ completion: @escaping Client.Completion<FlagMessageResponse>) {
        return rx.unflag(message: message).bindOnce(to: completion)
    }
}
