//
// DatabaseSession_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class DatabaseSession_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_eventPayloadChannelData_isSavedToDatabase() {
        // Prepare an Event payload with a channel data
        let channelId: ChannelId = .unique
        let channelPayload = dummyPayload(with: channelId)
        let eventPayload = EventPayload(eventType: "test_event", connectionId: .unique, channel: channelPayload.channel,
                                        currentUser: nil, cid: channelPayload.channel.cid)
        
        // Save the event payload to DB
        database.write { (session) in
            try session.saveEvent(payload: eventPayload)
        }
        
        // Try to load the saved channel from DB
        var loadedChannel: ChannelModel<DefaultDataTypes>? {
            database.viewContext.loadChannel(cid: channelId)
        }
        AssertAsync.willBeEqual(loadedChannel?.cid, channelId)
    }
}
