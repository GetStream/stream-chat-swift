//
//  Channel+RxRequests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 07/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

// MARK: Channel Requests

extension Channel: ReactiveCompatible {}

public extension Reactive where Base == Channel {
    
    /// Create a channel.
    @discardableResult
    func create() -> Observable<ChannelResponse> {
        Client.shared.rx.create(channel: base)
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc
    /// - Parameters:
    ///   - messagesPagination: a pagination for messages (see `Pagination`).
    ///   - membersPagination: a pagination for members. You can use `.limit` and `.offset`.
    ///   - watchersPagination: a pagination for watchers. You can use `.limit` and `.offset`.
    ///   - options: a query options. All by default (see `QueryOptions`), e.g. `.watch`.
    func query(messagesPagination: Pagination = [],
               membersPagination: Pagination = [],
               watchersPagination: Pagination = [],
               options: QueryOptions = []) -> Observable<ChannelResponse> {
        Client.shared.rx.queryChannel(base,
                                      messagesPagination: messagesPagination,
                                      membersPagination: membersPagination,
                                      watchersPagination: watchersPagination,
                                      options: options)
    }
    
    /// Loads the initial channel state and watches for changes.
    /// - Parameters:
    ///   - options: an additional channel options, e.g. `.presence`
    func watch(options: QueryOptions = []) -> Observable<ChannelResponse> {
        Client.shared.rx.watch(channel: base, options: options)
    }
    
    /// Stop watching the channel for a state changes.
    func stopWatching() -> Observable<EmptyData> {
        Client.shared.rx.stopWatching(channel: base)
    }
    
    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - user: the current user.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    func hide(clearHistory: Bool = false) -> Observable<EmptyData> {
        Client.shared.rx.hide(channel: base, clearHistory: clearHistory)
    }
    
    /// Removes the hidden status for a channel.
    /// - Parameters:
    ///   - user: the current user.
    func show() -> Observable<EmptyData> {
        Client.shared.rx.show(channel: base)
    }
    
    /// Mutes a channel.
    func mute() -> Observable<MutedChannelResponse> {
        Client.shared.rx.mute(channel: base)
    }
    
    /// Unmutes a channel.
    func unmute() -> Observable<EmptyData> {
        Client.shared.rx.unmute(channel: base)
    }
    
    /// Update channel data.
    /// - Parameters:
    ///   - name: a channel name.
    ///   - imageURL: an image URL.
    ///   - extraData: a custom extra data.
    func update(name: String? = nil,
                imageURL: URL? = nil,
                extraData: ChannelExtraDataCodable? = nil) -> Observable<ChannelResponse> {
        Client.shared.rx.update(channel: base, name: name, imageURL: imageURL, extraData: extraData)
    }
    
    /// Delete the channel.
    func delete() -> Observable<Channel> {
        Client.shared.rx.delete(channel: base)
    }
    
    // MARK: - Message
    
    /// Send a new message with a given `message.id`.
    /// - Parameters:
    ///   - message: a message.
    ///   - parseMentionedUsers: whether to automatically parse mentions into the `message.mentionedUsers` property. Defaults to `true`.
    func send(message: Message, parseMentionedUsers: Bool = true) -> Observable<MessageResponse> {
        Client.shared.rx.send(message: message, to: base, parseMentionedUsers: parseMentionedUsers)
    }
    
    /// Update a message with a given `message.id`.
    /// - Parameters:
    ///   - message: a message.
    ///   - parseMentionedUsers: whether to automatically parse mentions into the `message.mentionedUsers` property. Defaults to `true`.
    func edit(message: Message, parseMentionedUsers: Bool = true) -> Observable<MessageResponse> {
        Client.shared.rx.edit(message: message, to: base, parseMentionedUsers: parseMentionedUsers)
    }
    
    /// Send a message action for a given ephemeral message.
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    func send(action: Attachment.Action, for ephemeralMessage: Message) -> Observable<MessageResponse> {
        Client.shared.rx.send(action: action, for: ephemeralMessage, to: base)
    }
    
    /// Mark messages in the channel as read.
    func markRead() -> Observable<StreamChatClient.Event> {
        Client.shared.rx.markRead(channel: base)
    }
    
    // MARK: - Events
    
    /// Send an event.
    /// - Parameter eventType: an event type.
    func send(eventType: EventType) -> Observable<StreamChatClient.Event> {
        Client.shared.rx.send(eventType: eventType, to: base)
    }
    
    /// Send a keystroke event for the current user.
    func keystroke() -> Observable<StreamChatClient.Event> {
        request({ [weak base] in base?.keystroke($0) ?? SubscriptionBag() })
    }
    
    /// Send a keystroke event for the current user.
    func stopTyping() -> Observable<StreamChatClient.Event> {
        request({ [weak base] in base?.stopTyping($0) ?? SubscriptionBag() })
    }
    
    // MARK: - Members
    
    /// Add a user as a member to the channel.
    /// - Parameter user: a member.
    func add(user: User) -> Observable<ChannelResponse> {
        Client.shared.rx.add(user: user, to: base)
    }
    
    /// Add users as members to the channel.
    /// - Parameter users: members.
    func add(users: Set<User>) -> Observable<ChannelResponse> {
        Client.shared.rx.add(users: users, to: base)
    }
    
    /// Add a member to the channel.
    /// - Parameter member: a member.
    func add(member: Member) -> Observable<ChannelResponse> {
        Client.shared.rx.add(member: member, to: base)
    }
    
    /// Add members to the channel.
    /// - Parameter members: members.
    func add(members: Set<Member>) -> Observable<ChannelResponse> {
        Client.shared.rx.add(members: members, to: base)
    }
    
    /// Remove a user as a member from the channel.
    /// - Parameter user: a user.
    func remove(user: User) -> Observable<ChannelResponse> {
        Client.shared.rx.remove(user: user, from: base)
    }
    
    /// Remove users as members from the channel.
    /// - Parameter users: users.
    func remove(users: Set<User>) -> Observable<ChannelResponse> {
        Client.shared.rx.remove(users: users, from: base)
    }
    
    /// Remove a member from the channel.
    /// - Parameter member: a member.
    func remove(member: Member) -> Observable<ChannelResponse> {
        Client.shared.rx.remove(member: member, from: base)
    }
    
    /// Remove members from the channel.
    /// - Parameter members: members.
    func remove(members: Set<Member>) -> Observable<ChannelResponse> {
        Client.shared.rx.remove(members: members, from: base)
    }
    
    // MARK: - User Ban
    
    /// Ban a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - timeoutInMinutes: for a timeout in minutes.
    func ban(user: User, timeoutInMinutes: Int? = nil, reason: String? = nil) -> Observable<EmptyData> {
        Client.shared.rx.ban(user: user, in: base, timeoutInMinutes: timeoutInMinutes, reason: reason)
    }
    
    /// Unban a user.
    /// - Parameter user: a user.
    func unban(user: User) -> Observable<EmptyData> {
        Client.shared.rx.unban(user: user, in: base)
    }
    
    // MARK: - Invite Requests
    
    /// Invite a member to the channel.
    /// - Parameter member: a member.
    func invite(member: Member) -> Observable<ChannelResponse> {
        Client.shared.rx.invite(member: member, to: base)
    }
    
    /// Invite members to the channel.
    /// - Parameter members: a list of members.
    func invite(members: Set<Member>) -> Observable<ChannelResponse> {
        Client.shared.rx.invite(members: members, to: base)
    }
    
    /// Accept an invite to the channel.
    /// - Parameter message: an additional message.
    func acceptInvite(with message: Message? = nil) -> Observable<ChannelInviteResponse> {
        Client.shared.rx.acceptInvite(for: base, with: message)
    }
    
    /// Reject an invite to the channel.
    /// - Parameter message: an additional message.
    func rejectInvite(with message: Message? = nil) -> Observable<ChannelInviteResponse> {
        Client.shared.rx.rejectInvite(for: base, with: message)
    }
    
    /// Query this channel's members.
    /// - Parameters:
    ///   - filter: Filter conditions for query
    ///   - sorting: Sorting conditions for query
    ///   - limit: Limit for number of members to return. Defaults to 100.
    ///   - offset: Offset of pagination. Defaults to 0.
    func queryMembers(filter: Filter,
                      sorting: [Sorting] = [],
                      limit: Int = 100,
                      offset: Int = 0) -> Observable<MembersQueryResponse> {
        let query: MembersQuery
        if base.id.isEmpty {
            query = MembersQuery(channelType: base.type,
                                 members: Array(base.members),
                                 filter: filter,
                                 sorting: sorting,
                                 limit: limit,
                                 offset: offset)
        } else {
            query = MembersQuery(channelId: base.cid,
                                 filter: filter,
                                 sorting: sorting,
                                 limit: limit,
                                 offset: offset)
        }
        return Client.shared.rx.queryMembers(membersQuery: query)
    }
    
    // MARK: - Uploading
    
    /// Upload an image to the channel.
    /// - Parameters:
    ///   - data: an image data.
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    func sendImage(data: Data, fileName: String, mimeType: String) -> Observable<ProgressResponse<URL>> {
        Client.shared.rx.sendImage(data: data, fileName: fileName, mimeType: mimeType, channel: base)
    }
    
    /// Upload a file to the channel.
    /// - Parameters:
    ///   - data: a file data.
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    func sendFile(data: Data, fileName: String, mimeType: String) -> Observable<ProgressResponse<URL>> {
        Client.shared.rx.sendFile(data: data, fileName: fileName, mimeType: mimeType, channel: base)
    }
    
    /// Delete an image with a given URL.
    /// - Parameter url: an image URL.
    func deleteImage(url: URL) -> Observable<EmptyData> {
        Client.shared.rx.deleteImage(url: url, channel: base)
    }
    
    /// Delete a file with a given URL.
    /// - Parameter url: a file URL.
    func deleteFile(url: URL) -> Observable<EmptyData> {
        Client.shared.rx.deleteFile(url: url, channel: base)
    }
    
    /// Enable slow mode for the channel
    /// - Parameters:
    ///   - channel: a channel.
    ///   - cooldown: Cooldown duration in seconds. (1-120)
    ///   - completion: an empty completion block.
    @discardableResult
    func enableSlowMode(cooldown: Int) -> Observable<EmptyData> {
        Client.shared.rx.enableSlowMode(for: base, cooldown: cooldown)
    }
    
    /// Disables slow mode for the channel
    /// - Parameters:
    ///   - channel: a channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func disableSlowMode() -> Observable<EmptyData> {
        Client.shared.rx.disableSlowMode(for: base)
    }
}
