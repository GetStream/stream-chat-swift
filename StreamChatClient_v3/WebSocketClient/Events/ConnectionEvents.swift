//
// ConnectionEvents.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ConnectionEvent: Event {
  var connectionId: String { get }
}

public struct HealthCheck: ConnectionEvent {
  public static var eventRawType: String { "health.check" }
  public let connectionId: String

  init?<ExtraData: ExtraDataTypes>(from eventResponse: EventResponse<ExtraData>) throws {
    guard eventResponse.eventType == Self.eventRawType else { return nil }
    guard let connectionId = eventResponse.connectionId else {
      throw ClientError.EventDecodingError(missingValue: "connectionId", eventType: "HealthCheck")
    }
    self.connectionId = connectionId
  }
}
