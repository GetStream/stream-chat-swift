//
//  Channel+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Channel {
    
    // MARK: Channel Requests
    
    /// Create a channel.
    /// - Parameter completion: a completion block with `ChannelResponse`.
    @discardableResult
    func create(_ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        return query(completion)
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc
    /// - Parameters:
    ///   - pagination: a pagination for messages (see `Pagination`).
    ///   - options: a query options. All by default (see `QueryOptions`), e.g. `.watch`.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func query(pagination: Pagination = .none,
               options: QueryOptions = [],
               client: Client = .shared,
               _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        let channelQuery = ChannelQuery(channel: self, pagination: pagination, options: options)
        var fullCompletion = completion
        
        if options.contains(.state) {
            fullCompletion = doAfter(completion) { response in
                response.channel.add(messagesToDatabase: response.messages)
            }
        }
        
        return client.request(endpoint: .channel(channelQuery), fullCompletion)
    }
    
    /// Loads the initial channel state and watches for changes.
    /// - Parameters:
    ///   - options: an additional channel options, e.g. `.presence`
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func watch(options: QueryOptions = [], _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        var options = options
        
        if !options.contains(.watch) {
            options = options.union(.watch)
        }
        
        return query(options: .watch, completion)
    }
    
    /// Stop watching the channel for a state changes.
    /// - Parameter completion: an empty completion block.
    @discardableResult
    func stopWatching(client: Client = .shared, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        return client.request(endpoint: .stopWatching(self), completion)
    }
    
    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - user: the current user.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func hide(for user: User = User.current,
              clearHistory: Bool = false,
              client: Client = .shared,
              _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        let completion = doAfter(completion) { [weak self] _ in
            self?.stopWatching()
        }
        
        return client.request(endpoint: .hideChannel(self, user, clearHistory), completion)
    }
    
    /// Removes the hidden status for a channel.
    /// - Parameters:
    ///   - user: the current user.
    ///   - completion: an empty completion block.
    @discardableResult
    func show(for user: User = User.current,
              client: Client = .shared,
              _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        return client.request(endpoint: .showChannel(self, user), completion)
    }
    
    /// Update channel data.
    /// - Parameters:
    ///   - name: a channel name.
    ///   - imageURL: an image URL.
    ///   - extraData: a custom extra data.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func update(name: String? = nil,
                imageURL: URL? = nil,
                extraData: Codable? = nil,
                client: Client = .shared,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        var changed = false
        
        if let name = name, !name.isEmpty {
            changed = true
            self.name = name
        }
        
        if let imageURL = imageURL {
            changed = true
            self.imageURL = imageURL
        }
        
        if let extraData = extraData {
            changed = true
            self.extraData = ExtraData(extraData)
        }
        
        guard changed else {
            completion(.success(.init(channel: self)))
            return .empty
        }
        
        return client.request(endpoint: .updateChannel(.init(data: .init(self))), completion)
    }
    
    /// Delete the channel.
    /// - Parameter completion: a completion block with `Channel`.
    @discardableResult
    func delete(client: Client = .shared, _ completion: @escaping Client.Completion<Channel>) -> URLSessionTask {
        return client.request(endpoint: .deleteChannel(self)) { (result: Result<ChannelDeletedResponse, ClientError>) in
            completion(result.map({ $0.channel }))
        }
    }
    
    // MARK: - Message
    
    /// Send a new message or update with a given `message.id`.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func send(message: Message,
              client: Client = .shared,
              _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        let completion = doAfter(completion) { [unowned client] response in
            if response.message.isBan {
                if !client.user.isBanned {
                    var user = client.user
                    user.isBanned = true
                    client.user = user
                }
            }
        }
        
        if id.isEmpty {
            completion(.failure(.emptyChannelId))
            return .empty
        }
        
        return client.request(endpoint: .sendMessage(message, self), completion)
    }
    
    /// Send a message action for a given ephemeral message.
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func send(action: Attachment.Action,
              for ephemeralMessage: Message,
              client: Client = .shared,
              _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        let endpoint = Endpoint.sendMessageAction(.init(channel: self, message: ephemeralMessage, action: action))
        return client.request(endpoint: endpoint, completion)
    }
    
    /// Mark messages in the channel as read.
    /// - Parameter completion: a completion block with `Event`.
    @discardableResult
    func markRead(client: Client = .shared, _ completion: @escaping Client.Completion<Event>) -> URLSessionTask {
        guard config.readEventsEnabled else {
            return .empty
        }
        
        client.logger?.log("🎫 Send Message Read. For a new message of the current user.")
        
        return client.request(endpoint: .markRead(self)) { (result: Result<EventResponse, ClientError>) in
            completion(result.map({ $0.event }))
        }
    }
    
    /// Send an event.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - completion: a completion block with `Event`.
    @discardableResult
    func send(eventType: EventType,
              client: Client = .shared,
              _ completion: @escaping Client.Completion<Event>) -> URLSessionTask {
        return client
            .request(endpoint: .sendEvent(eventType, self)) { [unowned client] (result: Result<EventResponse, ClientError>) in
                client.logger?.log("🎫 \(eventType.rawValue)")
                completion(result.map({ $0.event }))
        }
    }
    
    /// Delete a message.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func delete(message: Message, _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        return message.delete(completion)
    }
    
    /// Flag a message.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func flag(message: Message, _ completion: @escaping Client.Completion<FlagMessageResponse>) -> URLSessionTask {
        guard config.flagsEnabled else {
            completion(.success(.init(messageId: message.id, created: Date(), updated: Date())))
            return .empty
        }
        
        return message.flag(completion)
    }
    
    /// Unflag a message.
    /// - Parameters:
    ///   - message: a message.
    ///   - completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func unflag(message: Message, _ completion: @escaping Client.Completion<FlagMessageResponse>) -> URLSessionTask {
        guard config.flagsEnabled else {
            completion(.success(.init(messageId: message.id, created: Date(), updated: Date())))
            return .empty
        }
        
        return message.unflag(completion)
    }
    
    // MARK: - Members
    
    /// Add a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(_ member: Member, _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        return add(Set([member]), completion)
    }
    
    /// Add members to the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func add(_ members: Set<Member>,
             client: Client = .shared,
             _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        var members = members
        
        self.members.forEach { existsMember in
            if let index = members.firstIndex(of: existsMember) {
                members.remove(at: index)
            }
        }
        
        if members.isEmpty {
            completion(.success(.init(channel: self)))
            return .empty
        }
        
        return client.request(endpoint: .addMembers(members, self), completion)
    }
    
    /// Remove a member from the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(_ member: Member, _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        return remove(Set([member]), completion)
    }
    
    /// Remove members from the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func remove(_ members: Set<Member>,
                client: Client = .shared,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        var existsMembers = Set<Member>()
        
        self.members.forEach { existsMember in
            if members.firstIndex(of: existsMember) != nil {
                existsMembers.insert(existsMember)
            }
        }
        
        if existsMembers.isEmpty {
            completion(.success(.init(channel: self)))
            return .empty
        }
        
        return client.request(endpoint: .removeMembers(members, self), completion)
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
             client: Client = .shared,
             _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        if isBanned(user) || !banEnabling.isEnabled(for: self) {
            completion(.success(.empty))
            return .empty
        }
        
        let timeoutInMinutes = timeoutInMinutes ?? banEnabling.timeoutInMinutes
        let reason = reason ?? banEnabling.reason
        let userBan = UserBan(user: user, channel: self, timeoutInMinutes: timeoutInMinutes, reason: reason)
        
        let completion = doBefore(completion) { [weak self] _ in
            if timeoutInMinutes == nil {
                self?.bannedUsers.append(user)
            }
        }
        
        return client.request(endpoint: .ban(userBan), completion)
    }
    
    // MARK: - Invite Requests
    
    /// Invite a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func invite(_ member: Member, _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        return invite([member], completion)
    }
    
    /// Invite members to the channel.
    /// - Parameters:
    ///   - members: a list of members.
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func invite(_ members: [Member],
                client: Client = .shared,
                _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        var membersSet = Set<Member>()
        
        for member in members where !self.members.contains(member) {
            membersSet.insert(member)
        }
        
        guard !membersSet.isEmpty else {
            completion(.success(.init(channel: self)))
            return .empty
        }
        
        return client.request(endpoint: .invite(membersSet, self), completion)
    }
    
    /// Accept an invite to the channel.
    ///
    /// - Parameters:
    ///   - message: an additional message.
    ///   - completion: a completion block with `ChannelInviteResponse`.
    @discardableResult
    func acceptInvite(with message: Message? = nil,
                      client: Client = .shared,
                      _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> URLSessionTask {
        return sendInviteAnswer(accept: true, reject: nil, message: message, client: client, completion)
    }
    
    /// Reject an invite to the channel.
    /// - Parameters:
    ///   - message: an additional message.
    ///   - completion: a completion block with `ChannelInviteResponse`.
    @discardableResult
    func rejectInvite(with message: Message? = nil,
                      client: Client = .shared,
                      _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> URLSessionTask {
        return sendInviteAnswer(accept: nil, reject: true, message: message, client: client, completion)
    }
    
    private func sendInviteAnswer(accept: Bool?,
                                  reject: Bool?,
                                  message: Message?,
                                  client: Client,
                                  _ completion: @escaping Client.Completion<ChannelInviteResponse>) -> URLSessionTask {
        let answer = ChannelInviteAnswer(channel: self, accept: accept, reject: reject, message: message)
        return client.request(endpoint: .inviteAnswer(answer), completion)
    }
    
    // MARK: - File Requests
    
    /// Upload an image to the channel.
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - completion: a completion block with `ProgressResponse<URL>`.
    @discardableResult
    func sendImage(fileName: String,
                   mimeType: String,
                   imageData: Data,
                   client: Client = .shared,
                   _ progress: @escaping Client.Progress,
                   _ completion: @escaping Client.Completion<URL>) -> URLSessionTask {
        return sendFile(endpoint: .sendImage(fileName, mimeType, imageData, self), client: client, progress, completion)
    }
    
    /// Upload a file to the channel.
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - completion: a completion block with `ProgressResponse<URL>`.
    @discardableResult
    func sendFile(fileName: String,
                  mimeType: String,
                  fileData: Data,
                  client: Client = .shared,
                  _ progress: @escaping Client.Progress,
                  _ completion: @escaping Client.Completion<URL>) -> URLSessionTask {
        return sendFile(endpoint: .sendFile(fileName, mimeType, fileData, self), client: client, progress, completion)
    }
    
    private func sendFile(endpoint: Endpoint,
                          client: Client,
                          _ progress: @escaping Client.Progress,
                          _ completion: @escaping Client.Completion<URL>) -> URLSessionTask {
        return client.request(endpoint: endpoint, progress) { (result: Result<FileUploadResponse, ClientError>) in
            completion(result.map({ $0.file }))
        }
    }
    
    /// Delete an image with a given URL.
    /// - Parameters:
    ///   - url: an image URL.
    ///   - completion: an empty completion block.
    @discardableResult
    func deleteImage(url: URL,
                     client: Client = .shared,
                     _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        return client.request(endpoint: .deleteImage(url, self), completion)
    }
    
    /// Delete a file with a given URL.
    /// - Parameters:
    ///   - url: a file URL.
    ///   - completion: an empty completion block.
    @discardableResult
    func deleteFile(url: URL,
                    client: Client = .shared,
                    _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        return client.request(endpoint: .deleteFile(url, self), completion)
    }
}
