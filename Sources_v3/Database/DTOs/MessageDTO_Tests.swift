//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class MessageDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_messagePayload_isStoredAndLoadedFromDB() {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<DefaultExtraData> = dummyPayload(with: channelId)
        
        let messagePayload: MessagePayload<DefaultExtraData> = .dummy(messageId: messageId, authorUserId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        var loadedMessage: MessageDTO? {
            database.viewContext.message(id: messageId)
        }
        
        AssertAsync {
            Assert.willBeEqual(messagePayload.id, loadedMessage?.id)
            Assert.willBeEqual(messagePayload.type.rawValue, loadedMessage?.type)
            Assert.willBeEqual(messagePayload.user.id, loadedMessage?.user.id)
            Assert.willBeEqual(messagePayload.createdAt, loadedMessage?.createdAt)
            Assert.willBeEqual(messagePayload.updatedAt, loadedMessage?.updatedAt)
            Assert.willBeEqual(messagePayload.deletedAt, loadedMessage?.deletedAt)
            Assert.willBeEqual(messagePayload.text, loadedMessage?.text)
//            Assert.willBeEqual(loadedMessage?.command, messagePayload.command)
//            Assert.willBeEqual(loadedMessage?.args, messagePayload.args)
            Assert.willBeEqual(messagePayload.parentId, loadedMessage?.parentMessageId)
            Assert.willBeEqual(messagePayload.showReplyInChannel, loadedMessage?.showReplyInChannel)
            Assert.willBeEqual(
                messagePayload.mentionedUsers.map(\.id),
                loadedMessage?.mentionedUsers.map(\.id)
            )
            Assert.willBeEqual(Int32(messagePayload.replyCount), loadedMessage?.replyCount)
            Assert.willBeEqual(messagePayload.extraData, loadedMessage.map {
                try? JSONDecoder.default.decode(NoExtraData.self, from: $0.extraData)
            })
            Assert.willBeEqual(messagePayload.reactionScores, loadedMessage?.reactionScores)
            Assert.willBeEqual(messagePayload.isSilent, loadedMessage?.isSilent)
        }
    }
    
    func test_messagePayload_withExtraData_isStoredAndLoadedFromDB() {
        struct DeathStarMetadata: MessageExtraData {
            static var defaultValue: DeathStarMetadata = .init(isSectedDeathStarPlanIncluded: false)
            
            let isSectedDeathStarPlanIncluded: Bool
        }
        
        enum SecretExtraData: ExtraDataTypes {
            typealias Message = DeathStarMetadata
        }
        
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<DefaultExtraData> = dummyPayload(with: channelId)
        
        let messagePayload: MessagePayload<SecretExtraData> = .dummy(
            messageId: messageId,
            authorUserId: userId,
            extraData: DeathStarMetadata(isSectedDeathStarPlanIncluded: true)
        )
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        var loadedMessage: MessageDTO? {
            database.viewContext.message(id: messageId)
        }
        
        AssertAsync {
            Assert.willBeEqual(messagePayload.id, loadedMessage?.id)
            Assert.willBeEqual(messagePayload.type.rawValue, loadedMessage?.type)
            Assert.willBeEqual(messagePayload.user.id, loadedMessage?.user.id)
            Assert.willBeEqual(messagePayload.createdAt, loadedMessage?.createdAt)
            Assert.willBeEqual(messagePayload.updatedAt, loadedMessage?.updatedAt)
            Assert.willBeEqual(messagePayload.deletedAt, loadedMessage?.deletedAt)
            Assert.willBeEqual(messagePayload.text, loadedMessage?.text)
            //            Assert.willBeEqual(loadedMessage?.command, messagePayload.command)
            //            Assert.willBeEqual(loadedMessage?.args, messagePayload.args)
            Assert.willBeEqual(messagePayload.parentId, loadedMessage?.parentMessageId)
            Assert.willBeEqual(messagePayload.showReplyInChannel, loadedMessage?.showReplyInChannel)
            Assert.willBeEqual(
                messagePayload.mentionedUsers.map(\.id),
                loadedMessage?.mentionedUsers.map(\.id)
            )
            Assert.willBeEqual(Int32(messagePayload.replyCount), loadedMessage?.replyCount)
            Assert.willBeEqual(messagePayload.extraData, loadedMessage.map {
                try? JSONDecoder.default.decode(DeathStarMetadata.self, from: $0.extraData)
            })
            Assert.willBeEqual(messagePayload.reactionScores, loadedMessage?.reactionScores)
            Assert.willBeEqual(messagePayload.isSilent, loadedMessage?.isSilent)
        }
    }
    
    func test_messagePayload_asModel() {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<DefaultExtraData> = dummyPayload(with: channelId)
        
        let messagePayload: MessagePayload<DefaultExtraData> = .dummy(messageId: messageId, authorUserId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        var loadedMessage: _ChatMessage<DefaultExtraData>? {
            database.viewContext.message(id: messageId)?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(loadedMessage?.id, messagePayload.id)
            Assert.willBeEqual(loadedMessage?.type, messagePayload.type)
            Assert.willBeEqual(loadedMessage?.author.id, messagePayload.user.id)
            Assert.willBeEqual(loadedMessage?.createdAt, messagePayload.createdAt)
            Assert.willBeEqual(loadedMessage?.updatedAt, messagePayload.updatedAt)
            Assert.willBeEqual(loadedMessage?.deletedAt, messagePayload.deletedAt)
            Assert.willBeEqual(loadedMessage?.text, messagePayload.text)
            Assert.willBeEqual(loadedMessage?.command, messagePayload.command)
            Assert.willBeEqual(loadedMessage?.arguments, messagePayload.args)
            Assert.willBeEqual(loadedMessage?.parentMessageId, messagePayload.parentId)
            Assert.willBeEqual(loadedMessage?.showReplyInChannel, messagePayload.showReplyInChannel)
            Assert.willBeEqual(loadedMessage?.mentionedUsers.map(\.id), messagePayload.mentionedUsers.map(\.id))
            Assert.willBeEqual(loadedMessage?.replyCount, messagePayload.replyCount)
            Assert.willBeEqual(loadedMessage?.extraData, messagePayload.extraData)
            Assert.willBeEqual(loadedMessage?.reactionScores, messagePayload.reactionScores)
            Assert.willBeEqual(loadedMessage?.isSilent, messagePayload.isSilent)
        }
    }
    
    func test_messagePayload_asRequestBody() {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<DefaultExtraData> = dummyPayload(with: channelId)
        
        let messagePayload: MessagePayload<DefaultExtraData> = .dummy(messageId: messageId, authorUserId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        var loadedMessage: MessageRequestBody<DefaultExtraData>? {
            database.viewContext.message(id: messageId)?.asRequestBody()
        }
        
        AssertAsync {
            Assert.willBeEqual(loadedMessage?.id, messagePayload.id)
            Assert.willBeEqual(loadedMessage?.user.id, messagePayload.user.id)
            Assert.willBeEqual(loadedMessage?.text, messagePayload.text)
            Assert.willBeEqual(loadedMessage?.command, messagePayload.command)
            Assert.willBeEqual(loadedMessage?.args, messagePayload.args)
            Assert.willBeEqual(loadedMessage?.parentId, messagePayload.parentId)
            Assert.willBeEqual(loadedMessage?.showReplyInChannel, messagePayload.showReplyInChannel)
//            Assert.willBeEqual(loadedMessage?.mentionedUsers.map { $0.id }, messagePayload.mentionedUsers.map { $0.id })
            Assert.willBeEqual(loadedMessage?.extraData, messagePayload.extraData)
        }
    }
    
    func test_additionalLocalState_isStored() {
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<DefaultExtraData> = dummyPayload(with: channelId)
        let messagePayload: MessagePayload<DefaultExtraData> = .dummy(messageId: messageId, authorUserId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Set the local state of the message
        database.write {
            $0.message(id: messageId)?.localMessageState = .pendingSend
        }
        
        // Load the message from the db
        var loadedMessage: _ChatMessage<DefaultExtraData>? {
            database.viewContext.message(id: messageId)?.asModel()
        }
        
        // Assert the local state is set
        AssertAsync.willBeEqual(loadedMessage?.localState, .pendingSend)
        
        // Re-save the payload and check the local state is not overriden
        database.write { session in
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        AssertAsync.staysEqual(loadedMessage?.localState, .pendingSend)
        
        // Reset the local state and check it gets propagated
        database.write {
            $0.message(id: messageId)?.localMessageState = nil
        }
        AssertAsync.willBeNil(loadedMessage?.localState)
    }
    
    func test_defaultSortingKey_isAutomaticallyAssigned() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        _ = try await { completion in
            database.write({ (session) in
                try session.saveCurrentUser(payload: .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: NameAndImageExtraData(name: nil, imageURL: nil)
                ))
                
                try session.saveChannel(payload: self.dummyPayload(with: cid))
                
            }, completion: completion)
        }
        
        // Create two messages in the DB
        
        var message1Id: MessageId!
        var message2Id: MessageId!
        
        _ = try await { completion in
            database.write({ session in
                let message1DTO = try session.createNewMessage(
                    in: cid,
                    text: .unique,
                    command: nil,
                    arguments: nil,
                    parentMessageId: nil,
                    showReplyInChannel: false,
                    extraData: NoExtraData.defaultValue
                )
                message1Id = message1DTO.id
                // Assign locallyCreatedAt data do message 1
                message1DTO.locallyCreatedAt = .unique
                
                let message2DTO = try session.createNewMessage(
                    in: cid,
                    text: .unique,
                    command: nil,
                    arguments: nil,
                    parentMessageId: nil,
                    showReplyInChannel: false,
                    extraData: NoExtraData.defaultValue
                )
                message2Id = message2DTO.id
            }, completion: completion)
        }
        
        var message1: MessageDTO? {
            database.viewContext.message(id: message1Id)
        }
        
        var message2: MessageDTO? {
            database.viewContext.message(id: message2Id)
        }
        
        AssertAsync {
            Assert.willBeTrue(message1 != nil)
            Assert.willBeTrue(message2 != nil)
            
            // Message 1 should have `locallyCreatedAt` as `defaultSortingKey`
            Assert.willBeEqual(message1?.defaultSortingKey, message1?.locallyCreatedAt)
            
            // Message 2 should have `createdAt` as `defaultSortingKey`
            Assert.willBeEqual(message2?.defaultSortingKey, message2?.createdAt)
        }
    }
    
    // MARK: - New message tests
    
    func test_creatingNewMessage() throws {
        // Prepare the current user and channel first
        let cid: ChannelId = .unique
        let currentUserId: UserId = .unique
        
        _ = try await { completion in
            database.write({ (session) in
                try session.saveCurrentUser(payload: .dummy(
                    userId: currentUserId,
                    role: .admin,
                    extraData: NameAndImageExtraData(name: nil, imageURL: nil)
                ))
                
                try session.saveChannel(payload: self.dummyPayload(with: cid))
                
            }, completion: completion)
        }
        
        // Create a new message
        var newMessageId: MessageId!
        
        let newMessageText: String = .unique
        let newMessageCommand: String = .unique
        let newMessageArguments: String = .unique
        let newMessageParentMessageId: String = .unique
        
        _ = try await { completion in
            database.write({
                let messageDTO = try $0.createNewMessage(
                    in: cid,
                    text: newMessageText,
                    command: newMessageCommand,
                    arguments: newMessageArguments,
                    parentMessageId: newMessageParentMessageId,
                    showReplyInChannel: true,
                    extraData: NoExtraData.defaultValue
                )
                newMessageId = messageDTO.id
            }, completion: completion)
        }
        
        let loadedMessage: _ChatMessage<DefaultExtraData> = try unwrapAsync(
            database.viewContext.message(id: newMessageId)?
                .asModel()
        )
        
        XCTAssertEqual(loadedMessage.text, newMessageText)
        XCTAssertEqual(loadedMessage.command, newMessageCommand)
        XCTAssertEqual(loadedMessage.arguments, newMessageArguments)
        XCTAssertEqual(loadedMessage.parentMessageId, newMessageParentMessageId)
        XCTAssertEqual(loadedMessage.author.id, currentUserId)
        // Assert the created date of the message is roughly "now"
        XCTAssertLessThan(loadedMessage.createdAt.timeIntervalSince(Date()), 0.1)
        XCTAssertEqual(loadedMessage.createdAt, loadedMessage.locallyCreatedAt)
        XCTAssertEqual(loadedMessage.createdAt, loadedMessage.updatedAt)
    }
    
    func test_creatingNewMessage_withoutExistingCurrentUser_throwsError() throws {
        let result = try await { completion in
            database.write({ (session) in
                try session.createNewMessage(
                    in: .unique,
                    text: .unique,
                    command: .unique,
                    arguments: .unique,
                    parentMessageId: .unique,
                    showReplyInChannel: true,
                    extraData: NoExtraData.defaultValue
                )
            }, completion: completion)
        }
        
        XCTAssert(result is ClientError.CurrentUserDoesNotExist)
    }
    
    func test_creatingNewMessage_withoutExistingChannel_throwsError() throws {
        // Save current user first
        _ = try await {
            database.write({
                try $0.saveCurrentUser(payload: .dummy(
                    userId: .unique,
                    role: .admin,
                    extraData: NameAndImageExtraData(name: nil, imageURL: nil)
                ))
            }, completion: $0)
        }
        
        // Try to create a new message
        let result = try await { completion in
            database.write({ (session) in
                try session.createNewMessage(
                    in: .unique,
                    text: .unique,
                    command: .unique,
                    arguments: .unique,
                    parentMessageId: .unique,
                    showReplyInChannel: true,
                    extraData: NoExtraData.defaultValue
                )
            }, completion: completion)
        }
        
        XCTAssert(result is ClientError.ChannelDoesNotExist)
    }
}
