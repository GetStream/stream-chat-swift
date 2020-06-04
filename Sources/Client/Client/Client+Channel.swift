//
//  Client+Channel.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 04/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Channel Setup

public extension Client {
    
    /// A common way to init a channel with channel type and id.
    /// - Parameters:
    ///   - type: a channel type.
    ///   - id: a channel id.
    ///   - members: a list of members.
    ///   - invitedMembers: a list of invited members.
    ///   - team: The team the channel belongs to.
    ///   - extraData: a channel extra data.
    func channel(type: ChannelType,
                 id: String,
                 members: [User] = [],
                 invitedMembers: [User] = [],
                 team: String = "",
                 extraData: ChannelExtraDataCodable? = nil) -> Channel {
        Channel(type: type,
                id: id,
                members: members,
                invitedMembers: invitedMembers,
                extraData: extraData,
                created: .init(),
                deleted: nil,
                createdBy: nil,
                lastMessageDate: nil,
                frozen: false,
                team: team,
                config: .init())
    }
    
    /// A channel with members without id. It's great for direct message channels.
    /// - Note: The number of members should be more than 1.
    /// - Parameters:
    ///   - type: a channel type.
    ///   - members: a list of members.
    ///   - team: The team the channel belongs to.
    ///   - extraData: a channel extra data.
    ///   - namingStrategy: a naming strategy to generate a name and image for the channel based on members.
    ///                     Only takes effect if `extraData` is `nil`.
    func channel(type: ChannelType = .messaging,
                 members: [User],
                 team: String = "",
                 extraData: ChannelExtraDataCodable? = nil,
                 namingStrategy: ChannelNamingStrategy? = Channel.DefaultNamingStrategy(maxUserNames: 1)) -> Channel {
        var extraData = extraData
        
        if extraData == nil, let namingStrategy = namingStrategy {
            extraData = namingStrategy.extraData(for: user, members: members)
        }
        
        return Channel(type: type,
                       id: "",
                       members: members,
                       invitedMembers: [],
                       extraData: extraData,
                       created: .init(),
                       deleted: nil,
                       createdBy: nil,
                       lastMessageDate: nil,
                       frozen: false,
                       team: team,
                       config: .init())
    }
}

// MARK: Channel Requests

public extension Client {
    
    /// Create a channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func create(channel: Channel, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        queryChannel(channel, completion)
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc.
    /// Creates a `ChannelQuery` with given parameters and call `queryChannel` with it.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - pagination: a pagination for messages (see `Pagination`).
    ///   - options: a query options. `.state` by default (see `QueryOptions`)
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func queryChannel(_ channel: Channel,
                      messagesPagination: Pagination = [],
                      membersPagination: Pagination = [],
                      watchersPagination: Pagination = [],
                      options: QueryOptions = .state,
                      _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        queryChannel(query: .init(channel: channel,
                                  messagesPagination: messagesPagination,
                                  membersPagination: membersPagination,
                                  watchersPagination: watchersPagination,
                                  options: options), completion)
    }
    
    /// Requests for a channel data, e.g. messages, members, read states, etc.
    /// - Parameters:
    ///   - query: a channel query.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func queryChannel(query: ChannelQuery, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        watchingChannelsAtomic.flush()
        
        var modifiedCompletion = completion
        
        if query.options.contains(.watch), query.options.contains(.state) {
            modifiedCompletion = { [unowned self] result in
                if let channel = result.value?.channel {
                    self.refreshWatchingChannels(with: channel)
                }
                
                completion(result)
            }
        }
        
        return request(endpoint: .channel(query), modifiedCompletion)
    }
    
    /// Loads the initial channel state and watches for changes.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - options: an additional channel options, e.g. `.presence`
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func watch(channel: Channel,
               options: QueryOptions = [],
               _ completion: @escaping Client.Completion<ChannelResponse> = { _ in }) -> Cancellable {
        watchingChannelsAtomic.flush()
        watchingChannelsAtomic.add(channel, key: channel.cid)
        return queryChannel(channel, options: options.union(.watch), completion)
    }
    
    /// Stop watching the channel for a state changes.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func stopWatching(channel: Channel, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        request(endpoint: .stopWatching(channel), completion)
    }
    
    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func hide(channel: Channel,
              clearHistory: Bool = false,
              _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        let completion = doAfter(completion) { [unowned self, weak channel] _ in
            if let channel = channel {
                self.stopWatching(channel: channel)
            }
        }
        
        return request(endpoint: .hideChannel(channel, user, clearHistory), completion)
    }
    
    /// Removes the hidden status for a channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - user: the current user.
    ///   - completion: an empty completion block.
    @discardableResult
    func show(channel: Channel, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        request(endpoint: .showChannel(channel, user), completion)
    }
    
    /// Update channel data.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - name: a channel name.
    ///   - imageURL: an image URL.
    ///   - extraData: a custom extra data.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func update(channel: Channel,
                name: String? = nil,
                imageURL: URL? = nil,
                extraData: ChannelExtraDataCodable? = nil,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        var changed = false
        
        if let name = name, !name.isEmpty {
            changed = true
            channel.name = name
        }
        
        if let imageURL = imageURL {
            changed = true
            channel.imageURL = imageURL
        }
        
        if let extraData = extraData {
            changed = true
            channel.extraData = extraData
        }
        
        guard changed else {
            completion(.success(.init(channel: channel)))
            return Subscription.empty
        }
        
        return request(endpoint: .updateChannel(.init(data: .init(channel))), completion)
    }
    
    /// Delete the channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - completion: a completion block with `Channel`.
    @discardableResult
    func delete(channel: Channel, _ completion: @escaping Client.Completion<Channel>) -> Cancellable {
        request(endpoint: .deleteChannel(channel)) { (result: Result<ChannelDeletedResponse, ClientError>) in
            completion(result.map(to: \.channel))
        }
    }
    
    // MARK: - Message
    
    /// Send a new message or update with a given `message.id`.
    /// - Parameters:
    ///   - message: a message.
    ///   - channel: a channel.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func send(message: Message, to channel: Channel, _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        let completion = doAfter(completion) { [unowned self] response in
            if response.message.isBan, !self.user.isBanned {
                self.userAtomic.isBanned = true
            }
        }
        
        if channel.id.isEmpty {
            completion(.failure(.emptyChannelId))
            return Subscription.empty
        }
        
        // Add mentiond users
        var message = message
        var mentionedUsers = [User]()
        
        if !message.text.isEmpty, message.text.contains("@"), !channel.members.isEmpty {
            let text = message.text.lowercased()
            
            channel.members.forEach { member in
                if text.contains("@\(member.user.name.lowercased())") {
                    mentionedUsers.append(member.user)
                }
            }
        }
        
        message.mentionedUsers = mentionedUsers
        
        let completionWithStopTypingEvent = doBefore(completion) { [weak channel] _ in
            channel?.stopTyping({ _ in })
        }
        
        return request(endpoint: .sendMessage(message, channel), completionWithStopTypingEvent)
    }
    
    /// Send a message action for a given ephemeral message.
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    ///   - channel: a channel.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func send(action: Attachment.Action,
              for ephemeralMessage: Message,
              to channel: Channel,
              _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        request(endpoint: .sendMessageAction(.init(channel: channel, message: ephemeralMessage, action: action)), completion)
    }
    
    /// Mark messages in the channel as read.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - completion: a completion block with `Event`.
    @discardableResult
    func markRead(channel: Channel, _ completion: @escaping Client.Completion<Event>) -> Cancellable {
        guard channel.readEventsEnabled else {
            return Subscription.empty
        }
        
        logger?.log("🎫 Mark Read")
        
        return request(endpoint: .markRead(channel)) { (result: Result<EventResponse, ClientError>) in
            completion(result.map(to: \.event))
        }
    }
    
    /// Send an event.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - channel: a channel.
    ///   - completion: a completion block with `Event`.
    @discardableResult
    func send(eventType: EventType, to channel: Channel, _ completion: @escaping Client.Completion<Event>) -> Cancellable {
        #if DEBUG
        outgoingEventsTestLogger?(eventType)
        #endif
        
        return request(endpoint: .sendEvent(eventType, channel)) { [unowned self] (result: Result<EventResponse, ClientError>) in
            self.logger?.log("🎫 \(eventType.rawValue)")
            completion(result.map(to: \.event))
        }
    }
    
    // MARK: - Members
    
    /// Add a user to the channel as a member.
    /// - Parameters:
    ///   - user: a user.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(user: User, to channel: Channel, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        add(members: Set([user.asMember]), to: channel, completion)
    }
    
    /// Add users to the channel as members.
    /// - Parameters:
    ///   - users: users.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(users: Set<User>,
             to channel: Channel,
             _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        add(members: Set(users.map({ $0.asMember })), to: channel, completion)
    }
    
    /// Add a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(member: Member, to channel: Channel, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        add(members: Set([member]), to: channel, completion)
    }
    
    /// Add members to the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(members: Set<Member>,
             to channel: Channel,
             _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        request(endpoint: .addMembers(members, channel), completion)
    }
    
    /// Remove a user as a member from the channel.
    /// - Parameters:
    ///   - user: a user.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(user: User,
                from channel: Channel,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        remove(members: Set([user.asMember]), from: channel, completion)
    }
    
    /// Remove users as members from the channel.
    /// - Parameters:
    ///   - users: users.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(users: Set<User>,
                from channel: Channel,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        remove(members: Set(users.map({ $0.asMember })), from: channel, completion)
    }
    
    /// Remove a member from the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(member: Member,
                from channel: Channel,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        remove(members: Set([member]), from: channel, completion)
    }
    
    /// Remove members from the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(members: Set<Member>,
                from channel: Channel,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        request(endpoint: .removeMembers(members, channel), completion)
    }
    
    // MARK: - User Ban
    
    /// Ban a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - channel: a channel.
    ///   - timeoutInMinutes: for a timeout in minutes.
    ///   - completion: an empty completion block.
    @discardableResult
    func ban(user: User,
             in channel: Channel,
             timeoutInMinutes: Int? = nil,
             reason: String? = nil,
             _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        let timeoutInMinutes = timeoutInMinutes ?? channel.banEnabling.timeoutInMinutes
        let reason = reason ?? channel.banEnabling.reason
        let userBan = UserBan(user: user, channel: channel, timeoutInMinutes: timeoutInMinutes, reason: reason)
        
        let completion = doBefore(completion) { [weak channel] _ in
            if timeoutInMinutes == nil {
                channel?.bannedUsers.append(user)
            }
        }
        
        return request(endpoint: .ban(userBan), completion)
    }
    
    // MARK: - Invite Requests
    
    /// Invite a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func invite(member: Member, to channel: Channel, _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        invite(members: [member], to: channel, completion)
    }
    
    /// Invite members to the channel.
    /// - Parameters:
    ///   - members: a list of members.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func invite(members: Set<Member>,
                to channel: Channel,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> Cancellable {
        request(endpoint: .invite(members, channel), completion)
    }
    
    /// Accept an invite to the channel.
    ///
    /// - Parameters:
    ///   - channel: a channel.
    ///   - message: an additional message.
    ///   - completion: a completion block with `ChannelInviteResponse`.
    @discardableResult
    func acceptInvite(for channel: Channel,
                      with message: Message? = nil,
                      _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> Cancellable {
        sendInviteAnswer(accept: true, reject: nil, message: message, channel: channel, completion)
    }
    
    /// Reject an invite to the channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - message: an additional message.
    ///   - completion: a completion block with `ChannelInviteResponse`.
    @discardableResult
    func rejectInvite(for channel: Channel,
                      with message: Message? = nil,
                      _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> Cancellable {
        sendInviteAnswer(accept: nil, reject: true, message: message, channel: channel, completion)
    }
    
    private func sendInviteAnswer(accept: Bool?,
                                  reject: Bool?,
                                  message: Message?,
                                  channel: Channel,
                                  _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> Cancellable {
        let answer = ChannelInviteAnswer(channel: channel, accept: accept, reject: reject, message: message)
        return request(endpoint: .inviteAnswer(answer), completion)
    }
    
    // MARK: - Uploading
    
    /// Upload an image to the channel.
    /// - Parameters:
    ///   - data: an image data.
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - channel: a channel.
    ///   - progress: a progress block with `Client.Progress`.
    ///   - completion: a completion block with `Client.Completion<URL>`.
    @discardableResult
    func sendImage(data: Data,
                   fileName: String,
                   mimeType: String,
                   channel: Channel,
                   progress: @escaping Client.Progress,
                   completion: @escaping Client.Completion<URL>) -> Cancellable {
        sendFile(endpoint: .sendImage(data, fileName, mimeType, channel), progress: progress, completion: completion)
    }
    
    /// Upload a file to the channel.
    /// - Parameters:
    ///   - data: a file data.
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - channel: a channel.
    ///   - progress: a progress block with `Client.Progress`.
    ///   - completion: a completion block with `Client.Completion<URL>`.
    @discardableResult
    func sendFile(data: Data,
                  fileName: String,
                  mimeType: String,
                  channel: Channel,
                  progress: @escaping Client.Progress,
                  completion: @escaping Client.Completion<URL>) -> Cancellable {
        sendFile(endpoint: .sendFile(data, fileName, mimeType, channel), progress: progress, completion: completion)
    }
    
    private func sendFile(endpoint: Endpoint,
                          progress: @escaping Client.Progress,
                          completion: @escaping Client.Completion<URL>) -> Cancellable {
        request(endpoint: endpoint, progress: progress) { (result: Result<FileUploadResponse, ClientError>) in
            completion(result.map(to: \.file))
        }
    }
    
    /// Delete an image with a given URL.
    /// - Parameters:
    ///   - url: an image URL.
    ///   - channel: a channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func deleteImage(url: URL, channel: Channel, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        request(endpoint: .deleteImage(url, channel), completion)
    }
    
    /// Delete a file with a given URL.
    /// - Parameters:
    ///   - url: a file URL.
    ///   - channel: a channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func deleteFile(url: URL, channel: Channel, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        request(endpoint: .deleteFile(url, channel), completion)
    }
} // swiftlint:disable:this file_length
