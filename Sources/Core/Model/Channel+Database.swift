//
//  Channel+Database.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 17/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Database

public extension Channel {
    
    /// Fetch channel messages for a local database.
    ///
    /// - Parameter pagination: a pagination perameters.
    /// - Returns: a channel response (see `ChannelResponse`).
    func fetch(pagination: Pagination = .none) -> Observable<ChannelResponse> {
        guard let database = Client.shared.database else {
            return .empty()
        }
        
        return database.channel(channelType: type, channelId: id, pagination: pagination)
    }
}
