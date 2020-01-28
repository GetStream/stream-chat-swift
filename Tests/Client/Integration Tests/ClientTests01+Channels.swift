//
//  ClientTests01_Channels.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 16/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

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
    
    static let salt = Int.random(in: 1000...9999)
    static let cid = ChannelId(type: .team, id: "test_\(salt)")
    /// Temporary the search text changed from: `"Text \(Self.salt)"` to `"Text\(Self.salt)"`,
    /// because on the issue for the search of a text in direct message channels with spaces.
    static let messageText = "Text \(salt)"
    
    let member2 = User.user2.asMember
    
    func test01CreateUsers() {
        let client1 = Client(apiKey: TestCase.apiKey,
                             baseURL: TestCase.baseURL,
                             callbackQueue: .main,
                             stayConnectedInBackground: false,
                             logOptions: .requestsInfo)
        
        let client2 = Client(apiKey: TestCase.apiKey,
                             baseURL: TestCase.baseURL,
                             callbackQueue: .main,
                             stayConnectedInBackground: false,
                             logOptions: .webSocketInfo)
        
        client2.onEvent = { event in
            if case .notificationAddedToChannel = event {
                StorageHelper.shared.increment(key: .notificationAddedToChannel)
            }
            
            if case .messageNew(_, _, _, _, _, let eventType) = event, case .notificationMessageNew = eventType {
                StorageHelper.shared.increment(key: .notificationMessageNew)
            }
        }

        StorageHelper.shared.add(client1, key: .client1)
        StorageHelper.shared.add(client2, key: .client2)
        
        expect("setup user1") { expectation in
            connect(client1, user: .user1, token: .token1) { [weak client1] in
                client1?.update(users: [.user1, .user2]) {
                    if $0.isSuccess {
                        expectation.fulfill()
                    }
                }
            }
        }

        expect("setup user2") { expectation in
            connect(client2, user: .user2, token: .token2) { [weak client2] in
                client2?.update(user: .user2) {
                    if $0.isSuccess {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        createChannel(client1)
        createChannel1By1(client1)
    }
    
    func test02WebSocketEvents() {
        XCTAssertEqual(StorageHelper.shared.value(key: .notificationMessageNew), 2)
        XCTAssertEqual(StorageHelper.shared.value(key: .notificationAddedToChannel), 2)
    }
    
    func createChannel(_ client: Client) {
        var createdChannel: Channel?
        
        expect("a new channel") { expectation in
            let channel = Channel(type: .team, id: Self.cid.id)
            channel.members.insert(User.user1.asMember)
            channel.query(options: .all, client: client) {
                if let value = $0.value {
                    XCTAssertEqual(channel.cid, value.channel.cid)
                    createdChannel = value.channel
                    expectation.fulfill()
                }
            }
        }
        
        XCTAssertNotNil(createdChannel)
        addMember(to: createdChannel!, client)
        sendMessage(createdChannel!, client)
        removeMember(to: createdChannel!, client)
        deleteChannel(createdChannel!, client)
    }
    
    func addMember(to channel: Channel, _ client: Client) {
        expect("added a member2") { expectation in
            channel.add([member2], client: client) {
                if let response = $0.value {
                    XCTAssertTrue(response.channel.members.contains(self.member2))
                    expectation.fulfill()
                }
            }
        }
    }
    
    func removeMember(to channel: Channel, _ client: Client) {
        expect("removed a member2") { expectation in
            channel.remove([member2], client: client) {
                if let response = $0.value {
                    XCTAssertFalse(response.channel.members.contains(self.member2))
                    expectation.fulfill()
                }
            }
        }
    }
    
    func createChannel1By1(_ client: Client) {
        var createdChannel: Channel?
        
        expect("a 1 by 1 channel") { expectation in
            let channel = Channel(type: .messaging, with: User.user2.asMember, currentUser: client.user)
            channel.query(options: .all, client: client) {
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
        sendMessage(createdChannel!, client)
        deleteChannel(createdChannel!, client)
    }
    
    func sendMessage(_ channel: Channel, _ client: Client) {
        var createdMessage: Message?
        
        expect("a message sent") { expectation in
            let message = Message(text: Self.messageText)
            channel.send(message: message, client: client) {
                if let response = $0.value {
                    XCTAssertEqual(response.message.text, message.text)
                    createdMessage = response.message
                    expectation.fulfill()
                }
            }
        }
        
        XCTAssertNotNil(createdMessage)
        getMessage(by: createdMessage!.id, client)
        queryChannels(client)
//        searchText(client)
        addReaction(createdMessage!, client)
        deleteMessage(createdMessage!, client)
    }
    
    func getMessage(by messageId: String, _ client: Client) {
        expect("a message by id: \"\(messageId)\"") { expectation in
            client.message(with: messageId) {
                if $0.isSuccess {
                    expectation.fulfill()
                }
            }
        }
    }
    
    func queryChannels(_ client: Client) {
        expect("channels with current user member") { expectation in
            let query = ChannelsQuery(pagination: .limit(1))
            client.queryChannels(query) { result in
                if let channelResponses = try? result.get() {
                    XCTAssertEqual(channelResponses.count, 1)
                    channelResponses.forEach { XCTAssertTrue($0.channel.cid == Self.cid || $0.channel.isDirectMessage) }
                    expectation.fulfill()
                }
            }
        }
    }
    
    func searchText(_ client: Client) {
        expect("a message with text") { expectation in
            client.search(filter: .currentUserInMembers(), query: Self.messageText) {
                if let messages = try? $0.get() {
                    XCTAssertFalse(messages.isEmpty)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func addReaction(_ message: Message, _ client: Client) {
        var likedMessage: Message?
        
        expect("a message with reaction like") { expectation in
            message.addReaction(.like, client: client) { result in
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
        deleteReaction(likedMessage!, client)
    }
    
    func deleteReaction(_ message: Message, _ client: Client) {
        expect("a message without deleted reaction like") { expectation in
            message.deleteReaction(.like, client: client) { result in
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
    
    func deleteMessage(_ message: Message, _ client: Client) {
        expect("a deleted message") { expectation in
            message.delete(client: client) { result in
                if let response = try? result.get() {
                    XCTAssertEqual(response.message.id, message.id)
                    XCTAssertTrue(response.message.isDeleted)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func deleteChannel(_ channel: Channel, _ client: Client) {
        expect("deleted channels") { expectation in
            channel.delete(client: client) { result in
                if let channel = result.value {
                    XCTAssertEqual(channel.id, channel.id)
                    XCTAssertTrue(channel.isDeleted)
                    expectation.fulfill()
                }
            }
        }
    }
}
