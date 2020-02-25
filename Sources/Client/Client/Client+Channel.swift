//
//  Client+Channel.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 04/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Channel Requests

public extension Client {
    
    /// Create a channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func create(channel: Channel, _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        queryChannel(channel, completion)
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc.
    /// Creates a `ChannelQuery` with given parameters and call `queryChannel` with it.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - pagination: a pagination for messages (see `Pagination`).
    ///   - options: a query options. All by default (see `QueryOptions`), e.g. `.watch`.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func queryChannel(_ channel: Channel,
                      pagination: Pagination = .none,
                      options: QueryOptions = [],
                      _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        queryChannel(query: .init(channel: channel, pagination: pagination, options: options), completion)
    }
    
    /// Requests for a channel data, e.g. messages, members, read states, etc.
    /// - Parameters:
    ///   - query: a channel query.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func queryChannel(query: ChannelQuery, _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        channelsAtomic.flush()
        var modifiedCompletion = completion
        
        if query.options.contains(.watch) || query.options.contains(.presence) {
            modifiedCompletion = { [unowned self] result in
                if let channel = result.value?.channel {
                    self.channelsAtomic.add(channel, key: channel.cid)
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
               _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        queryChannel(channel, options: options.union(.watch), completion)
    }
    
    /// Stop watching the channel for a state changes.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func stopWatching(channel: Channel, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
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
              _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
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
    func show(channel: Channel, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
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
                extraData: Codable? = nil,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
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
            channel.extraData = ExtraData(extraData)
        }
        
        guard changed else {
            completion(.success(.init(channel: channel)))
            return .empty
        }
        
        return request(endpoint: .updateChannel(.init(data: .init(channel))), completion)
    }
    
    /// Delete the channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - completion: a completion block with `Channel`.
    @discardableResult
    func delete(channel: Channel, _ completion: @escaping Client.Completion<Channel>) -> URLSessionTask {
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
    func send(message: Message, to channel: Channel, _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        let completion = doAfter(completion) { [unowned self] response in
            if response.message.isBan, !self.user.isBanned {
                self.userAtomic.isBanned = true
            }
        }
        
        if channel.id.isEmpty {
            completion(.failure(.emptyChannelId))
            return .empty
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
        return request(endpoint: .sendMessage(message, channel), completion)
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
              _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        request(endpoint: .sendMessageAction(.init(channel: channel, message: ephemeralMessage, action: action)), completion)
    }
    
    /// Mark messages in the channel as read.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - completion: a completion block with `Event`.
    @discardableResult
    func markRead(channel: Channel, _ completion: @escaping Client.Completion<Event>) -> URLSessionTask {
        guard channel.config.readEventsEnabled else {
            return .empty
        }
        
        logger?.log("🎫 Send Message Read. For a new message of the current user.")
        
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
    func send(eventType: EventType, to channel: Channel, _ completion: @escaping Client.Completion<Event>) -> URLSessionTask {
        request(endpoint: .sendEvent(eventType, channel)) { [unowned self] (result: Result<EventResponse, ClientError>) in
            self.logger?.log("🎫 \(eventType.rawValue)")
            completion(result.map(to: \.event))
        }
    }
    
    // MARK: - Members
    
    /// Add a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(member: Member, to channel: Channel, _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
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
             _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        request(endpoint: .addMembers(members, channel), completion)
    }
    
    /// Remove a member from the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(member: Member,
                from channel: Channel,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
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
                _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
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
             _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
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
    func invite(member: Member, to channel: Channel, _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
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
                _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
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
                      _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> URLSessionTask {
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
                      _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> URLSessionTask {
        sendInviteAnswer(accept: nil, reject: true, message: message, channel: channel, completion)
    }
    
    private func sendInviteAnswer(accept: Bool?,
                                   reject: Bool?,
                                   message: Message?,
                                   channel: Channel,
                                   _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> URLSessionTask {
        let answer = ChannelInviteAnswer(channel: channel, accept: accept, reject: reject, message: message)
        return request(endpoint: .inviteAnswer(answer), completion)
    }
    
    // MARK: - File Requests
    
    /// Upload an image to the channel.
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - imageData: an image data.
    ///   - channel: a channel.
    ///   - progress: a progress block with `Client.Progress`.
    ///   - completion: a completion block with `Client.Completion<URL>`.
    @discardableResult
    func sendImage(fileName: String,
                   mimeType: String,
                   imageData: Data,
                   to channel: Channel,
                   _ progress: @escaping Client.Progress,
                   _ completion: @escaping Client.Completion<URL>) -> URLSessionTask {
        sendFile(endpoint: .sendImage(fileName, mimeType, imageData, channel), progress, completion)
    }
    
    /// Upload a file to the channel.
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - fileData: a file data.
    ///   - channel: a channel.
    ///   - progress: a progress block with `Client.Progress`.
    ///   - completion: a completion block with `Client.Completion<URL>`.
    @discardableResult
    func sendFile(fileName: String,
                  mimeType: String,
                  fileData: Data,
                  to channel: Channel,
                  _ progress: @escaping Client.Progress,
                  _ completion: @escaping Client.Completion<URL>) -> URLSessionTask {
        sendFile(endpoint: .sendFile(fileName, mimeType, fileData, channel), progress, completion)
    }
    
    private func sendFile(endpoint: Endpoint,
                           _ progress: @escaping Client.Progress,
                           _ completion: @escaping Client.Completion<URL>) -> URLSessionTask {
        request(endpoint: endpoint, progress) { (result: Result<FileUploadResponse, ClientError>) in
            completion(result.map(to: \.file))
        }
    }
    
    /// Delete an image with a given URL.
    /// - Parameters:
    ///   - url: an image URL.
    ///   - channel: a channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func deleteImage(url: URL,
                     from channel: Channel,
                     _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        request(endpoint: .deleteImage(url, channel), completion)
    }
    
    /// Delete a file with a given URL.
    /// - Parameters:
    ///   - url: a file URL.
    ///   - channel: a channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func deleteFile(url: URL,
                    from channel: Channel,
                    _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        request(endpoint: .deleteFile(url, channel), completion)
    }
}
