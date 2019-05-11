//
//  EventResponse.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 11/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A created event response.
public struct EventResponse: Decodable {
    /// An event.
    let event: Event
    /// A duration of the response.
    let duration: String
}
