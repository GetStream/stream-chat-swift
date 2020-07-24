//
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
        
        let eventPayload = EventPayload(eventType: .notificationAddedToChannel,
                                        connectionId: .unique,
                                        cid: channelPayload.channel.cid,
                                        channel: channelPayload.channel)
        
        // Save the event payload to DB
        database.write { session in
            try session.saveEvent(payload: eventPayload)
        }
        
        // Try to load the saved channel from DB
        var loadedChannel: ChannelModel<DefaultDataTypes>? {
            database.viewContext.loadChannel(cid: channelId)
        }
        
        AssertAsync.willBeEqual(loadedChannel?.cid, channelId)
        
        // Try to load a saved channel owner from DB
        if let userId = channelPayload.channel.createdBy?.id {
            var loadedUser: UserModel<DefaultDataTypes.User>? {
                database.viewContext.loadUser(id: userId)
            }
            
            AssertAsync.willBeEqual(loadedUser?.id, userId)
        }
        
        // Try to load the saved member from DB
        if let member = channelPayload.channel.members?.first {
            var loadedMember: UserModel<DefaultDataTypes.User>? {
                database.viewContext.loadMember(id: member.user.id, channelId: channelId)
            }
            
            AssertAsync.willBeEqual(loadedMember?.id, member.user.id)
        }
    }
}
