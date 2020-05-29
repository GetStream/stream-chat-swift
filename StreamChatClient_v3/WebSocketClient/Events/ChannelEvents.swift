//
// ChannelEvents.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ChannelEvent: Event {
  associatedtype ExtraData: ExtraDataTypes

  var channel: ChannelModel<ExtraData> { get }
}

public struct AddedToChannel<ExtraData: ExtraDataTypes>: ChannelEvent {
  public static var eventRawType: String { "notification.added_to_channel" }

//  public let member: MemberModel<ExtraData.User>
  public let channel: ChannelModel<ExtraData>

  init?(from eventResponse: EventResponse<ExtraData>) throws {
    guard eventResponse.eventType == Self.eventRawType else { return nil }
    guard let channel = eventResponse.channel else {
      throw ClientError.EventDecodingError("`channel` field can't be `nil` for the RemovedFromChannel event.")
    }
    self.init(channel: ChannelModel(from: channel))
  }

  init(channel: ChannelModel<ExtraData>) {
    self.channel = channel
  }
}
