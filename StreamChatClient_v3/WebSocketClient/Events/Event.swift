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

// WIP

extension ChannelModel {
  init(from eventResponseChannel: EventResponse<ExtraData>.Channel<ExtraData>) {
    id = eventResponseChannel.id
    extraData = eventResponseChannel.extraData
    members = Set(eventResponseChannel.members.map(UserModel.init))
  }
}
