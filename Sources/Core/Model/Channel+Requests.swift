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
    
    /// Requests channels with a given query.
    ///
    /// - Parameter query: a channels query (see `ChannelsQuery`).
    /// - Returns: a list of a channel response (see `ChannelResponse`).
    static func channels(query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        let request: Observable<ChannelsResponse> = Client.shared.rx.request(endpoint: .channels(query))
        return request.map { $0.channels }
    }
    
    /// Send a new message or update with a given `message.id`.
    ///
    /// - Parameter message: a message.
    /// - Returns: a created/updated message response.
    func send(message: Message) -> Observable<MessageResponse> {
        return Client.shared.rx.request(endpoint: .sendMessage(message, self))
    }
    
    /// Send a message action for a given ephemeral message.
    ///
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    /// - Returns: a result message.
    func send(action: Attachment.Action, for ephemeralMessage: Message) -> Observable<MessageResponse> {
        return Client.shared.rx.request(endpoint: .sendMessageAction(.init(channel: self, message: ephemeralMessage, action: action)))
    }
    
    /// Send a message read event.
    ///
    /// - Returns: an observable event response.
    func sendRead() -> Observable<Event> {
        let request: Observable<EventResponse> = Client.shared.rx.request(endpoint: .sendRead(self))
        return request.map { $0.event }
    }
    
    func send(eventType: EventType) -> Observable<Event> {
        let request: Observable<EventResponse> = Client.shared.rx.request(endpoint: .sendEvent(eventType, self))
        
        return request.map { $0.event }
            .do(onNext: { _ in Client.shared.logger?.log("🎫", eventType.rawValue) })
    }
    
    /// Upload an image to the channel.
    ///
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    /// - Returns: an observable file upload response.
    func sendImage(fileName: String, mimeType: String, imageData: Data) -> Observable<ProgressResponse<URL>> {
        let request: Observable<ProgressResponse<FileUploadResponse>> =
            Client.shared.rx.progressRequest(endpoint: .sendImage(fileName, mimeType, imageData, self))
        
        return request.map { ($0.progress, $0.result?.file) }
    }
    
    /// Upload a file to the channel.
    ///
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    /// - Returns: an observable file upload response.
    func sendFile(fileName: String, mimeType: String, fileData: Data) -> Observable<ProgressResponse<URL>> {
        let request: Observable<ProgressResponse<FileUploadResponse>> =
            Client.shared.rx.progressRequest(endpoint: .sendFile(fileName, mimeType, fileData, self))
        
        return request.map { ($0.progress, $0.result?.file) }
    }

    /// Request for a channel data, e.g. messages, members, read states, etc
    ///
    /// - Parameters:
    ///   - pagination: a pagination (see `Pagination`).
    ///   - queryOptions: a query options. All by default (see `QueryOptions`).
    /// - Returns: an observable channel query.
    func query(pagination: Pagination, queryOptions: QueryOptions = .all) -> Observable<ChannelResponse> {
        var members = [Member]()
        
        if members.isEmpty, let user = User.current {
            members = [Member(user: user)]
        }
        
        let channelQuery = ChannelQuery(channel: self, members: members, pagination: pagination, options: queryOptions)
        
        return Client.shared.rx.request(endpoint: .channel(channelQuery))
    }
}

extension Channel {
    /// Create a channel.
    ///
    /// - Parameters:
    ///     - type: a channel type (see `ChannelType`).
    ///     - id: a channel id.
    ///     - name: a channel name.
    ///     - imageURL: a channel image URL.
    ///     - memberIds: members of the channel. If empty, then the current user will be added.
    ///     - extraData: an extra data for the channel.
    /// - Returns: an observable channel query (see `ChannelQuery`).
    static func create(type: ChannelType = .messaging,
                       id: String = "",
                       name: String? = nil,
                       imageURL: URL? = nil,
                       memberIds: [String] = [],
                       extraData: Codable? = nil) -> Observable<ChannelResponse> {
        guard let currentUser = User.current else {
            return .empty()
        }
        
        var memberIds = memberIds
        
        if !memberIds.contains(currentUser.id) {
            memberIds.append(currentUser.id)
        }
        
        let channel = Channel(type: type, id: id, name: name, imageURL: imageURL, memberIds: memberIds, extraData: extraData)
        
        return Client.shared.connection.connected()
            .flatMapLatest { _ in Client.shared.rx.request(endpoint: .createChannel(channel)) }
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
