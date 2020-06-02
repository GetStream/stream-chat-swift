//
//  Channel+SilentMessageTests.swift
//  StreamChatClientTests
//
//  Created by Bahadir Oncel on 12.05.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

class Channel_SilentMessageTests: XCTestCase {
    
    let client = sharedClient
    
    override func setUp() {
        super.setUp()
        
        client.unreadCountAtomic.set(.noUnread)
    }
    
    func test_silentMessage_doesNotIncreaseUnreadCount() {
        let channel = client.channel(type: .messaging, id: "test-silent-message")
        
        let message = Message(text: "test", silent: true, user: .init(id: "test-sender"))
        
        let newMessageEvent = Event.messageNew(message, 0, channel.cid, .messageNew)
        
        assert(channel.unreadCount.mentionedMessages == 0)
        assert(channel.unreadCount.messages == 0)
        
        channel.updateUnreadCount(event: newMessageEvent)
        
        XCTAssertEqual(channel.unreadCount.messages, 0)
    }
    
    func test_silentMentionMessage_doesNotIncreaseUnreadCount() {
        client.userAtomic.set(.init(id: "test-mention"))
        
        let channel = client.channel(type: .messaging, id: "test-silent-message")
        
        let message = Message(text: "test", silent: true, user: .init(id: "test-sender"), mentionedUsers: [User(id: "test-mention")])
        
        let newMessageEvent = Event.messageNew(message, 0, channel.cid, .messageNew)
        
        assert(channel.unreadCount.mentionedMessages == 0)
        assert(channel.unreadCount.messages == 0)
        
        channel.updateUnreadCount(event: newMessageEvent)
        
        XCTAssertEqual(channel.unreadCount.messages, 0)
        XCTAssertEqual(channel.unreadCount.mentionedMessages, 0)
    }
    
    func test_silentDeletedMessage_doesNotDecreaseUnreadCount() {
        let channel = client.channel(type: .messaging, id: "test-silent-message")
        
        let message = Message(text: "test", silent: true, user: .init(id: "test-sender"), mentionedUsers: [User(id: "test-mention")])
        
        let deletedMessageEvent = Event.messageDeleted(message, User(id: "test-sender"), channel.cid, .messageDeleted)
        
        channel.unreadCountAtomic.set(.init(messages: 1, mentionedMessages: 1))
        
        assert(channel.unreadCount.mentionedMessages == 1)
        assert(channel.unreadCount.messages == 1)
        
        channel.updateUnreadCount(event: deletedMessageEvent)
        
        XCTAssertEqual(channel.unreadCount.messages, 1)
        XCTAssertEqual(channel.unreadCount.mentionedMessages, 1)
    }
    
    func test_channelResponse_calculateUnreadCount_disregardsSilentMessages() throws {
        // Set current user to mentioned user
        sharedClient.userAtomic.set(.init(id: "steep-moon-9"))
        
        let channelResponse = try! JSONDecoder.stream.decode(ChannelResponse.self, from: Data(sampleChannelResponse.utf8))
        
        XCTAssertEqual(channelResponse.channel.unreadCount.messages, 1) // Because response has 1, sent from server
        XCTAssertEqual(channelResponse.channel.unreadCount.mentionedMessages, 0) // Calculated in client
    }
    
    // The test `test_channelResponse_calculateUnreadCount_disregardsSilentMessages` will fail if line 94
    // silent: true
    // is changed to false, as expected
    private let sampleChannelResponse = """
    {
        "messages": [
            {
                "id": "061b5da4-111c-464f-a855-972b83479a1f",
                "reaction_counts": {},
                "silent": true,
                "created_at": "2020-05-12T12:42:56.450979Z",
                "reaction_scores": {},
                "type": "regular",
                "latest_reactions": [],
                "text": "@steep-moon-9 hello",
                "attachments": [],
                "own_reactions": [],
                "updated_at": "2020-05-12T12:42:56.450979Z",
                "reply_count": 0,
                "user": {
                    "banned": false,
                    "online": true,
                    "id": "broken-waterfall-5",
                    "role": "user",
                    "created_at": "2019-03-08T14:45:03.243237Z",
                    "image": "https:////getstream.io//random_svg//?id=broken-waterfall-5&amp;name=Broken+waterfall",
                    "updated_at": "2020-05-12T12:22:29.788007Z",
                    "last_active": "2020-05-12T12:16:00.498889Z",
                    "name": "broken-waterfall-5"
                },
                "mentioned_users": [
                    {
                        "banned": false,
                        "online": true,
                        "test": 1,
                        "id": "steep-moon-9",
                        "role": "user",
                        "created_at": "2019-06-05T15:01:52.847807Z",
                        "image": "https:////i.imgur.com//EgEPqWZ.jpg",
                        "updated_at": "2020-05-12T12:13:01.306955Z",
                        "last_active": "2020-05-12T12:13:01.30335Z",
                        "name": "steep-moon-9"
                    }
                ],
                "html": "<p>@steep-moon-9 hello<//p>\\n"
            }
        ],
        "watcher_count": 2,
        "channel": {
            "last_message_at": "2020-05-12T12:42:56.450979Z",
            "created_by": {
                "banned": false,
                "online": true,
                "id": "broken-waterfall-5",
                "role": "user",
                "created_at": "2019-03-08T14:45:03.243237Z",
                "image": "https:////getstream.io//random_svg//?id=broken-waterfall-5&amp;name=Broken+waterfall",
                "updated_at": "2020-05-12T12:22:29.788007Z",
                "last_active": "2020-05-12T12:16:00.498889Z",
                "name": "broken-waterfall-5"
            },
            "frozen": false,
            "id": "test-silent",
            "created_at": "2020-05-12T12:16:01.128713Z",
            "member_count": 2,
            "config": {
                "automod_behavior": "flag",
                "reactions": true,
                "typing_events": true,
                "mutes": true,
                "max_message_length": 5000,
                "created_at": "2019-03-21T15:49:15.40182Z",
                "automod": "AI",
                "read_events": true,
                "commands": [
                    {
                        "set": "fun_set",
                        "args": "[text]",
                        "name": "giphy",
                        "description": "Post a random gif to the channel"
                    }
                ],
                "connect_events": true,
                "replies": true,
                "updated_at": "2020-03-17T18:54:09.460881Z",
                "url_enrichment": true,
                "search": false,
                "message_retention": "infinite",
                "uploads": true,
                "name": "messaging"
            },
            "type": "messaging",
            "updated_at": "2020-05-12T12:16:01.128713Z",
            "cid": "messaging:test-silent"
        },
        "read": [
            {
                "unread_messages": 0,
                "user": {
                    "banned": false,
                    "online": true,
                    "id": "broken-waterfall-5",
                    "role": "user",
                    "created_at": "2019-03-08T14:45:03.243237Z",
                    "image": "https:////getstream.io//random_svg//?id=broken-waterfall-5&amp;name=Broken+waterfall",
                    "updated_at": "2020-05-12T12:22:29.788007Z",
                    "last_active": "2020-05-12T12:16:00.498889Z",
                    "name": "broken-waterfall-5"
                },
                "last_read": "2020-05-12T12:27:50.38323072Z"
            },
            {
                "unread_messages": 1,
                "user": {
                    "banned": false,
                    "online": true,
                    "test": 1,
                    "id": "steep-moon-9",
                    "role": "user",
                    "created_at": "2019-06-05T15:01:52.847807Z",
                    "image": "https:////i.imgur.com//EgEPqWZ.jpg",
                    "updated_at": "2020-05-12T12:13:01.306955Z",
                    "last_active": "2020-05-12T12:13:01.30335Z",
                    "name": "steep-moon-9"
                },
                "last_read": "2020-05-12T12:16:01.14596864Z"
            }
        ],
        "members": [
            {
                "created_at": "2020-05-12T12:16:01.132467Z",
                "updated_at": "2020-05-12T12:16:01.132467Z",
                "role": "owner",
                "user": {
                    "banned": false,
                    "online": true,
                    "id": "broken-waterfall-5",
                    "role": "user",
                    "created_at": "2019-03-08T14:45:03.243237Z",
                    "image": "https:////getstream.io//random_svg//?id=broken-waterfall-5&amp;name=Broken+waterfall",
                    "updated_at": "2020-05-12T12:22:29.788007Z",
                    "last_active": "2020-05-12T12:16:00.498889Z",
                    "name": "broken-waterfall-5"
                }
            },
            {
                "created_at": "2020-05-12T12:16:01.132467Z",
                "updated_at": "2020-05-12T12:16:01.132467Z",
                "role": "member",
                "user": {
                    "banned": false,
                    "online": true,
                    "test": 1,
                    "id": "steep-moon-9",
                    "role": "user",
                    "created_at": "2019-06-05T15:01:52.847807Z",
                    "image": "https:////i.imgur.com//EgEPqWZ.jpg",
                    "updated_at": "2020-05-12T12:13:01.306955Z",
                    "last_active": "2020-05-12T12:13:01.30335Z",
                    "name": "steep-moon-9"
                }
            }
        ],
        "membership": {
            "created_at": "2020-05-12T12:16:01.132467Z",
            "updated_at": "2020-05-12T12:16:01.132467Z",
            "role": "channel_member",
            "user": {
                "banned": false,
                "online": true,
                "id": "broken-waterfall-5",
                "role": "user",
                "created_at": "2019-03-08T14:45:03.243237Z",
                "image": "https:////getstream.io//random_svg//?id=broken-waterfall-5&amp;name=Broken+waterfall",
                "updated_at": "2020-05-12T12:22:29.788007Z",
                "last_active": "2020-05-12T12:16:00.498889Z",
                "name": "broken-waterfall-5"
            }
        }
    }
    """
}
