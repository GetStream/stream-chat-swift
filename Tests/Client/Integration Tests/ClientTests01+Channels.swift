//
//  ClientTests01_Channels.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 16/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient



var websocketForUser2: WebSocket?

/// Test Flow:
///   - Create `user1` and `user2`.
///   - Create a team channel with id .
///   - Create a channel with 2 members.
///   - Send a message to channels.
///   - Get a message by id.
///   - Search a message.
///   - Add a reaction.
///   - Delete a reaction.
///   - Delete a message.
///   - Delete a channel.
final class ClientTests01_Channels: TestCase {
    
    enum StorageKey: String {
        case websocketForUser2
        case notificationAddedToChannel
        case notificationMessageNew
    }
    
    override var connectByDefault: Bool {
        return false
    }
    
    static let salt = Int.random(in: 1000...9999)
    static let cid = ChannelId(type: .team, id: "test_\(salt)")
    /// Temporary the search text changed from: `"Text \(Self.salt)"` to `"Text\(Self.salt)"`,
    /// because on the issue for the search of a text in direct message channels with spaces.
    static let messageText = "Text \(salt)"
    
    let member2 = User.user2.asMember
    
    func test01CreateUsers() {
        expect("setup users") { expectation in
            connect(withUser: .user2, token: .token2) {
                Client.shared.update(user: .user2) { result in
                    Client.shared.webSocket.disconnect()
                    StorageHelper.shared.add(Client.shared.webSocket, key: StorageKey.websocketForUser2.rawValue)
                    
                    if result.isSuccess {
                        self.connect(withUser: .user1, token: .token1) {
                            Client.shared.update(user: .user1) { result in
                                if result.isSuccess {
                                    expectation.fulfill()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        guard let websocketForUser2: WebSocket = StorageHelper.shared.value(key: StorageKey.websocketForUser2.rawValue) else {
            XCTFail("websocketForUser2 not found")
            return
        }
        
        expect("separate websocket for user2 connected") { expectation in
            websocketForUser2.onConnect = { connection in
                if case .connected = connection {
                    DispatchQueue.main.async { expectation.fulfill() }
                }
            }
            
            websocketForUser2.onEvent = { event in
                print("🌈🦄", websocketForUser2.lastConnectionId, event.user?.id, event)
                
                if case .notificationAddedToChannel = event {
                    StorageHelper.shared.increment(key: StorageKey.notificationAddedToChannel.rawValue)
                }
                
                if case .messageNew(_, _, _, _, _, let eventType) = event, case .notificationMessageNew = eventType {
                    StorageHelper.shared.increment(key: StorageKey.notificationMessageNew.rawValue)
                }
            }

            websocketForUser2.connect()
        }
    }
    
    func test02CreateChannel() {
        var createdChannel: Channel?
        
        expect("a new channel") { expectation in
            let channel = Channel(type: .team, id: Self.cid.id)
            channel.members.insert(User.user1.asMember)
            channel.query(options: .all) {
                if let value = $0.value {
                    XCTAssertEqual(channel.cid, value.channel.cid)
                    createdChannel = value.channel
                    expectation.fulfill()
                }
            }
        }
        
        XCTAssertNotNil(createdChannel)
        addMember(to: createdChannel!)
        sendMessage(createdChannel!)
        removeMember(to: createdChannel!)
        deleteChannel(createdChannel!)
    }
    
    func addMember(to channel: Channel) {
        expect("added a member2") { expectation in
            channel.add(member2) {
                if let response = $0.value {
                    XCTAssertTrue(response.channel.members.contains(self.member2))
                    expectation.fulfill()
                }
            }
        }
    }
    
    func removeMember(to channel: Channel) {
        expect("removed a member2") { expectation in
            channel.remove(member2) {
                if let response = $0.value {
                    XCTAssertFalse(response.channel.members.contains(self.member2))
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test03CreateChannel1By1() {
        var createdChannel: Channel?
        
        expect("a 1 by 1 channel") { expectation in
            let channel = Channel(type: .messaging, with: User.user2.asMember)
            channel.create {
                if let value = $0.value {
                    XCTAssertTrue(value.channel.isDirectMessage)
                    XCTAssertEqual(value.channel.members.count, 2)
                    XCTAssertTrue(value.channel.members.contains(User.user1.asMember))
                    XCTAssertTrue(value.channel.members.contains(User.user2.asMember))
                    createdChannel = value.channel
                    expectation.fulfill()
                }
            }
        }
        
        XCTAssertNotNil(createdChannel)
        sendMessage(createdChannel!)
        deleteChannel(createdChannel!)
    }
    
    func test04WebSocketEvents() {
        XCTAssertEqual(StorageHelper.shared.value(key: StorageKey.notificationMessageNew.rawValue), 2)
        XCTAssertEqual(StorageHelper.shared.value(key: StorageKey.notificationAddedToChannel.rawValue), 2)
    }
    
    func sendMessage(_ channel: Channel) {
        var createdMessage: Message?
        
        expect("a message sent") { expectation in
            let message = Message(text: Self.messageText)
            channel.send(message: message) {
                if let response = $0.value {
                    XCTAssertEqual(response.message.text, message.text)
                    createdMessage = response.message
                    expectation.fulfill()
                }
            }
        }
        
        XCTAssertNotNil(createdMessage)
        getMessage(by: createdMessage!.id)
//        searchText()
        addReaction(createdMessage!)
        deleteMessage(createdMessage!)
    }
    
    func searchText() {
        expect("a message with text") { expectation in
            Client.shared.search(filter: .currentUserInMembers(), query: Self.messageText) {
                if let messages = try? $0.get() {
                    XCTAssertFalse(messages.isEmpty)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func queryChannels() {
        expect("channels with current user member") { expectation in
            let query = ChannelsQuery(pagination: .limit(2))
            Client.shared.queryChannels(query) { result in
                if let channelResponses = try? result.get() {
                    XCTAssertEqual(channelResponses.count, 2)
                    channelResponses.forEach { XCTAssertTrue($0.channel.cid == Self.cid || $0.channel.isDirectMessage) }
                    expectation.fulfill()
                }
            }
        }
    }
    
    func getMessage(by messageId: String) {
        expect("a message by id: \"\(messageId)\"") { expectation in
            Client.shared.message(with: messageId) {
                if $0.isSuccess {
                    expectation.fulfill()
                }
            }
        }
    }
    
    func addReaction(_ message: Message) {
        var likedMessage: Message?
        
        expect("a message with reaction like") { expectation in
            message.addReaction(.like) { result in
                if let response = try? result.get() {
                    XCTAssertEqual(response.message.id, message.id)
                    XCTAssertNotEqual(response.message, message)
                    XCTAssertTrue(response.message.hasReactions)
                    XCTAssertNotNil(response.reaction)
                    XCTAssertEqual(response.reaction?.type, ReactionType.like)
                    likedMessage = response.message
                    expectation.fulfill()
                }
            }
        }
        
        XCTAssertNotNil(likedMessage)
        deleteReaction(likedMessage!)
    }
    
    func deleteReaction(_ message: Message) {
        expect("a message without deleted reaction like") { expectation in
            message.deleteReaction(.like) { result in
                if let response = try? result.get() {
                    XCTAssertEqual(response.message.id, message.id)
                    XCTAssertNotEqual(response.message, message)
                    XCTAssertFalse(response.message.hasReactions)
                    XCTAssertNotNil(response.reaction)
                    XCTAssertEqual(response.reaction?.type, ReactionType.like)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func deleteMessage(_ message: Message) {
        expect("a deleted message") { expectation in
            message.delete { result in
                if let response = try? result.get() {
                    XCTAssertEqual(response.message.id, message.id)
                    XCTAssertTrue(response.message.isDeleted)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func deleteChannel(_ channel: Channel) {
        expect("deleted channels") { expectation in
            channel.delete { result in
                if let channel = result.value {
                    XCTAssertEqual(channel.id, channel.id)
                    XCTAssertTrue(channel.isDeleted)
                    expectation.fulfill()
                }
            }
        }
    }
}
