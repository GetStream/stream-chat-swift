//
//  Client_SilentMessageTests.swift
//  StreamChatClientTests
//
//  Created by Bahadir Oncel on 12.05.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

class Client_SilentMessageTests: XCTestCase {
    
    private static let config = Client.Config(apiKey: "client_silentMessageTests")
    private let config = Client_SilentMessageTests.config
    private var client: Client {
        Client(config: config)
    }
    
    func test_silentMessage_doesNotIncreaseUnreadCount() {
        let client = self.client
        
        let channel = client.channel(type: .messaging, id: "test-silent-message")
        
        var message = Message(text: "test", silent: true)
        message.user = User(id: "test-sender")
        
        let newMessageEvent = Event.messageNew(message, 0, channel.cid, .messageNew)
        
        assert(client.unreadCount.messages == 0)
        
        client.updateUserUnreadCount(event: newMessageEvent)
        
        XCTAssertEqual(client.unreadCount.messages, 0)
    }
    
    func test_silentMentionMessage_doesNotIncreaseUnreadCount() {
        let client = self.client
        client.userAtomic.set(.init(id: "test-mention"))
        
        let channel = client.channel(type: .messaging, id: "test-silent-message")
        
        var message = Message(text: "test", silent: true, mentionedUsers: [User(id: "test-mention")])
        message.user = User(id: "test-sender")
        
        let newMessageEvent = Event.messageNew(message, 0, channel.cid, .messageNew)
        
        assert(client.unreadCount.messages == 0)
        
        client.updateUserUnreadCount(event: newMessageEvent)
        
        XCTAssertEqual(client.unreadCount.messages, 0)
    }
    
    func test_silentDeletedMessage_doesNotDecreaseUnreadCount() {
        let client = self.client
        
        let channel = client.channel(type: .messaging, id: "test-silent-message")
        
        var message = Message(text: "test", silent: true, mentionedUsers: [User(id: "test-mention")])
        message.user = User(id: "test-sender")
        
        let deletedMessageEvent = Event.messageDeleted(message, User(id: "test-sender"), channel.cid, .messageDeleted)
        
        client.unreadCountAtomic.set(.init(channels: 1, messages: 1))

        assert(client.unreadCount.messages == 1)
        
        client.updateUserUnreadCount(event: deletedMessageEvent)
        
        XCTAssertEqual(client.unreadCount.messages, 1)
    }
}
