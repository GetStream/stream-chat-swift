//
//  Database.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 12/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

public protocol Database {
    
    /// A user owner of the database.
    var user: User? { get set }
    
    /// Fetch channels and messages from a database.
    ///
    /// - Parameter query: a channels query
    /// - Returns: an observable channels response.
    func channels(_ query: ChannelsQuery) -> Observable<[ChannelResponse]>
    
    /// Fetch channel messages.
    ///
    /// - Parameters:
    ///   - channelType: a channel type.
    ///   - channelId: a channel id.
    ///   - pagination: a pagination.
    /// - Returns: an observable channel response.
    func channel(channelType: ChannelType, channelId: String, pagination: Pagination) -> Observable<ChannelResponse>
    
    /// Fetch message replies.
    ///
    /// - Parameters:
    ///   - message: a parent message.
    ///   - pagination: a pagination.
    /// - Returns: an observable messages.
    func replies(for message: Message, pagination: Pagination) -> Observable<[Message]>
    
    /// Add messages for a channel.
    ///
    /// - Parameters:
    ///   - messages: messages of a channel
    ///   - channel: a channel
    func add(messages: [Message], for channel: Channel)
    
    /// Add replies for a message.
    ///
    /// - Parameters:
    ///   - messages: replies.
    ///   - message: a parent message.
    func add(replies: [Message], for message: Message)
    
    /// Set members for a channel.
    ///
    /// - Parameters:
    ///   - members: members of a channel
    ///   - channel: a channel
    func set(members: [Member], for channel: Channel)
    
    /// Add a new member for a channel.
    ///
    /// - Parameters:
    ///   - member: a new member of a channel
    ///   - channel: a channel
    func add(member: Member, for channel: Channel)
    
    /// Remove a member from a channel.
    ///
    /// - Parameters:
    ///   - member: a member of a channel
    ///   - channel: a channel
    func remove(member: Member, from channel: Channel)
    
    /// Update a member in a channel.
    ///
    /// - Parameters:
    ///   - member: a member of a channel
    ///   - channel: a channel
    func update(member: Member, from channel: Channel)
}
