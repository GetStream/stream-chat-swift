//
//  Client+RxChannel.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 06/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

// MARK: Channels Requests

public extension Reactive where Base == Client {
    
    /// Create a channel.
    /// - Parameters:
    ///   - channel: a channel.
    func create(channel: Channel) -> Observable<ChannelResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.create(channel: channel, completion)
        }))
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc
    /// - Parameters:
    ///   - channel: a channel.
    ///   - pagination: a pagination for messages (see `Pagination`).
    ///   - options: a query options. All by default (see `QueryOptions`), e.g. `.watch`.
    func queryChannel(_ channel: Channel,
                      pagination: Pagination = .none,
                      options: QueryOptions = []) -> Observable<ChannelResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.queryChannel(channel, pagination: pagination, options: options, completion)
        }))
    }
    
    /// Loads the initial channel state and watches for changes.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - options: an additional channel options, e.g. `.presence`
    func watch(channel: Channel, options: QueryOptions = []) -> Observable<ChannelResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.watch(channel: channel, options: options, completion)
        }))
    }
    
    /// Stop watching the channel for a state changes.
    /// - Parameters:
    ///   - channel: a channel.
    func stopWatching(channel: Channel) -> Observable<Void> {
        connectedRequest(request({ [unowned base] completion in
            base.stopWatching(channel: channel, completion)
        })).void()
    }
    
    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    func hide(channel: Channel, clearHistory: Bool = false) -> Observable<Void> {
        connectedRequest(request({ [unowned base] completion in
            base.hide(channel: channel, clearHistory: clearHistory, completion)
        })).void()
    }
    
    /// Removes the hidden status for a channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - user: the current user.
    func show(channel: Channel) -> Observable<Void> {
        connectedRequest(request({ [unowned base] completion in
            base.show(channel: channel, completion)
        })).void()
    }
    
    /// Update channel data.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - name: a channel name.
    ///   - imageURL: an image URL.
    ///   - extraData: a custom extra data.
    func update(channel: Channel,
                name: String? = nil,
                imageURL: URL? = nil,
                extraData: Codable? = nil) -> Observable<ChannelResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.update(channel: channel, name: name, imageURL: imageURL, extraData: extraData, completion)
        }))
    }
    
    /// Delete the channel.
    /// - Parameters:
    ///   - channel: a channel.
    func delete(channel: Channel) -> Observable<Channel> {
        connectedRequest(request({ [unowned base] completion in
            base.delete(channel: channel, completion)
        }))
    }
    
    // MARK: - Message
    
    /// Send a new message or update with a given `message.id`.
    /// - Parameters:
    ///   - message: a message.
    ///   - channel: a channel.
    func send(message: Message, to channel: Channel) -> Observable<MessageResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.send(message: message, to: channel, completion)
        }))
    }
    
    /// Send a message action for a given ephemeral message.
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    ///   - channel: a channel.
    func send(action: Attachment.Action, for ephemeralMessage: Message, to channel: Channel) -> Observable<MessageResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.send(action: action, for: ephemeralMessage, to: channel, completion)
        }))
    }
    
    /// Mark messages in the channel as read.
    /// - Parameters:
    ///   - channel: a channel.
    func markRead(channel: Channel) -> Observable<StreamChatClient.Event> {
        connectedRequest(request({ [unowned base] completion in
            base.markRead(channel: channel, completion)
        }))
    }
    
    /// Send an event.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - channel: a channel.
    func send(eventType: EventType, to channel: Channel) -> Observable<StreamChatClient.Event> {
        connectedRequest(request({ [unowned base] completion in
            base.send(eventType: eventType, to: channel, completion)
        }))
    }
    
    // MARK: - Members
    
    /// Add a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    func add(member: Member, to channel: Channel) -> Observable<ChannelResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.add(member: member, to: channel, completion)
        }))
    }
    
    /// Add members to the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - channel: a channel.
    func add(members: Set<Member>, to channel: Channel) -> Observable<ChannelResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.add(members: members, to: channel, completion)
        }))
    }
    
    /// Remove a member from the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    func remove(member: Member, from channel: Channel) -> Observable<ChannelResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.remove(member: member, from: channel, completion)
        }))
    }
    
    /// Remove members from the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - channel: a channel.
    func remove(members: Set<Member>, from channel: Channel) -> Observable<ChannelResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.remove(members: members, from: channel, completion)
        }))
    }
    
    // MARK: - User Ban
    
    /// Ban a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - channel: a channel.
    ///   - timeoutInMinutes: for a timeout in minutes.
    func ban(user: User,
             in channel: Channel,
             timeoutInMinutes: Int? = nil,
             reason: String? = nil) -> Observable<Void> {
        connectedRequest(request({ [unowned base] completion in
            base.ban(user: user, in: channel, timeoutInMinutes: timeoutInMinutes, reason: reason, completion)
        })).void()
    }
    
    // MARK: - Invite Requests
    
    /// Invite a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    func invite(member: Member, to channel: Channel) -> Observable<ChannelResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.invite(member: member, to: channel, completion)
        }))
    }
    
    /// Invite members to the channel.
    /// - Parameters:
    ///   - members: a list of members.
    ///   - channel: a channel.
    func invite(members: Set<Member>, to channel: Channel) -> Observable<ChannelResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.invite(members: members, to: channel, completion)
        }))
    }
    
    /// Accept an invite to the channel.
    ///
    /// - Parameters:
    ///   - channel: a channel.
    ///   - message: an additional message.
    func acceptInvite(for channel: Channel, with message: Message? = nil) -> Observable<ChannelInviteResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.acceptInvite(for: channel, with: message, completion)
        }))
    }
    
    /// Reject an invite to the channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - message: an additional message.
    func rejectInvite(for channel: Channel, with message: Message? = nil) -> Observable<ChannelInviteResponse> {
        connectedRequest(request({ [unowned base] completion in
            base.rejectInvite(for: channel, with: message, completion)
        }))
    }
    
    // MARK: - File Requests
    
    /// Upload an image to the channel.
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - imageData: an image data.
    ///   - channel: a channel.
    ///   - progress: a progress block with `Client.Progress`.
    func sendImage(fileName: String, mimeType: String, imageData: Data, to channel: Channel) -> Observable<ProgressResponse<URL>> {
        connectedRequest(progressRequest({ [unowned base] progress, completion in
            base.sendImage(fileName: fileName, mimeType: mimeType, imageData: imageData, to: channel, progress, completion)
        }))
    }
    
    /// Upload a file to the channel.
    /// - Parameters:
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - fileData: a file data.
    ///   - channel: a channel.
    ///   - progress: a progress block with `Client.Progress`.
    func sendFile(fileName: String, mimeType: String, fileData: Data, to channel: Channel) -> Observable<ProgressResponse<URL>> {
        connectedRequest(progressRequest({ [unowned base] progress, completion in
            base.sendFile(fileName: fileName, mimeType: mimeType, fileData: fileData, to: channel, progress, completion)
        }))
    }
    
    /// Delete an image with a given URL.
    /// - Parameters:
    ///   - url: an image URL.
    ///   - channel: a channel.
    func deleteImage(url: URL, from channel: Channel) -> Observable<Void> {
        connectedRequest(request({ [unowned base] completion in
            base.deleteImage(url: url, from: channel, completion)
        })).void()
    }
    
    /// Delete a file with a given URL.
    /// - Parameters:
    ///   - url: a file URL.
    ///   - channel: a channel.
    func deleteFile(url: URL, from channel: Channel) -> Observable<Void> {
        connectedRequest(request({ [unowned base] completion in
            base.deleteFile(url: url, from: channel, completion)
        })).void()
    }
}
