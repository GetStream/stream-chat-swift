//
// ChannelEventsHandler.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

/// Handles some of the incoming ChannelEvents and propagates related changes to the database.
class ChannelEventsHandler<ExtraData: ExtraDataTypes>: EventHandlerWorker<ExtraData> {
  override func handleNewEvent(event: Event) {
    if let event = event as? AddedToChannel<ExtraData> {
      database.write { session in
        session.saveChannel(event.channel)
      }
    }

    // TODO: more events
  }
}
