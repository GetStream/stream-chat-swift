//
// Event.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object represent an event in the chat system.
public protocol Event {
    /// The underlying raw type of the incoming string.
    static var eventRawType: String { get }
}
