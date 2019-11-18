//
//  Client+Database.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

extension Client {
    
    /// Fetch channels from a database.
    /// - Parameter pagination: a pagination perameters.
    /// - Returns: a channel response (see `ChannelResponse`).
    public func fetchChannels(_ query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        guard let database = database else {
            return .empty()
        }
        
        database.logger?.log("⬅️ Fetch channels with: \(query)")
        return database.channels(query)
    }
}
