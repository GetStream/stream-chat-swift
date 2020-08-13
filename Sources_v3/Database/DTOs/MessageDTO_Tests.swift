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
        
        let channelPayload: ChannelPayload<DefaultDataTypes> = dummyPayload(with: channelId)
        
        let userPayload: UserPayload<NameAndImageExtraData> = .init(id: userId,
                                                                    role: .admin,
                                                                    createdAt: .unique,
                                                                    updatedAt: .unique,
                                                                    lastActiveAt: .unique,
                                                                    isOnline: true,
                                                                    isInvisible: true,
                                                                    isBanned: true,
                                                                    extraData: .init(name: "Anakin",
                                                                                     imageURL: URL(string: UUID().uuidString)))
        
        let messagePayload: MessagePayload<DefaultDataTypes> = .init(id: messageId,
                                                                     type: .regular,
                                                                     user: userPayload,
                                                                     createdAt: .unique,
                                                                     updatedAt: .unique,
                                                                     deletedAt: nil,
                                                                     text: "No, I am your father 🤯",
                                                                     command: "some command",
                                                                     args: "some args",
                                                                     parentId: nil,
                                                                     showReplyInChannel: false,
                                                                     mentionedUsers: [userPayload],
                                                                     replyCount: 0,
                                                                     extraData: .init(),
                                                                     reactionScores: ["shock": 1000],
                                                                     isSilent: false)
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        var loadedMessage: MessageModel<DefaultDataTypes>? {
            database.viewContext.loadMessage(id: messageId)
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
            Assert.willBeEqual(loadedMessage?.args, messagePayload.args)
            Assert.willBeEqual(loadedMessage?.parentId, messagePayload.parentId)
            Assert.willBeEqual(loadedMessage?.showReplyInChannel, messagePayload.showReplyInChannel)
            Assert.willBeEqual(loadedMessage?.mentionedUsers.map { $0.id }, messagePayload.mentionedUsers.map { $0.id })
            Assert.willBeEqual(loadedMessage?.replyCount, messagePayload.replyCount)
            Assert.willBeEqual(loadedMessage?.extraData, messagePayload.extraData)
            Assert.willBeEqual(loadedMessage?.reactionScores, messagePayload.reactionScores)
            Assert.willBeEqual(loadedMessage?.isSilent, messagePayload.isSilent)
        }
    }
    
    func test_messagePayload_withExtraData_isStoredAndLoadedFromDB() {
        struct DeathStarMetadata: MessageExtraData {
            let isSectedDeathStarPlanIncluded: Bool
        }
        
        enum SecretExtraData: ExtraDataTypes {
            typealias Message = DeathStarMetadata
        }
        
        let userId: UserId = .unique
        let messageId: MessageId = .unique
        let channelId: ChannelId = .unique
        
        let channelPayload: ChannelPayload<DefaultDataTypes> = dummyPayload(with: channelId)
        
        let userPayload: UserPayload<NameAndImageExtraData> = .init(id: userId,
                                                                    role: .admin,
                                                                    createdAt: .unique,
                                                                    updatedAt: .unique,
                                                                    lastActiveAt: .unique,
                                                                    isOnline: true,
                                                                    isInvisible: true,
                                                                    isBanned: true,
                                                                    extraData: .init(name: "Anakin",
                                                                                     imageURL: URL(string: UUID().uuidString)))
        
        let messagePayload: MessagePayload<SecretExtraData> = .init(id: messageId,
                                                                    type: .regular,
                                                                    user: userPayload,
                                                                    createdAt: .unique,
                                                                    updatedAt: .unique,
                                                                    deletedAt: nil,
                                                                    text: "No, I am your father 🤯",
                                                                    command: "some command",
                                                                    args: "some args",
                                                                    parentId: nil,
                                                                    showReplyInChannel: false,
                                                                    mentionedUsers: [userPayload],
                                                                    replyCount: 0,
                                                                    extraData: .init(isSectedDeathStarPlanIncluded: true),
                                                                    reactionScores: ["shock": 1000],
                                                                    isSilent: false)
        
        // Asynchronously save the payload to the db
        database.write { session in
            // Create the channel first
            try! session.saveChannel(payload: channelPayload, query: nil)
            
            // Save the message
            try! session.saveMessage(payload: messagePayload, for: channelId)
        }
        
        // Load the message from the db and check the fields are correct
        var loadedMessage: MessageModel<SecretExtraData>? {
            database.viewContext.loadMessage(id: messageId)
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
            Assert.willBeEqual(loadedMessage?.args, messagePayload.args)
            Assert.willBeEqual(loadedMessage?.parentId, messagePayload.parentId)
            Assert.willBeEqual(loadedMessage?.showReplyInChannel, messagePayload.showReplyInChannel)
            Assert.willBeEqual(loadedMessage?.mentionedUsers.map { $0.id }, messagePayload.mentionedUsers.map { $0.id })
            Assert.willBeEqual(loadedMessage?.replyCount, messagePayload.replyCount)
            Assert.willBeEqual(loadedMessage?.extraData.isSectedDeathStarPlanIncluded,
                               messagePayload.extraData.isSectedDeathStarPlanIncluded)
            Assert.willBeEqual(loadedMessage?.reactionScores, messagePayload.reactionScores)
            Assert.willBeEqual(loadedMessage?.isSilent, messagePayload.isSilent)
        }
    }
}
