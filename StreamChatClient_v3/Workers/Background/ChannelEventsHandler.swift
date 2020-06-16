//
// ChannelEventsHandler.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

/// Handles some of the incoming ChannelEvents and propagates related changes to the database.
class ChannelEventsHandler<ExtraData: ExtraDataTypes>: EventHandlerWorker<ExtraData> {
    override func handleNewEvent(event: Event) {
        // TODO: Saving the data must happen in the middleware so we're sure the data is saved before the event is published
//    if let event = event as? AddedToChannel<ExtraData> {
        
//      database.write { session in
//        session.saveChannel(payload: event.channelPayload)
//      }
//    }
        
        // TODO: more events
    }
}
