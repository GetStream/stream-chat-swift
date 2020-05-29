//
//  Client+SilentMessageTests.swift
//  StreamChatClientTests
//
//  Created by Bahadir Oncel on 12.05.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

class Client_SilentMessageTests: XCTestCase {
    
    let client = sharedClient
    
    override func setUp() {
        super.setUp()
        
        client.unreadCountAtomic.set(.noUnread)
    }
    
    func test_silentMessage_doesNotIncreaseUnreadCount() {
        let channel = client.channel(type: .messaging, id: "test-silent-message")
        
        let message = Message(text: "test", silent: true, user: User(id: "test-sender"))
        
        let newMessageEvent = Event.messageNew(message, 0, channel.cid, .messageNew)
        
        assert(client.unreadCount.messages == 0)
        
        client.updateUserUnreadCount(event: newMessageEvent)
        
        XCTAssertEqual(client.unreadCount.messages, 0)
    }
    
    func test_silentMentionMessage_doesNotIncreaseUnreadCount() {
        client.userAtomic.set(.init(id: "test-mention"))
        
        let channel = client.channel(type: .messaging, id: "test-silent-message")
        
        let message = Message(text: "test", silent: true, user: User(id: "test-sender"), mentionedUsers: [client.user])
        
        let newMessageEvent = Event.messageNew(message, 0, channel.cid, .messageNew)
        
        assert(client.unreadCount.messages == 0)
        
        client.updateUserUnreadCount(event: newMessageEvent)
        
        XCTAssertEqual(client.unreadCount.messages, 0)
    }
    
    func test_silentDeletedMessage_doesNotDecreaseUnreadCount() {
        client.userAtomic.set(.init(id: "test-mention"))
        
        let channel = client.channel(type: .messaging, id: "test-silent-message")
        
        let message = Message(text: "test", silent: true, user: User(id: "test-sender"), mentionedUsers: [client.user])
        
        let deletedMessageEvent = Event.messageDeleted(message, User(id: "test-sender"), channel.cid, .messageDeleted)
        
        client.unreadCountAtomic.set(.init(channels: 1, messages: 1))

        assert(client.unreadCount.messages == 1)
        
        client.updateUserUnreadCount(event: deletedMessageEvent)
        
        XCTAssertEqual(client.unreadCount.messages, 1)
    }
}
