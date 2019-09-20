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
    
    /// Add messages for a channel to a local database.
    ///
    /// - Parameters:
    ///   - messages: messages of a channel
    ///   - channel: a channel
    func add(messages: [Message], for channel: Channel)
}
