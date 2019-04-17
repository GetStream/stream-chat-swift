//
//  MessageResponse.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 17/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A created message response.
public struct MessageResponse: Decodable {
    /// A message.
    let message: Message
    /// A duration of the response.
    let duration: String
}
