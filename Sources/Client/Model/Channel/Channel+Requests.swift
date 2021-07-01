//
//  Channel+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Channel Requests

public extension Channel {
    
    /// The number of seconds from the last `typingStart` event until the `typingStop` event is automatically sent.
    static var startTypingEventTimeout: TimeInterval = 5
   
    /// If user is still typing, resend the `typingStart` event after this time interval.
    static var startTypingResendInterval: TimeInterval = 20
      
    /// Create a channel.
    /// - Parameter completion: a completion block with `ChannelResponse`.
    @discardableResult
    func create(_ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.create(channel: self, completion)
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc
    /// - Parameters:
    ///   - pagination: a pagination for messages (see `Pagination`).
    ///   - options: a query options. `.state` by default (see `QueryOptions`)
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func query(messagesPagination: Pagination = [],
               membersPagination: Pagination = [],
               watchersPagination: Pagination = [],
               options: QueryOptions = .state,
               _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.queryChannel(self,
                                   messagesPagination: messagesPagination,
                                   membersPagination: membersPagination,
                                   watchersPagination: watchersPagination,
                                   options: options,
                                   completion)
    }
    
    /// Loads the initial channel state and watches for changes.
    /// - Parameters:
    ///   - options: an additional channel options, e.g. `.presence`
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func watch(options: QueryOptions = [], _ completion: @escaping Client.Completion<ChannelResponse> = { _ in }) -> Cancellable {
        Client.shared.watch(channel: self, options: options, completion)
    }
    
    /// Stop watching the channel for a state changes.
    /// - Parameter completion: an empty completion block.
    @discardableResult
    func stopWatching(_ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        Client.shared.stopWatching(channel: self, completion)
    }
    
    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - user: the current user.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func hide(clearHistory: Bool = false, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        Client.shared.hide(channel: self, clearHistory: clearHistory, completion)
    }
    
    /// Removes the hidden status for a channel.
    /// - Parameters:
    ///   - user: the current user.
    ///   - completion: an empty completion block.
    @discardableResult
    func show(_ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        Client.shared.show(channel: self, completion)
    }
    
    /// Mutes a channel.
    /// - Parameter completion: an empty completion block.
    @discardableResult
    func mute(_ completion: @escaping Client.Completion<MutedChannelResponse> = { _ in }) -> Cancellable {
        Client.shared.mute(channel: self, completion)
    }
    
    /// Unmutes a channel.
    /// - Parameter completion: an empty completion block.
    @discardableResult
    func unmute(_ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        Client.shared.unmute(channel: self, completion)
    }
    
    /// Update channel data.
    /// - Parameters:
    ///   - name: a channel name.
    ///   - imageURL: an image URL.
    ///   - extraData: a custom extra data.
    ///   - completion: a completion block with `ChannelResponse`.
    @available(*, deprecated, message: "Please use `update(extraData:_)` instead")
    @discardableResult
    func update(name: String? = nil,
                imageURL: URL? = nil,
                extraData: ChannelExtraDataCodable? = nil,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.update(channel: self, extraData: extraData, completion)
    }
    
    /// Update channel data.
    /// - Parameters:
    ///   - extraData: a custom extra data.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func update(extraData: ChannelExtraDataCodable? = nil,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.update(channel: self, extraData: extraData, completion)
    }
    
    /// Delete the channel.
    /// - Parameter completion: a completion block with `Channel`.
    @discardableResult
    func delete(_ completion: @escaping Client.Completion<Channel>) -> Cancellable {
        Client.shared.delete(channel: self, completion)
    }
    
    // MARK: - Message
    
    /// Send a new message with a given `message.id`.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func send(message: Message, _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        Client.shared.send(message: message, to: self, completion)
    }
    
    /// Update a message with a given `message.id`.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func edit(message: Message, _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        Client.shared.edit(message: message, to: self, completion)
    }
    
    /// Send a message action for a given ephemeral message.
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func send(action: Attachment.Action,
              for ephemeralMessage: Message,
              _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        Client.shared.send(action: action, for: ephemeralMessage, to: self, completion)
    }
    
    /// Mark messages in the channel as read.
    /// - Parameter completion: a completion block with `Event`.
    @discardableResult
    func markRead(_ completion: @escaping Client.Completion<Event>) -> Cancellable {
        Client.shared.markRead(channel: self, completion)
    }
    
    // MARK: - Events
    
    /// Send an event.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - completion: a completion block with `Event`.
    @discardableResult
    func send(eventType: EventType, _ completion: @escaping Client.Completion<Event>) -> Cancellable {
        Client.shared.send(eventType: eventType, to: self, completion)
    }
    
    /// Send a keystroke event for the current user.
    /// - Note: This method should be called from the main thread.
    /// - Parameter completion: a completion block with `Event`.
    @discardableResult
    func keystroke(_ completion: @escaping Client.Completion<Event>) -> Cancellable {
        keystroke(client: .shared, timerType: DefaultTimer.self, completion)
    }
    
    @discardableResult
    internal func keystroke(client: Client,
                            timerType: Timer.Type = DefaultTimer.self,
                            _ completion: @escaping Client.Completion<Event>) -> Cancellable {
        currentUserTypingTimerControlAtomic.get()?.cancel()
        
        let timerControl = timerType
            .schedule(timeInterval: Self.startTypingEventTimeout, queue: .main) { [weak self, unowned client] in
                self?.stopTyping(client: client, completion)
            }
        
        currentUserTypingTimerControlAtomic.set(timerControl)
        
        // The user is typing too long, we should resend `.typingStart` event.
        if
            let lastDate = currentUserTypingLastDateAtomic.get(),
            currentTime().timeIntervalSince(lastDate) < Self.startTypingResendInterval
        {
            completion(.success(.typingStart(client.user, cid, .typingStart)))
            return Subscription.empty
        }
        
        currentUserTypingLastDateAtomic.set(currentTime())
        return client.send(eventType: .typingStart, to: self, completion)
    }
    
    /// Send a stop typing event for the current user.
    /// - Note: This method should be called from the main thread.
    /// - Parameter completion: a completion block with `Event`.
    @discardableResult
    func stopTyping(_ completion: @escaping Client.Completion<Event>) -> Cancellable {
        stopTyping(client: .shared, completion)
    }
    
    @discardableResult
    internal func stopTyping(client: Client, _ completion: @escaping Client.Completion<Event>) -> Cancellable {
        guard currentUserTypingLastDateAtomic.get() != nil else {
            completion(.success(.typingStop(client.user, cid, .typingStop)))
            return Subscription.empty
        }
        
        currentUserTypingTimerControlAtomic.get()?.cancel()
        currentUserTypingLastDateAtomic.set(nil)
        
        return client.send(eventType: .typingStop, to: self, completion)
    }
    
    // MARK: - Members
    
    /// Add a user as a member to the channel.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(user: User, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.add(user: user, to: self, completion)
    }
    
    /// Add members to the channel.
    /// - Parameters:
    ///   - users: users.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(users: Set<User>, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.add(users: users, to: self, completion)
    }
    
    /// Add a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(member: Member, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.add(member: member, to: self, completion)
    }
    
    /// Add members to the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(members: Set<Member>, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.add(members: members, to: self, completion)
    }
    
    /// Remove a user as a member from the channel.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(user: User, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.remove(user: user, from: self, completion)
    }
    
    /// Remove users as members from the channel.
    /// - Parameters:
    ///   - users: users.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(users: Set<User>, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.remove(users: users, from: self, completion)
    }
    
    /// Remove a member from the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(member: Member, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.remove(member: member, from: self, completion)
    }
    
    /// Remove members from the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(members: Set<Member>, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.remove(members: members, from: self, completion)
    }
    
    /// Query this channel's members.
    /// - Parameters:
    ///   - filter: Filter conditions for query
    ///   - sorting: Sorting conditions for query
    ///   - limit: Limit for number of members to return. Defaults to 100.
    ///   - offset: Offset of pagination. Defaults to 0.
    ///   - completion: Completion block with `MembersQueryResponse`
    @discardableResult
    func queryMembers(filter: Filter,
                      sorting: [Sorting] = [],
                      limit: Int = 100,
                      offset: Int = 0,
                      _ completion: @escaping Client.Completion<MembersQueryResponse>) -> Cancellable {
        let query: MembersQuery
        if id.isEmpty {
            query = MembersQuery(channelType: type,
                                 members: Array(members),
                                 filter: filter,
                                 sorting: sorting,
                                 limit: limit,
                                 offset: offset)
        } else {
            query = MembersQuery(channelId: cid,
                                 filter: filter,
                                 sorting: sorting,
                                 limit: limit,
                                 offset: offset)
        }
        return Client.shared.queryMembers(membersQuery: query, completion)
    }
    
    // MARK: - User Ban
    
    /// Ban a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - timeoutInMinutes: for a timeout in minutes.
    ///   - completion: an empty completion block.
    @discardableResult
    func ban(user: User,
             timeoutInMinutes: Int? = nil,
             reason: String? = nil,
             _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        Client.shared.ban(user: user, in: self, timeoutInMinutes: timeoutInMinutes, reason: reason, completion)
    }
    
    /// Unban a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: an empty completion block.
    @discardableResult
    func unban(user: User, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        Client.shared.unban(user: user, in: self, completion)
    }
    
    // MARK: - Invite Requests
    
    /// Invite a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func invite(member: Member, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.invite(member: member, to: self, completion)
    }
    
    /// Invite members to the channel.
    /// - Parameters:
    ///   - members: a list of members.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func invite(members: Set<Member>, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        Client.shared.invite(members: members, to: self, completion)
    }
    
    /// Accept an invite to the channel.
    ///
    /// - Parameters:
    ///   - message: an additional message.
    ///   - completion: a completion block with `ChannelInviteResponse`.
    @discardableResult
    func acceptInvite(with message: Message? = nil,
                      _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> Cancellable {
        Client.shared.acceptInvite(for: self, with: message, completion)
    }
    
    /// Reject an invite to the channel.
    /// - Parameters:
    ///   - message: an additional message.
    ///   - completion: a completion block with `ChannelInviteResponse`.
    @discardableResult
    func rejectInvite(with message: Message? = nil,
                      _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> Cancellable {
        Client.shared.rejectInvite(for: self, with: message, completion)
    }
    
    // MARK: - Uploading
    
    /// Upload an image to the channel.
    /// - Parameters:
    ///   - data: an image data.
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - completion: a completion block with `ProgressResponse<URL>`.
    @discardableResult
    func sendImage(data: Data,
                   fileName: String,
                   mimeType: String,
                   progress: @escaping Client.Progress,
                   completion: @escaping Client.Completion<URL>) -> Cancellable {
        Client.shared.sendImage(data: data,
                                fileName: fileName,
                                mimeType: mimeType,
                                channel: self,
                                progress: progress,
                                completion: completion)
    }
    
    /// Upload a file to the channel.
    /// - Parameters:
    ///   - data: a file data.
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - completion: a completion block with `ProgressResponse<URL>`.
    @discardableResult
    func sendFile(data: Data,
                  fileName: String,
                  mimeType: String,
                  progress: @escaping Client.Progress,
                  completion: @escaping Client.Completion<URL>) -> Cancellable {
        Client.shared.sendFile(data: data,
                               fileName: fileName,
                               mimeType: mimeType,
                               channel: self,
                               progress: progress,
                               completion: completion)
    }
    
    /// Delete an image with a given URL.
    /// - Parameters:
    ///   - url: an image URL.
    ///   - completion: an empty completion block.
    @discardableResult
    func deleteImage(url: URL, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        Client.shared.deleteImage(url: url, channel: self, completion)
    }
    
    /// Delete a file with a given URL.
    /// - Parameters:
    ///   - url: a file URL.
    ///   - completion: an empty completion block.
    @discardableResult
    func deleteFile(url: URL, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        Client.shared.deleteFile(url: url, channel: self, completion)
    }
    
    /// Enable slow mode for the channel
    /// - Parameters:
    ///   - cooldown: Cooldown duration in seconds. (1-120)
    ///   - completion: an empty completion block.
    @discardableResult
    func enableSlowMode(cooldown: Int,
                        _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        Client.shared.enableSlowMode(for: self, cooldown: cooldown, completion)
    }
    
    /// Disables slow mode for the channel
    /// - Parameters:
    ///   - completion: an empty completion block.
    @discardableResult
    func disableSlowMode(_ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        Client.shared.disableSlowMode(for: self, completion)
    }
}
