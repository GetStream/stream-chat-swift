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
    
    /// Send a new message or update with a given `message.id`.
    ///
    /// - Parameter message: a message.
    /// - Returns: a created/updated message response.
    func send(message: Message) -> Observable<MessageResponse> {
        let request: Observable<MessageResponse> = Client.shared.rx.request(endpoint: .sendMessage(message, self))
        
        if isActive {
            return request
        }
        
        return query(pagination: .limit(1)).flatMap { _ in request }
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
    
    private func sendFile(endpoint: ChatEndpoint) -> Observable<ProgressResponse<URL>> {
        let request: Observable<ProgressResponse<FileUploadResponse>> = Client.shared.rx.progressRequest(endpoint: endpoint)
        return request.map { ($0.progress, $0.result?.file) }
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
    
    private func deleteFile(endpoint: ChatEndpoint) -> Observable<Void> {
        let request: Observable<EmptyData> = Client.shared.rx.request(endpoint: endpoint)
        return request.map { _ in Void() }
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc
    ///
    /// - Parameters:
    ///   - pagination: a pagination (see `Pagination`).
    ///   - queryOptions: a query options. All by default (see `QueryOptions`).
    /// - Returns: an observable channel query.
    func query(pagination: Pagination, queryOptions: QueryOptions = .all) -> Observable<ChannelResponse> {
        if members.isEmpty, let user = User.current {
            members = [Member(user: user)]
        }
        
        let channelQuery = ChannelQuery(channel: self, members: members, pagination: pagination, options: queryOptions)
        
        return Client.shared.rx.request(endpoint: .channel(channelQuery))
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
