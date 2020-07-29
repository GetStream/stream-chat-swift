//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class DatabaseSession_Tests: StressTestCase {
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
    
    func test_messageData_isSavedToDatabase() throws {
        // Prepare an Event payload with a message data
        let channelId: ChannelId = .unique
        let messageId: MessageId = .unique
        
        let channelPayload: ChannelDetailPayload<DefaultDataTypes> = dummyPayload(with: channelId).channel
        
        let userPayload: UserPayload<NameAndImageExtraData> = .init(id: .unique,
                                                                    role: .admin,
                                                                    created: .unique,
                                                                    updated: .unique,
                                                                    lastActiveDate: .unique,
                                                                    isOnline: true,
                                                                    isInvisible: true,
                                                                    isBanned: true,
                                                                    extraData: .init(name: "Anakin",
                                                                                     imageURL: URL(string: UUID().uuidString)))
        
        let messagePayload = MessagePayload<DefaultDataTypes>(id: messageId,
                                                              type: .regular,
                                                              user: userPayload,
                                                              created: .unique,
                                                              updated: .unique,
                                                              text: "No, I am your father 🤯",
                                                              showReplyInChannel: false,
                                                              mentionedUsers: [],
                                                              replyCount: 0,
                                                              extraData: .init(),
                                                              reactionScores: [:],
                                                              isSilent: false)
        
        let eventPayload: EventPayload<DefaultDataTypes> = .init(eventType: .messageNew,
                                                                 connectionId: .unique,
                                                                 cid: channelId,
                                                                 currentUser: nil,
                                                                 user: nil,
                                                                 createdBy: nil,
                                                                 memberContainer: nil,
                                                                 channel: channelPayload,
                                                                 message: messagePayload,
                                                                 reaction: nil,
                                                                 watcherCount: nil,
                                                                 unreadCount: nil,
                                                                 createdAt: nil,
                                                                 isChannelHistoryCleared: false,
                                                                 banReason: nil,
                                                                 banExpiredAt: nil)
        
        // Save the event payload to DB
        database.write { session in
            try session.saveEvent(payload: eventPayload)
        }
        
        // Try to load the saved message from DB
        var loadedMessage: MessageModel<DefaultDataTypes>? {
            database.viewContext.loadMessage(id: messageId)
        }
        AssertAsync.willBeTrue(loadedMessage != nil)
        
        // Verify the channel has the message
        let loadedChannel: ChannelModel<DefaultDataTypes> = try XCTUnwrap(database.viewContext.loadChannel(cid: channelId))
        let message = try XCTUnwrap(loadedMessage)
        XCTAssert(loadedChannel.latestMessages.contains(message))
    }
}
