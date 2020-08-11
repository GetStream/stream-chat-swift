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
///   - Create `user1` and `user2` and mark all messages and channels as read.
///   - `user2` use shared Client.
///   - `user1`: Create a team channel with id.
///   - `user1`: Send message1.
///   - `user1`: Get the message1 by id.
///   - `user1`: Add a reaction for the message1.
///   - `user1`: Delete a reaction for the message1.
///   - `user1`: Add a `user2` to the channel.
///   - `user1`: Check the channel was updated by event.
///   - `user1`: Send message2 for both members.
///   - `user1`: Send message3 for both members and mention `user2`.
///   - `user2`: Query from user2 for a channel.
///   - `user2`: Check unread messages for a channel.
///   - `user2`: Mark messages as read.
///   - `user1`: Create a channel 1-by-1 with `user2`.
///   - `user1`: Send message1vs1.
///   - `user1`: Send message1vs1 with mentioning `user2`.
///   - Checks all changes for the `user2` unread counts.
///   - Checks web scoket events for new messages and added to channel counts.
///   - Delete all messages.
///   - Delete all channels.
final class ClientTests01_Channels: TestCase {
    
    /// Temporary the search text changed from: `"Text \(Self.salt)"` to `"Text\(Self.salt)"`,
    /// because on the issue for the search of a text in direct message channels with spaces.
    static let messageText = "Text \(UUID().uuidString)"
    let loveReactionType = "love"
    
    let unreadCounts: [UnreadCount] = [.init(channels: 0, messages: 0),
                                       .init(channels: 1, messages: 1),
                                       .init(channels: 1, messages: 2),
                                       .init(channels: 1, messages: 3),
                                       .init(channels: 0, messages: 0),
                                       .init(channels: 1, messages: 1),
                                       .init(channels: 1, messages: 2)]
    
    let subscriptionBag = SubscriptionBag()
    
    func test01BigFlow() {
        // MARK: User 1
        
        let client1 = Client(config: .init(
            apiKey: TestCase.apiKey,
            baseURL: TestCase.baseURL,
            stayConnectedInBackground: false,
            callbackQueue: .main,
            logOptions: []
        ))
        
        StorageHelper.shared.add(client1, key: .client1)
        
        expect("setup user1") { expectation in
            connect(client1, user: .user1, token: .token1) { [weak client1] in
                client1?.update(user: .user1) {
                    if $0.isSuccess {
                        client1?.markAllRead {
                            if $0.isSuccess {
                                expectation.fulfill()
                            }
                        }
                    }
                }
            }
        }
        
        // MARK: User 2
        
        expect("setup user2") { expectation in
            connect(Client.shared, user: .user2, token: .token2) {
                Client.shared.update(user: .user2) {
                    if $0.isSuccess {
                        Client.shared.markAllRead {
                            if $0.isSuccess {
                                expectation.fulfill()
                            }
                        }
                    }
                }
            }
        }
        
        let subscriptionNotifications = Client.shared.subscribe { event in
            DispatchQueue.main.async {
                if case .notificationAddedToChannel = event {
                    StorageHelper.shared.increment(key: .notificationAddedToChannel)
                }
                
                if case .notificationMessageNew = event {
                    StorageHelper.shared.increment(key: .notificationMessageNew)
                }
            }
        }
        
        let unreadCountSubscription = Client.shared.subscribeToUnreadCount { unreadCount in
            DispatchQueue.main.async {
                StorageHelper.shared.append(unreadCount, key: .user2UnreadCounts)
            }
        }
        
        subscriptionBag.add(subscriptionNotifications)
        subscriptionBag.add(unreadCountSubscription)
        
        XCTAssertTrue(client1.isConnected)
        XCTAssertTrue(Client.shared.isConnected)

        let cid = ChannelId(type: .team, id: UUID().uuidString)
        createChannel(client1, cid: cid, mentionedUser: Client.shared.user)
        queryChannels(client1, cid: cid)
        checkUnreadCountFromQuery(Client.shared, cid: cid)
        createChannel1By1(client1, anotherUser: Client.shared.user)
        
        // Wait for all events and finish the big flow.
        if let unreadCounts: [UnreadCount] = StorageHelper.shared.value(key: .user2UnreadCounts),
            unreadCounts.count < self.unreadCounts.count {
            expect("finished big flow with \(self.unreadCounts.count) notification events") { expectation in
                var subscription: Cancellable?
                
                subscription = Client.shared.subscribeToUnreadCount { _ in
                    DispatchQueue.main.async {
                        if let unreadCounts: [UnreadCount] = StorageHelper.shared.value(key: .user2UnreadCounts),
                            unreadCounts.count == self.unreadCounts.count {
                            subscription?.cancel()
                            expectation.fulfill()
                        }
                    }
                }
            }
        }
    }
    
    func checkUnreadCountFromQuery(_ client: Client, cid: ChannelId) {
        var createdChannel: Channel?
        
        // Check channel for unread messages.
        expect("get a channel by cid with unread count") { expectation in
            let channel = client.channel(type: cid.type, id: cid.id)
            client.queryChannel(channel, options: .all) {
                    if let response = $0.value {
                        XCTAssertEqual(response.messages.count, 3)
                        XCTAssertEqual(response.channel.unreadCount, ChannelUnreadCount(messages: 3, mentionedMessages: 1))
                        createdChannel = response.channel
                        expectation.fulfill()
                    }
            }
        }
        
        XCTAssertNotNil(createdChannel)
        
        // Mark channel as read.
        expect("messages read") { expectation in
            client.markRead(channel: createdChannel!) { result in
                if result.value != nil {
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test10WebSocketEvents() {
        XCTAssertEqual(StorageHelper.shared.value(key: .notificationMessageNew), 5)
        XCTAssertEqual(StorageHelper.shared.value(key: .notificationAddedToChannel), 2)
    }
    
    func test11CleanUp() {
        guard let client1: Client = StorageHelper.shared.value(key: .client1) else {
            XCTFail("Client1 unread counts not found")
            return
        }
        
        guard let deleteChannels: [Channel] = StorageHelper.shared.value(key: .deleteChannels) else {
            XCTFail("Channels for deleting not found")
            return
        }
        
        guard let deleteMessages: [Message] = StorageHelper.shared.value(key: .deleteMessages) else {
            XCTFail("Messages for deleting not found")
            return
        }
        
        deleteMessages.forEach { self.deleteMessage($0, client1) }
        
        deleteChannels.forEach {
            if !$0.isDirectMessage {
                self.removeMember(Client.shared.user, from: $0, client1)
            }
            
            self.deleteChannel($0, client1)
        }
        
        subscriptionBag.cancel()
    }
    
    func test04CheckUnreadCount() {
        guard let unreadCounts: [UnreadCount] = StorageHelper.shared.value(key: .user2UnreadCounts) else {
            XCTFail("User2 unread counts not found")
            return
        }
        
        XCTAssertEqual(unreadCounts, self.unreadCounts)
    }
    
    func createChannel(_ client: Client, cid: ChannelId, mentionedUser: User) {
        var createdChannel: Channel?
        
        expect("a new channel") { expectation in
            let channel = client.channel(type: cid.type, id: cid.id, members: [client.user, mentionedUser])
            client.queryChannel(channel, options: .all) {
                    if let value = $0.value {
                        XCTAssertEqual(cid, value.channel.cid)
                        createdChannel = value.channel
                        expectation.fulfill()
                    }
            }
        }
        
        XCTAssertNotNil(createdChannel)
        let message = sendMessage("Message1 \(UUID().uuidString)", channel: createdChannel!, client)
        getMessage(by: message.id, client)
        // TODO: searchText(client)
        addReaction(message, client)
        
        // Checks if the channel will be updated when member added.
        var channelUpdatedExpectation: XCTestExpectation?
        
        func updateChannelUpdatedExpectation() {
            channelUpdatedExpectation?.fulfill()
        }
        
        let subscription = client.subscribe { event in
            if case .channelUpdated(let updatedResponse, _, _) = event {
                XCTAssertEqual(updatedResponse.channel, createdChannel)
                createdChannel = updatedResponse.channel
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: updateChannelUpdatedExpectation)
            }
        }
        
        addMember(mentionedUser, to: createdChannel!, client)
        
        expect("a channel was updated") { channelUpdatedExpectation = $0 }
        subscription.cancel()
        
        sendMessage("Message2 \(UUID().uuidString)", channel: createdChannel!, client)
        sendMessage("Message3 @\(mentionedUser.name) \(UUID().uuidString)", channel: createdChannel!, client)
        StorageHelper.shared.append(createdChannel, key: .deleteChannels)
    }
    
    func addMember(_ user: User, to channel: Channel, _ client: Client) {
        expect("added a member2") { expectation in
            client.add(user: user, to: channel) {
                if let response = $0.value {
                    XCTAssertTrue(response.channel.members.contains(user.asMember))
                    expectation.fulfill()
                }
            }
        }
    }
    
    func removeMember(_ user: User, from channel: Channel, _ client: Client) {
        expect("removed a member2") { expectation in
            client.remove(user: user, from: channel) {
                if let response = $0.value {
                    XCTAssertFalse(response.channel.members.contains(user.asMember))
                    expectation.fulfill()
                }
            }
        }
    }
    
    func createChannel1By1(_ client: Client, anotherUser: User) {
        var createdChannel: Channel?
        
        expect("a 1 by 1 channel") { expectation in
            let channel = client.channel(members: [client.user, anotherUser])
            client.queryChannel(channel, options: .all) { [unowned client] in
                if let value = $0.value {
                    XCTAssertTrue(value.channel.isDirectMessage)
                    XCTAssertEqual(value.channel.members.count, 2)
                    XCTAssertTrue(value.channel.members.contains(client.user.asMember))
                    XCTAssertTrue(value.channel.members.contains(anotherUser.asMember))
                    createdChannel = value.channel
                    expectation.fulfill()
                }
            }
        }
        
        XCTAssertNotNil(createdChannel)
        sendMessage("Message1vs1 \(UUID().uuidString)", channel: createdChannel!, client)
        sendMessage("Message1vs1 @\(anotherUser.name) \(UUID().uuidString)", channel: createdChannel!, client)
        StorageHelper.shared.append(createdChannel, key: .deleteChannels)
    }
    
    @discardableResult
    func sendMessage(_ text: String, channel: Channel, _ client: Client) -> Message {
        var createdMessage: Message?
        
        expect("a message sent") { expectation in
            let message = Message(text: text)
            client.send(message: message, to: channel) {
                if let response = $0.value {
                    XCTAssertEqual(response.message.text, text)
                    createdMessage = response.message
                    expectation.fulfill()
                }
            }
        }
        
        XCTAssertNotNil(createdMessage)
        StorageHelper.shared.append(createdMessage, key: .deleteMessages)
        
        return createdMessage!
    }
    
    func getMessage(by messageId: String, _ client: Client) {
        expect("a message by id: \"\(messageId)\"") { expectation in
            client.message(withId: messageId) {
                if $0.isSuccess {
                    expectation.fulfill()
                }
            }
        }
    }
    
    func queryChannels(_ client: Client, cid: ChannelId) {
        expect("channels with current user member") { expectation in
            client.queryChannels(filter: .currentUserInMembers, pagination: [.limit(1)]) { result in
                if let channelResponses = try? result.get() {
                    XCTAssertEqual(channelResponses.count, 1)
                    channelResponses.forEach { XCTAssertTrue($0.channel.cid == cid || $0.channel.isDirectMessage) }
                    expectation.fulfill()
                }
            }
        }
    }
    
    func searchText(_ client: Client) {
        expect("a message with text") { expectation in
            client.search(filter: .currentUserInMembers, query: Self.messageText) {
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
            client.addReaction(type: loveReactionType, to: message) { result in
                if let response = try? result.get() {
                    XCTAssertEqual(response.message.id, message.id)
                    XCTAssertNotEqual(response.message, message)
                    XCTAssertTrue(response.message.hasReactions)
                    XCTAssertNotNil(response.reaction)
                    XCTAssertEqual(response.reaction?.type, self.loveReactionType)
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
            client.deleteReaction(type: loveReactionType, from: message) { result in
                if let response = try? result.get() {
                    XCTAssertEqual(response.message.id, message.id)
                    XCTAssertNotEqual(response.message, message)
                    XCTAssertFalse(response.message.hasReactions)
                    XCTAssertNotNil(response.reaction)
                    XCTAssertEqual(response.reaction?.type, self.loveReactionType)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func deleteMessage(_ message: Message, _ client: Client) {
        expect("a deleted message") { expectation in
            client.delete(message: message) { result in
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
            client.delete(channel: channel) { result in
                if let channel = result.value {
                    XCTAssertEqual(channel.id, channel.id)
                    XCTAssertTrue(channel.isDeleted)
                    expectation.fulfill()
                }
            }
        }
    }
}
