//
//  Channel+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 07/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Requests

public extension Channel {
    
    /// Create a channel.
    ///
    /// - Parameter options: a query options for a new channel, e.g. watch channel events, presence of users.
    /// - Returns: an observable channel response.
    func create(options: QueryOptions = []) -> Observable<ChannelResponse> {
        return query(options: options)
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
        
        return Client.shared.rx.connectedRequest(endpoint: .channel(channelQuery))
            .do(onNext: { channelResponse in
                if options.contains(.state) {
                    if let database = Client.shared.database {
                        database.add(messages: channelResponse.messages, for: channelResponse.channel)
                        database.set(members: channelResponse.members, for: channelResponse.channel)
                    }
                }
            })
    }
    
    /// Delete the channel.
    ///
    /// - Returns: an observable completion.
    func delete() -> Observable<ChannelDeletedResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .deleteChannel(self))
    }
    
    /// Send a new message or update with a given `message.id`.
    ///
    /// - Parameter message: a message.
    /// - Returns: a created/updated message response.
    func send(message: Message) -> Observable<MessageResponse> {
        var request: Observable<MessageResponse> = Client.shared.rx.request(endpoint: .sendMessage(message, self))
        
        if !isActive {
            request = query().flatMap { _ in request }
        }
        
        return Client.shared.connectedRequest(request)
    }
    
    /// Send a message action for a given ephemeral message.
    ///
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
            .do(onNext: { _ in Client.shared.logger?.log("🎫", eventType.rawValue) }))
    }
}

// MARK: - Invite Requests

public extension Channel {
    
    /// Send invites to users.
    ///
    /// - Parameter userIds: a list of user Ids.
    /// - Returns: an observable channel response.
    func sendInvites(to users: [User]) -> Observable<ChannelResponse> {
        users.forEach { addInvitedUser($0) }    
        return query()
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
    ///   - reactionType: a reaction type, e.g. like.
    ///   - message: a message.
    /// - Returns: an observable message response.
    func addReaction(_ reactionType: ReactionType, to message: Message) -> Observable<MessageResponse> {
        return message.addReaction(reactionType)
    }
    
    /// Delete a reaction to the message.
    ///
    /// - Parameters:
    ///     - reactionType: a reaction type, e.g. like.
    ///     - message: a message.
    /// - Returns: an observable message response.
    func deleteReaction(_ reactionType: ReactionType, from message: Message) -> Observable<MessageResponse> {
        return message.deleteReaction(reactionType)
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
    let message: Message
    /// A reaction.
    let reaction: Reaction?
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
