//
//  Database.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 12/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol Database {
    
    /// A user owner of the database.
    var user: User { get set }
    
    /// A logger.
    var logger: ClientLogger? { get }
    
    /// Delete all objects.
    func deleteAll()
    
    // MARK: Channels
    
    /// Fetch channels and messages from a database.
    /// - Parameter query: a channels query
    /// - Returns: an observable channels response.
    func channelsFromDatabase(query: ChannelsQuery) -> [ChannelResponse]
    
    // MARK: Channel
    
    /// Fetch channel messages.
    /// - Parameters:
    ///   - channelType: a channel type.
    ///   - channelId: a channel id.
    ///   - pagination: a pagination.
    /// - Returns: an observable channel response.
    func channelFromDatabase(channelType: ChannelType, channelId: String, pagination: Pagination) -> ChannelResponse
    
    /// Add channels with messages and members.
    /// - Parameter channels: channel responses.
    func addToDatabase(channels: [ChannelResponse], query: ChannelsQuery)
    
    /// Add or update a channel.
    /// - Parameter channel: a channel.
    func addOrUpdateInDatabase(channel: Channel)
    
    // MARK: - Message
    
    /// Add messages to a channel. The channel and members should be added/updated too.
    /// - Parameters:
    ///   - messages: messages of a channel
    ///   - channel: a channel
    func addToDatabase(messages: [Message], to channel: Channel)
    
    /// Fetch message replies.
    /// - Parameters:
    ///   - message: a parent message.
    ///   - pagination: a pagination.
    /// - Returns: an observable messages.
    func repliesFromDatabase(for message: Message, pagination: Pagination) -> [Message]
    
    /// Add replies for a message.
    /// - Parameters:
    ///   - messages: replies.
    ///   - message: a parent message.
    func addToDatabase(replies: [Message], for message: Message)
    
    // MARK: - Members
    
    /// Set members for a channel.
    /// - Parameters:
    ///   - members: members of a channel
    ///   - channel: a channel
    func setToDatabase(members: Set<Member>, for channel: Channel)
    
    /// Add a new member for a channel.
    /// - Parameters:
    ///   - member: a new members of a channel
    ///   - channel: a channel
    func addToDatabase(members: Set<Member>, for channel: Channel)
    
    /// Remove a member from a channel.
    /// - Parameters:
    ///   - member: members of a channel
    ///   - channel: a channel
    func removeFromDatabase(members: Set<Member>, from channel: Channel)
    
    /// Update a member in a channel.
    /// - Parameters:
    ///   - members: members of a channel
    ///   - channel: a channel
    func updateInDatabase(members: Set<Member>, from channel: Channel)
}
