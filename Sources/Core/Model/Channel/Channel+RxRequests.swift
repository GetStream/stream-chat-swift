//
//  Channel+RxRequests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 07/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

extension Channel: ReactiveCompatible {}

public extension Reactive where Base == Channel {
    
    // MARK: Channel Requests
    
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
            base.members.insert(user.asMember)
        }
        
        let channelQuery = ChannelQuery(channel: base, members: base.members, pagination: pagination, options: options)
        return Client.shared.rx.channel(query: channelQuery)
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
        return Client.shared.rx.request(endpoint: .stopWatching(base)).map { (_: EmptyData) in Void() }
    }
    
    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - user: the current user.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    func hide(for user: User? = User.current, clearHistory: Bool = false) -> Observable<Void> {
        return Client.shared.rx.connectedRequest(endpoint: .hideChannel(base, user, clearHistory))
            .flatMapLatest { (_: EmptyData) in self.stopWatching() }
    }
    
    /// Removes the hidden status for a channel.
    /// - Parameter user: the current user.
    func show(for user: User? = User.current) -> Observable<Void> {
        guard let user = user else {
            return .empty()
        }
        
        return Client.shared.rx.connectedRequest(endpoint: .showChannel(base, user))
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
            base.name = name
        }
        
        if let imageURL = imageURL {
            changed = true
            base.imageURL = imageURL
        }
        
        if let extraData = extraData {
            changed = true
            base.extraData = ExtraData(extraData)
        }
        
        guard changed else {
            return .empty()
        }
        
        return Client.shared.rx.connectedRequest(endpoint: .updateChannel(.init(data: .init(base))))
    }
    
    /// Delete the channel.
    ///
    /// - Returns: an observable completion.
    func delete() -> Observable<Channel> {
        let request: Observable<ChannelDeletedResponse> = Client.shared.rx.connectedRequest(endpoint: .deleteChannel(base))
        return request.map { $0.channel }
    }
    
    // MARK: - Message
    
    /// Send a new message or update with a given `message.id`.
    /// - Parameter message: a message.
    /// - Returns: a created/updated message response.
    func send(message: Message) -> Observable<MessageResponse> {
        let sendMessageRequest: Observable<MessageResponse> = Client.shared.rx.request(endpoint: .sendMessage(message, base))
        
        let request = (base.isActive ? sendMessageRequest : query().flatMapLatest { _ in sendMessageRequest })
            .flatMapLatest({ [weak base] response -> Observable<MessageResponse> in
                if response.message.isBan {
                    if let currentUser = User.current, !currentUser.isBanned {
                        var user = currentUser
                        user.isBanned = true
                        Client.shared.user = user
                    }
                    
                    return .just(response)
                }
                
                guard let base = base else {
                    return .empty()
                }
                
                if base.config.readEventsEnabled {
                    return base.rx.markRead().map({ _ in response })
                }
                
                return .just(response)
            })
        
        return Client.shared.rx.connectedRequest(request)
    }
    
    /// Send a message action for a given ephemeral message.
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    /// - Returns: a result message.
    func send(action: Attachment.Action, for ephemeralMessage: Message) -> Observable<MessageResponse> {
        let endpoint = Endpoint.sendMessageAction(.init(channel: base, message: ephemeralMessage, action: action))
        return Client.shared.rx.connectedRequest(endpoint: endpoint)
    }
    
    /// Mark messages in the channel as read.
    ///
    /// - Returns: an observable event response.
    func markRead() -> Observable<Event> {
        guard base.config.readEventsEnabled else {
            return .empty()
        }
        
        Client.shared.logger?.log("🎫 Send Message Read. For a new message of the current user.")
        let request: Observable<EventResponse> = Client.shared.rx.request(endpoint: .markRead(base))
        return Client.shared.rx.connectedRequest(request.map({ $0.event }))
    }
    
    /// Send an event.
    ///
    /// - Parameter eventType: an event type.
    /// - Returns: an observable event.
    func send(eventType: EventType) -> Observable<Event> {
        let request: Observable<EventResponse> = Client.shared.rx.request(endpoint: .sendEvent(eventType, base))
        
        return Client.shared.rx.connectedRequest(request.map({ $0.event })
            .do(onNext: { _ in Client.shared.logger?.log("🎫 \(eventType.rawValue)") }))
    }
    
    // MARK: - Members
    
    /// Add a member to the channel.
    /// - Parameter member: a member.
    func add(_ member: Member) -> Observable<ChannelResponse> {
        return add(Set([member]))
    }
    
    /// Add members to the channel.
    /// - Parameter members: members.
    func add(_ members: Set<Member>) -> Observable<ChannelResponse> {
        var members = members
        
        base.members.forEach { existsMember in
            if let index = members.firstIndex(of: existsMember) {
                members.remove(at: index)
            }
        }
        
        return members.isEmpty ? .empty() : Client.shared.rx.connectedRequest(.addMembers(members, base))
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
        
        base.members.forEach { existsMember in
            if members.firstIndex(of: existsMember) != nil {
                existsMembers.insert(existsMember)
            }
        }
        
        return existsMembers.isEmpty ? .empty() : Client.shared.rx.connectedRequest(.removeMembers(members, base))
    }
    
    // MARK: User Ban
    
    /// Ban a user.
    /// - Parameter user: a user.
    func ban(user: User, timeoutInMinutes: Int? = nil, reason: String? = nil) -> Observable<Void> {
        if base.isBanned(user) || !base.banEnabling.isEnabled(for: base) {
            return .empty()
        }
        
        let timeoutInMinutes = timeoutInMinutes ?? base.banEnabling.timeoutInMinutes
        let reason = reason ?? base.banEnabling.reason
        let userBan = UserBan(user: user, channel: base, timeoutInMinutes: timeoutInMinutes, reason: reason)
        let request: Observable<EmptyData> = Client.shared.rx.connectedRequest(.ban(userBan))
        
        return request.map({ _ in Void() })
            .do(onNext: { [weak base] in
                if timeoutInMinutes == nil {
                    base?.bannedUsers.append(user)
                }
            })
    }
    
    // MARK: - Invite Requests
    
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
        
        for member in members where !base.members.contains(member) {
            membersSet.insert(member)
        }
        
        guard !membersSet.isEmpty else {
            return .empty()
        }
        
        return Client.shared.rx.connectedRequest(endpoint: .invite(membersSet, base))
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
        let answer = ChannelInviteAnswer(channel: base, accept: accept, reject: reject, message: message)
        return Client.shared.rx.connectedRequest(endpoint: .inviteAnswer(answer))
    }
    
    // MARK: - File Requests
    
    /// Upload an image to the channel.
    ///
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    /// - Returns: an observable file upload response.
    func sendImage(fileName: String, mimeType: String, imageData: Data) -> Observable<ProgressResponse<URL>> {
        return sendFile(endpoint: .sendImage(fileName, mimeType, imageData, base))
    }
    
    /// Upload a file to the channel.
    ///
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    /// - Returns: an observable file upload response.
    func sendFile(fileName: String, mimeType: String, fileData: Data) -> Observable<ProgressResponse<URL>> {
        return sendFile(endpoint: .sendFile(fileName, mimeType, fileData, base))
    }
    
    private func sendFile(endpoint: Endpoint) -> Observable<ProgressResponse<URL>> {
        let request: Observable<ProgressResponse<FileUploadResponse>> = Client.shared.rx.progressRequest(endpoint: endpoint)
        return Client.shared.rx.connectedRequest(request.map({ ($0.progress, $0.result?.file) }))
    }
    
    /// Delete an image with a given URL.
    ///
    /// - Parameter url: an image URL.
    /// - Returns: an empty observable result.
    func deleteImage(url: URL) -> Observable<Void> {
        return deleteFile(endpoint: .deleteImage(url, base))
    }
    
    /// Delete a file with a given URL.
    ///
    /// - Parameter url: a file URL.
    /// - Returns: an empty observable result.
    func deleteFile(url: URL) -> Observable<Void> {
        return deleteFile(endpoint: .deleteFile(url, base))
    }
    
    private func deleteFile(endpoint: Endpoint) -> Observable<Void> {
        let request: Observable<EmptyData> = Client.shared.rx.request(endpoint: endpoint)
        return Client.shared.rx.connectedRequest(request.map({ _ in Void() }))
    }
    
    // MARK: - Messages Requests
    
    /// Delete a message.
    ///
    /// - Parameter message: a message.
    /// - Returns: an observable message response.
    func delete(message: Message) -> Observable<MessageResponse> {
        return message.rx.delete()
    }
    
    /// Add a reaction to a message.
    ///
    /// - Parameters:
    ///   - reactionType: a reaction type, e.g. like.
    ///   - message: a message.
    /// - Returns: an observable message response.
    func addReaction(_ reactionType: ReactionType, to message: Message) -> Observable<MessageResponse> {
        return message.rx.addReaction(reactionType)
    }
    
    /// Delete a reaction to the message.
    ///
    /// - Parameters:
    ///     - reactionType: a reaction type, e.g. like.
    ///     - message: a message.
    /// - Returns: an observable message response.
    func deleteReaction(_ reactionType: ReactionType, from message: Message) -> Observable<MessageResponse> {
        return message.rx.deleteReaction(reactionType)
    }
    
    /// Send a request for reply messages.
    ///
    /// - Parameters:
    ///     - parentMessage: a parent message of replies.
    ///     - pagination: a pagination (see `Pagination`).
    /// - Returns: an observable message response.
    func replies(for parentMessage: Message, pagination: Pagination) -> Observable<[Message]> {
        return parentMessage.rx.replies(pagination: pagination)
    }
    
    /// Flag a message.
    ///
    /// - Parameter message: a message.
    /// - Returns: an observable flag message response.
    func flag(message: Message) -> Observable<FlagMessageResponse> {
        guard base.config.flagsEnabled else {
            return .empty()
        }
        
        return message.rx.flag()
    }
    
    /// Unflag a message.
    ///
    /// - Parameter message: a message.
    /// - Returns: an observable flag message response.
    func unflag(message: Message) -> Observable<FlagMessageResponse> {
        guard base.config.flagsEnabled else {
            return .empty()
        }
        
        return message.rx.unflag()
    }
}
