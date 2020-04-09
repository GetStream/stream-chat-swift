//
//  UserConnection.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 08/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A user connection result.
public struct UserConnection: Decodable {
    /// An authorized user.
    public let user: User
    /// A websocket connection id.
    public let connectionId: String
}
