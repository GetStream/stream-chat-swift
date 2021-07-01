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
        connected(request({ [unowned base] completion in
            base.create(channel: channel, completion)
        }))
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc.
    /// Creates a `ChannelQuery` with given parameters and call `queryChannel` with it.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - messagesPagination: a pagination for messages (see `Pagination`).
    ///   - membersPagination: a pagination for members. You can use `.limit` and `.offset`.
    ///   - watchersPagination: a pagination for watchers. You can use `.limit` and `.offset`.
    ///   - options: a query options. `.state` by default (see `QueryOptions`)
    func queryChannel(_ channel: Channel,
                      messagesPagination: Pagination = [],
                      membersPagination: Pagination = [],
                      watchersPagination: Pagination = [],
                      options: QueryOptions = .state) -> Observable<ChannelResponse> {
        queryChannel(query: .init(channel: channel,
                                  messagesPagination: messagesPagination,
                                  membersPagination: membersPagination,
                                  watchersPagination: watchersPagination,
                                  options: options))
    }
    
    /// Request for a channel data, e.g. messages, members, read states, etc.
    /// - Parameter query: a channel query.
    func queryChannel(query: ChannelQuery) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.queryChannel(query: query, completion)
        }))
    }
    
    /// Loads the initial channel state and watches for changes.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - options: an additional channel options, e.g. `.presence`
    func watch(channel: Channel, options: QueryOptions = []) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.watch(channel: channel, options: options, completion)
        }))
    }
    
    /// Stop watching the channel for a state changes.
    /// - Parameters:
    ///   - channel: a channel.
    func stopWatching(channel: Channel) -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.stopWatching(channel: channel, completion)
        }))
    }
    
    /// Hide the channel from queryChannels for the user until a message is added.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    func hide(channel: Channel, clearHistory: Bool = false) -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.hide(channel: channel, clearHistory: clearHistory, completion)
        }))
    }
    
    /// Removes the hidden status for a channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - user: the current user.
    func show(channel: Channel) -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.show(channel: channel, completion)
        }))
    }
    
    /// Mutes a channel.
    /// - Parameter channel: a channel.
    @discardableResult
    func mute(channel: Channel) -> Observable<MutedChannelResponse> {
        connected(request({ [unowned base] completion in
            base.mute(channel: channel, completion)
        }))
    }
    
    /// Unmutes a channel.
    /// - Parameter channel: a channel.
    @discardableResult
    func unmute(channel: Channel) -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.unmute(channel: channel, completion)
        }))
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
                extraData: ChannelExtraDataCodable? = nil) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.update(channel: channel, name: name, imageURL: imageURL, extraData: extraData, completion)
        }))
    }
    
    /// Delete the channel.
    /// - Parameters:
    ///   - channel: a channel.
    func delete(channel: Channel) -> Observable<Channel> {
        connected(request({ [unowned base] completion in
            base.delete(channel: channel, completion)
        }))
    }
    
    // MARK: - Message
    
    /// Send a new message with a given `message.id`.
    /// - Parameters:
    ///   - message: a message.
    ///   - channel: a channel.
    ///   - parseMentionedUsers: whether to automatically parse mentions into the `message.mentionedUsers` property. Defaults to `true`.
    func send(message: Message, to channel: Channel, parseMentionedUsers: Bool = true) -> Observable<MessageResponse> {
        connected(request({ [unowned base] completion in
            base.send(message: message, to: channel, parseMentionedUsers: parseMentionedUsers, completion)
        }))
    }
    
    /// Update a message with a given `message.id`.
    /// - Parameters:
    ///   - message: a message.
    ///   - channel: a channel.
    ///   - parseMentionedUsers: whether to automatically parse mentions into the `message.mentionedUsers` property. Defaults to `true`.
    func edit(message: Message, to channel: Channel, parseMentionedUsers: Bool = true) -> Observable<MessageResponse> {
        connected(request({ [unowned base] completion in
            base.edit(message: message, to: channel, parseMentionedUsers: parseMentionedUsers, completion)
        }))
    }
    
    /// Send a message action for a given ephemeral message.
    /// - Parameters:
    ///   - action: an action, e.g. send, shuffle.
    ///   - ephemeralMessage: an ephemeral message.
    ///   - channel: a channel.
    func send(action: Attachment.Action, for ephemeralMessage: Message, to channel: Channel) -> Observable<MessageResponse> {
        connected(request({ [unowned base] completion in
            base.send(action: action, for: ephemeralMessage, to: channel, completion)
        }))
    }
    
    /// Mark messages in the channel as read.
    /// - Parameters:
    ///   - channel: a channel.
    func markRead(channel: Channel) -> Observable<StreamChatClient.Event> {
        connected(request({ [unowned base] completion in
            base.markRead(channel: channel, completion)
        }))
    }
    
    /// Send an event.
    /// - Parameters:
    ///   - eventType: an event type.
    ///   - channel: a channel.
    func send(eventType: EventType, to channel: Channel) -> Observable<StreamChatClient.Event> {
        connected(request({ [unowned base] completion in
            base.send(eventType: eventType, to: channel, completion)
        }))
    }
    
    // MARK: - Members
    
    /// Add a user as a member to the channel.
    /// - Parameters:
    ///   - user: a user.
    ///   - channel: a channel.
    func add(user: User, to channel: Channel) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.add(user: user, to: channel, completion)
        }))
    }
    
    /// Add users as members to the channel.
    /// - Parameters:
    ///   - users: users.
    ///   - channel: a channel.
    func add(users: Set<User>, to channel: Channel) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.add(users: users, to: channel, completion)
        }))
    }
    
    /// Add a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    func add(member: Member, to channel: Channel) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.add(member: member, to: channel, completion)
        }))
    }
    
    /// Add members to the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - channel: a channel.
    func add(members: Set<Member>, to channel: Channel) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.add(members: members, to: channel, completion)
        }))
    }
    
    /// Remove a user as a member from the channel.
    /// - Parameters:
    ///   - user: a user.
    ///   - channel: a channel.
    func remove(user: User, from channel: Channel) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.remove(user: user, from: channel, completion)
        }))
    }
    
    /// Remove users as members from the channel.
    /// - Parameters:
    ///   - users: users.
    ///   - channel: a channel.
    func remove(users: Set<User>, from channel: Channel) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.remove(users: users, from: channel, completion)
        }))
    }
    
    /// Remove a member from the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    func remove(member: Member, from channel: Channel) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.remove(member: member, from: channel, completion)
        }))
    }
    
    /// Remove members from the channel.
    /// - Parameters:
    ///   - members: members.
    ///   - channel: a channel.
    func remove(members: Set<Member>, from channel: Channel) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
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
             reason: String? = nil) -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.ban(user: user, in: channel, timeoutInMinutes: timeoutInMinutes, reason: reason, completion)
        }))
    }
    
    /// Unban a user.
    /// - Parameter user: a user.
    func unban(user: User, in channel: Channel) -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.unban(user: user, in: channel, completion)
        }))
    }
    
    // MARK: - Invite Requests
    
    /// Invite a member to the channel.
    /// - Parameters:
    ///   - member: a member.
    ///   - channel: a channel.
    func invite(member: Member, to channel: Channel) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.invite(member: member, to: channel, completion)
        }))
    }
    
    /// Invite members to the channel.
    /// - Parameters:
    ///   - members: a list of members.
    ///   - channel: a channel.
    func invite(members: Set<Member>, to channel: Channel) -> Observable<ChannelResponse> {
        connected(request({ [unowned base] completion in
            base.invite(members: members, to: channel, completion)
        }))
    }
    
    /// Accept an invite to the channel.
    ///
    /// - Parameters:
    ///   - channel: a channel.
    ///   - message: an additional message.
    func acceptInvite(for channel: Channel, with message: Message? = nil) -> Observable<ChannelInviteResponse> {
        connected(request({ [unowned base] completion in
            base.acceptInvite(for: channel, with: message, completion)
        }))
    }
    
    /// Reject an invite to the channel.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - message: an additional message.
    func rejectInvite(for channel: Channel, with message: Message? = nil) -> Observable<ChannelInviteResponse> {
        connected(request({ [unowned base] completion in
            base.rejectInvite(for: channel, with: message, completion)
        }))
    }
    
    /// Query a channel's members.
    /// - Parameters:
    ///   - channelId: Channel Id for the channel.
    ///   - filter: Filter conditions for query
    ///   - sorting: Sorting conditions for query
    ///   - limit: Limit for number of members to return. Defaults to 100.
    ///   - offset: Offset of pagination. Defaults to 0.
    ///  - Returns: Observable with `MembersQueryResponse`
    func queryMembers(channelId: ChannelId,
                      filter: Filter,
                      sorting: [Sorting] = [],
                      limit: Int = 100,
                      offset: Int = 0) -> Observable<MembersQueryResponse> {
        connected(request({ [unowned base] completion in
            base.queryMembers(channelId: channelId,
                              filter: filter,
                              sorting: sorting,
                              limit: limit,
                              offset: offset,
                              completion)
        }))
    }
    
    /// Query a channel's members.
    /// - Parameters:
    ///   - channelTyoe: Channel type for the channel.
    ///   - members: Members for member-based channels (Direct Message)
    ///   - filter: Filter conditions for query
    ///   - sorting: Sorting conditions for query
    ///   - limit: Limit for number of members to return. Defaults to 100.
    ///   - offset: Offset of pagination. Defaults to 0.
    ///  - Returns: Observable with `MembersQueryResponse`
    func queryMembers(channelType: ChannelType,
                      members: [Member],
                      filter: Filter,
                      sorting: [Sorting] = [],
                      limit: Int = 100,
                      offset: Int = 0) -> Observable<MembersQueryResponse> {
        connected(request({ [unowned base] completion in
            base.queryMembers(channelType: channelType,
                              members: members,
                              filter: filter,
                              sorting: sorting,
                              limit: limit,
                              offset: offset,
                              completion)
        }))
    }
    
    /// Query a channel's members.
    /// - Parameters:
    ///   - membersQuery: `MembersQuery` object for the query.
    ///  - Returns: Observable with `MembersQueryResponse`
    func queryMembers(membersQuery: MembersQuery) -> Observable<MembersQueryResponse> {
        connected(request({ [unowned base] completion in
            base.queryMembers(membersQuery: membersQuery,
                              completion)
        }))
    }
    
    // MARK: - Uploading
    
    /// Upload an image to the channel.
    /// - Parameters:
    ///   - data: an image data.
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - channel: a channel.
    ///   - progress: a progress block with `Client.Progress`.
    func sendImage(data: Data, fileName: String, mimeType: String, channel: Channel) -> Observable<ProgressResponse<URL>> {
        connected(progressRequest({ [unowned base] progress, completion in
            base.sendImage(data: data,
                           fileName: fileName,
                           mimeType: mimeType,
                           channel: channel,
                           progress: progress,
                           completion: completion)
        }))
    }
    
    /// Upload a file to the channel.
    /// - Parameters:
    ///   - data: a file data.
    ///   - fileName: a file name.
    ///   - mimeType: a file mime type.
    ///   - channel: a channel.
    ///   - progress: a progress block with `Client.Progress`.
    func sendFile(data: Data, fileName: String, mimeType: String, channel: Channel) -> Observable<ProgressResponse<URL>> {
        connected(progressRequest({ [unowned base] progress, completion in
            base.sendFile(data: data,
                          fileName: fileName,
                          mimeType: mimeType,
                          channel: channel,
                          progress: progress,
                          completion: completion)
        }))
    }
    
    /// Delete an image with a given URL.
    /// - Parameters:
    ///   - url: an image URL.
    ///   - channel: a channel.
    func deleteImage(url: URL, channel: Channel) -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.deleteImage(url: url, channel: channel, completion)
        }))
    }
    
    /// Delete a file with a given URL.
    /// - Parameters:
    ///   - url: a file URL.
    ///   - channel: a channel.
    func deleteFile(url: URL, channel: Channel) -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.deleteFile(url: url, channel: channel, completion)
        }))
    }
    
    /// Enable slow mode for the given channel
    /// - Parameters:
    ///   - channel: a channel.
    ///   - cooldown: Cooldown duration in seconds. (1-120)
    ///   - completion: an empty completion block.
    @discardableResult
    func enableSlowMode(for channel: Channel, cooldown: Int) -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.enableSlowMode(for: channel, cooldown: cooldown, completion)
        }))
    }
    
    /// Disables slow mode for the given channel
    /// - Parameters:
    ///   - channel: a channel.
    ///   - completion: an empty completion block.
    @discardableResult
    func disableSlowMode(for channel: Channel) -> Observable<EmptyData> {
        connected(request({ [unowned base] completion in
            base.disableSlowMode(for: channel, completion)
        }))
    }
}
