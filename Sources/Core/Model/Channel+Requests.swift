//
//  Channel+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 07/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: Channel Requests

public extension Channel {
    
    /// Create a channel.
    /// - Returns: an observable channel response.
    func create() -> Observable<ChannelResponse> {
        return query()
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc
    ///
    /// - Parameters:
    ///   - pagination: a pagination for messages (see `Pagination`).
    ///   - options: a query options. All by default (see `QueryOptions`).
    /// - Returns: an observable channel response.
    func query(pagination: Pagination = .none, options: QueryOptions = []) -> Observable<ChannelResponse> {
        if let user = User.current {
            members.insert(user.asMember)
        }
        
        let channelQuery = ChannelQuery(channel: self, members: members, pagination: pagination, options: options)
        return Client.shared.channel(query: channelQuery)
    }
    
    /// Loads the initial channel state and watches for changes.
    /// - Parameter options: an additional channel options, e.g. `.presence`
    /// - Returns: an observable channel response.
    func watch(options: QueryOptions = []) -> Observable<ChannelResponse> {
        var options = options
        
        if !options.contains(.watch) {
            options = options.union(.watch)
        }
        
        return query(options: .watch)
    }
    
    /// Stop watching the channel for a state changes.
    func stopWatching() -> Observable<Void> {
        return Client.shared.rx.request(endpoint: .stopWatching(self))
            .map { (_: EmptyData) in Void() }
    }
    
    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - user: the current user.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    func hide(for user: User? = User.current, clearHistory: Bool = false) -> Observable<Void> {
        return Client.shared.rx.connectedRequest(endpoint: .hideChannel(self, user, clearHistory))
            .flatMapLatest { (_: EmptyData) in self.stopWatching() }
    }
    
    /// Removes the hidden status for a channel.
    /// - Parameter user: the current user.
    func show(for user: User? = User.current) -> Observable<Void> {
        guard let user = user else {
            return .empty()
        }
        
        return Client.shared.rx.connectedRequest(endpoint: .showChannel(self, user))
            .map { (_: EmptyData) in Void() }
    }
    
    /// Update channel data.
    /// - Parameter name: a channel name.
    /// - Parameter imageURL: an image URL.
    /// - Parameter extraData: a custom extra data.
    func update(name: String? = nil, imageURL: URL? = nil, extraData: Codable? = nil) -> Observable<ChannelResponse> {
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
            return .empty()
        }
        
        return Client.shared.rx.connectedRequest(endpoint: .updateChannel(.init(data: .init(self))))
    }
    
    /// Delete the channel.
    ///
    /// - Returns: an observable completion.
    func delete() -> Observable<ChannelDeletedResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .deleteChannel(self))
    }
}
    
// MARK: - Message

public extension Channel {
    
    /// Send a new message or update with a given `message.id`.
    /// - Parameter message: a message.
    /// - Returns: a created/updated message response.
    func send(message: Message) -> Observable<MessageResponse> {
        var request: Observable<MessageResponse> = Client.shared.rx.request(endpoint: .sendMessage(message, self))
        
        if !isActive {
            request = query().flatMapLatest { _ in request }
        }
        
        request = request
            .flatMapLatest({ [weak self] response -> Observable<MessageResponse> in
                if response.message.isBan {
                    if let currentUser = User.current, !currentUser.isBanned {
                        var user = currentUser
                        user.isBanned = true
                        Client.shared.user = user
                    }
                    
                    return .just(response)
                }
                
                guard let self = self else {
                    return .empty()
                }
                
                if self.config.readEventsEnabled {
                    return self.markRead().map({ _ in response })
                }
                
                return .just(response)
            })
        
        return Client.shared.connectedRequest(request)
    }
    
    /// Send a message action for a given ephemeral message.
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    /// - Returns: a result message.
    func send(action: Attachment.Action, for ephemeralMessage: Message) -> Observable<MessageResponse> {
        let endpoint = Endpoint.sendMessageAction(.init(channel: self, message: ephemeralMessage, action: action))
        return Client.shared.rx.connectedRequest(endpoint: endpoint)
    }
    
    /// Mark messages in the channel as readed.
    ///
    /// - Returns: an observable event response.
    func markRead() -> Observable<Event> {
        guard config.readEventsEnabled else {
            return .empty()
        }
        
        Client.shared.logger?.log("🎫 Send Message Read. For a new message of the current user.")
        let request: Observable<EventResponse> = Client.shared.rx.request(endpoint: .markRead(self))
        return Client.shared.connectedRequest(request.map({ $0.event }))
    }
    
    /// Send an event.
    ///
    /// - Parameter eventType: an event type.
    /// - Returns: an observable event.
    func send(eventType: EventType) -> Observable<Event> {
        let request: Observable<EventResponse> = Client.shared.rx.request(endpoint: .sendEvent(eventType, self))
        
        return Client.shared.connectedRequest(request.map({ $0.event })
            .do(onNext: { _ in Client.shared.logger?.log("🎫 \(eventType.rawValue)") }))
    }
}

// MARK: - Members

public extension Channel {
    
    /// Add a member to the channel.
    /// - Parameter member: a member.
    func add(_ member: Member) -> Observable<ChannelResponse> {
        return add(Set([member]))
    }
    
    /// Add members to the channel.
    /// - Parameter members: members.
    func add(_ members: Set<Member>) -> Observable<ChannelResponse> {
        var members = members
        
        self.members.forEach { existsMember in
            if let index = members.firstIndex(of: existsMember) {
                members.remove(at: index)
            }
        }
        
        return members.isEmpty ? .empty() : Client.shared.connectedRequest(.addMembers(members, self))
    }
    
    /// Remove a member from the channel.
    /// - Parameter member: a member.
    func remove(_ member: Member) -> Observable<ChannelResponse> {
        return remove(Set([member]))
    }
    
    /// Remove members from the channel.
    /// - Parameter members: members.
    func remove(_ members: Set<Member>) -> Observable<ChannelResponse> {
        var existsMembers = Set<Member>()
        
        self.members.forEach { existsMember in
            if members.firstIndex(of: existsMember) != nil {
                existsMembers.insert(existsMember)
            }
        }
        
        return existsMembers.isEmpty ? .empty() : Client.shared.connectedRequest(.removeMembers(members, self))
    }
    
    // MARK: User Ban
    
    /// Check is the user is banned for the channel.
    /// - Parameter user: a user.
    func isBanned(_ user: User) -> Bool {
        return bannedUsers.contains(user)
    }
    
    /// Ban a user.
    /// - Parameter user: a user.
    func ban(user: User, timeoutInMinutes: Int? = nil, reason: String? = nil) -> Observable<Void> {
        if isBanned(user) || !banEnabling.isEnabled(for: self) {
            return .empty()
        }
        
        let timeoutInMinutes = timeoutInMinutes ?? banEnabling.timeoutInMinutes
        let reason = reason ?? banEnabling.reason
        let userBan = UserBan(user: user, channel: self, timeoutInMinutes: timeoutInMinutes, reason: reason)
        let request: Observable<EmptyData> = Client.shared.connectedRequest(.ban(userBan))
        
        return request.map({ _ in Void() })
            .do(onNext: { [weak self] in
                if timeoutInMinutes == nil {
                    self?.bannedUsers.append(user)
                }
            })
    }
}

// MARK: - Invite Requests

public extension Channel {
    
    /// Invite a member to the channel.
    /// - Parameter member: a member.
    /// - Returns: an observable channel response.
    func invite(_ member: Member) -> Observable<ChannelResponse> {
        return invite([member])
    }
    
    /// Invite members to the channel.
    /// - Parameter members: a list of members.
    /// - Returns: an observable channel response.
    func invite(_ members: [Member]) -> Observable<ChannelResponse> {
        var membersSet = Set<Member>()
        
        for member in members where !self.members.contains(member) {
            membersSet.insert(member)
        }
        
        guard !membersSet.isEmpty else {
            return .empty()
        }
        
        return Client.shared.rx.connectedRequest(endpoint: .invite(membersSet, self))
    }
    
    /// Accept an invite to the channel.
    ///
    /// - Parameter message: an additional message.
    /// - Returns: an observable channel response.
    func acceptInvite(with message: Message? = nil) -> Observable<ChannelInviteResponse> {
        return sendInviteAnswer(accept: true, reject: nil, message: message)
    }
    
    /// Reject an invite to the channel.
    ///
    /// - Parameter message: an additional message.
    /// - Returns: an observable channel response.
    func rejectInvite(with message: Message? = nil) -> Observable<ChannelInviteResponse> {
        return sendInviteAnswer(accept: nil, reject: true, message: message)
    }
    
    private func sendInviteAnswer(accept: Bool?, reject: Bool?, message: Message?) -> Observable<ChannelInviteResponse> {
        let answer = ChannelInviteAnswer(channel: self, accept: accept, reject: reject, message: message)
        return Client.shared.rx.connectedRequest(endpoint: .inviteAnswer(answer))
    }
}

// MARK: - File Requests

public extension Channel {
    
    /// Upload an image to the channel.
    ///
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    /// - Returns: an observable file upload response.
    func sendImage(fileName: String, mimeType: String, imageData: Data) -> Observable<ProgressResponse<URL>> {
        return sendFile(endpoint: .sendImage(fileName, mimeType, imageData, self))
    }
    
    /// Upload a file to the channel.
    ///
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    /// - Returns: an observable file upload response.
    func sendFile(fileName: String, mimeType: String, fileData: Data) -> Observable<ProgressResponse<URL>> {
        return sendFile(endpoint: .sendFile(fileName, mimeType, fileData, self))
    }
    
    private func sendFile(endpoint: Endpoint) -> Observable<ProgressResponse<URL>> {
        let request: Observable<ProgressResponse<FileUploadResponse>> = Client.shared.rx.progressRequest(endpoint: endpoint)
        return Client.shared.connectedRequest(request.map({ ($0.progress, $0.result?.file) }))
    }
    
    /// Delete an image with a given URL.
    ///
    /// - Parameter url: an image URL.
    /// - Returns: an empty observable result.
    func deleteImage(url: URL) -> Observable<Void> {
        return deleteFile(endpoint: .deleteImage(url, self))
    }
    
    /// Delete a file with a given URL.
    ///
    /// - Parameter url: a file URL.
    /// - Returns: an empty observable result.
    func deleteFile(url: URL) -> Observable<Void> {
        return deleteFile(endpoint: .deleteFile(url, self))
    }
    
    private func deleteFile(endpoint: Endpoint) -> Observable<Void> {
        let request: Observable<EmptyData> = Client.shared.rx.request(endpoint: endpoint)
        return Client.shared.connectedRequest(request.map({ _ in Void() }))
    }
}

// MARK: - Messages Requests

public extension Channel {
    
    /// Delete a message.
    ///
    /// - Parameter message: a message.
    /// - Returns: an observable message response.
    func delete(message: Message) -> Observable<MessageResponse> {
        return message.delete()
    }
    
    /// Add a reaction to a message.
    ///
    /// - Parameters:
    ///   - type: a reaction type.
    ///   - score: a reaction score, e.g. `.cumulative` it could be more then 1.
    ///   - extraData: a reaction extra data.
    ///   - message: a message for the reacction.
    func addReaction(type: ReactionType,
                     score: Int = 1,
                     extraData: Codable? = nil,
                     to message: Message) -> Observable<MessageResponse> {
        return message.addReaction(type: type, score: score, extraData: extraData)
    }
    
    /// Delete a reaction to the message.
    ///
    /// - Parameters:
    ///     - type: a reaction type, e.g. like.
    ///     - message: a message.
    /// - Returns: an observable message response.
    func deleteReaction(type: ReactionType, from message: Message) -> Observable<MessageResponse> {
        return message.deleteReaction(type: type)
    }
    
    /// Send a request for reply messages.
    ///
    /// - Parameters:
    ///     - parentMessage: a parent message of replies.
    ///     - pagination: a pagination (see `Pagination`).
    /// - Returns: an observable message response.
    func replies(for parentMessage: Message, pagination: Pagination) -> Observable<[Message]> {
        return parentMessage.replies(pagination: pagination)
    }
    
    /// Flag a message.
    ///
    /// - Parameter message: a message.
    /// - Returns: an observable flag message response.
    func flag(message: Message) -> Observable<FlagMessageResponse> {
        guard config.flagsEnabled else {
            return .empty()
        }
        
        return message.flag()
    }
    
    /// Unflag a message.
    ///
    /// - Parameter message: a message.
    /// - Returns: an observable flag message response.
    func unflag(message: Message) -> Observable<FlagMessageResponse> {
        guard config.flagsEnabled else {
            return .empty()
        }
        
        return message.unflag()
    }
}

// MARK: - Supporting structs

/// A message response.
public struct MessageResponse: Decodable {
    /// A message.
    public let message: Message
    /// A reaction.
    public let reaction: Reaction?
}

/// An event response.
public struct EventResponse: Decodable {
    /// An event (see `Event`).
    public let event: Event
}

/// A file upload response.
public struct FileUploadResponse: Decodable {
    /// An uploaded file URL.
    public let file: URL
}

struct HiddenChannelRequest: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case clearHistory = "clear_history"
    }
    
    let userId: String
    let clearHistory: Bool
}

/// A hidden channel event response.
public struct HiddenChannelResponse: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case cid
        case clearHistory = "clear_history"
        /// A created date.
        case created = "created_at"
    }
    
    /// A channel type + id.
    public let cid: ChannelId
    /// The message history was cleared.
    public let clearHistory: Bool
    /// An event created date.
    public let created: Date
}
