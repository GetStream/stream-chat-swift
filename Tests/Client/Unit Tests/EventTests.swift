//
//  EventTests.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 19/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class EventTests: XCTestCase {
    
    func test_event_equatable() throws {
        let channel = sharedClient.channel(type: .messaging, id: "c1")
        let message = Message(text: "hi")
        let member = User.user1.asMember
        let reaction = Reaction(type: "like", messageId: "m1")
        let messageRead = MessageRead(user: .user1, lastReadDate: .init(), unreadMessagesCount: 0)
        
        XCTAssertTrue(equalityExistsFor(.connectionChanged(.connecting)))
        XCTAssertTrue(equalityExistsFor(.healthCheck(.user1, "")))
        XCTAssertTrue(equalityExistsFor(.pong))
        
        XCTAssertTrue(equalityExistsFor(.userPresenceChanged(.user1, nil, .userPresenceChanged)))
        XCTAssertTrue(equalityExistsFor(.userUpdated(.user1, nil, .userUpdated)))
        XCTAssertTrue(equalityExistsFor(.userBanned(reason: nil, expiration: nil, created: .init(), nil, .userBanned)))
        XCTAssertTrue(equalityExistsFor(.userStartWatching(.user1, 0, nil, .userStartWatching)))
        XCTAssertTrue(equalityExistsFor(.userStopWatching(.user1, 0, nil, .userStopWatching)))
        
        XCTAssertTrue(equalityExistsFor(.typingStart(.user1, nil, .userStartWatching)))
        XCTAssertTrue(equalityExistsFor(.typingStop(.user1, nil, .userStopWatching)))
        
        XCTAssertTrue(equalityExistsFor(.channelUpdated(.init(channel: channel, user: .user1, message: nil),
                                                        nil,
                                                        .channelUpdated)))
        
        XCTAssertTrue(equalityExistsFor(.channelDeleted(channel, .channelDeleted)))
        
        XCTAssertTrue(equalityExistsFor(.channelHidden(.init(cid: channel.cid, clearHistory: false, created: .init()),
                                                       nil, .channelHidden)))
        
        XCTAssertTrue(equalityExistsFor(.messageNew(message, 0, nil, .messageNew)))
        XCTAssertTrue(equalityExistsFor(.messageUpdated(message, nil, .messageUpdated)))
        XCTAssertTrue(equalityExistsFor(.messageDeleted(message, .user1, nil, .messageDeleted)))
        
        XCTAssertTrue(equalityExistsFor(.messageRead(.init(user: .user1, lastReadDate: .init(), unreadMessagesCount: 0),
                                                     nil,
                                                     .messageRead)))
        
        XCTAssertTrue(equalityExistsFor(.memberAdded(member, nil, .memberAdded)))
        XCTAssertTrue(equalityExistsFor(.memberUpdated(member, nil, .memberUpdated)))
        XCTAssertTrue(equalityExistsFor(.memberRemoved(.user1, nil, .memberRemoved)))
        
        XCTAssertTrue(equalityExistsFor(.reactionNew(reaction, message, .user1, nil, .reactionNew)))
        XCTAssertTrue(equalityExistsFor(.reactionUpdated(reaction, message, .user1, nil, .reactionUpdated)))
        XCTAssertTrue(equalityExistsFor(.reactionDeleted(reaction, message, .user1, nil, .reactionDeleted)))
        
        XCTAssertTrue(equalityExistsFor(.notificationMessageNew(message, channel, .noUnread, 0, .notificationMessageNew)))
        XCTAssertTrue(equalityExistsFor(.notificationMarkRead(messageRead, channel, .noUnread, .notificationMarkRead)))
        XCTAssertTrue(equalityExistsFor(.notificationMarkAllRead(messageRead, .notificationMarkRead)))
        XCTAssertTrue(equalityExistsFor(.notificationMutesUpdated(.user1, nil, .notificationMutesUpdated)))
        XCTAssertTrue(equalityExistsFor(.notificationAddedToChannel(channel, .noUnread, .notificationAddedToChannel)))
        XCTAssertTrue(equalityExistsFor(.notificationRemovedFromChannel(channel, .notificationRemovedFromChannel)))
        XCTAssertTrue(equalityExistsFor(.notificationInvited(channel, .notificationInvited)))
        XCTAssertTrue(equalityExistsFor(.notificationInviteAccepted(channel, .notificationInviteAccepted)))
        XCTAssertTrue(equalityExistsFor(.notificationInviteRejected(channel, .notificationInviteRejected)))
    }
    
    private func equalityExistsFor(_ event: Event) -> Bool {
        switch event {
        case .connectionChanged,
             .healthCheck,
             .pong,
             .userPresenceChanged,
             .userUpdated,
             .userBanned,
             .userStartWatching,
             .userStopWatching,
             .typingStart,
             .typingStop,
             .channelUpdated,
             .channelDeleted,
             .channelHidden,
             .messageNew,
             .messageUpdated,
             .messageDeleted,
             .messageRead,
             .memberAdded,
             .memberUpdated,
             .memberRemoved,
             .reactionNew,
             .reactionUpdated,
             .reactionDeleted,
             .notificationMessageNew,
             .notificationMarkRead,
             .notificationMarkAllRead,
             .notificationMutesUpdated,
             .notificationAddedToChannel,
             .notificationRemovedFromChannel,
             .notificationInvited,
             .notificationInviteAccepted,
             .notificationInviteRejected:
            return event == event
        }
    }
}
