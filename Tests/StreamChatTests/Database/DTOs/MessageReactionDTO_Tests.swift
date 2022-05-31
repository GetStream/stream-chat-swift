//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class MessageReactionDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }
    
    // MARK: - Save
    
    func test_messageReactionPayload_withDefaultExtraData_isStoredAndLoadedFromDB() throws {
        // Create message reaction payload with `DefaultExtraData`.
        let payload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: dummyUser
        )
        
        // Assert message reaction is saved and loaded correctly.
        try assert_messageReaction_isStoredAndLoadedFromDB(payload)
    }
    
    func test_messageReactionPayload_withCustomExtraData_isStoredAndLoadedFromDB() throws {
        // Create message reaction payload with `CustomExtraData`.
        let payload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: dummyUser,
            extraData: ["mood": .string(.unique)]
        )
        
        // Assert message reaction is saved and loaded correctly.
        try assert_messageReaction_isStoredAndLoadedFromDB(payload)
    }
    
    func test_saveReaction_throwsMessageDoesNotExist_ifThereIsNoMessage() {
        // Create message reaction payload with `DefaultExtraData`.
        let payload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: dummyUser
        )
        
        // Assert saving message reaction with the message throws `MessageDoesNotExist` error.
        XCTAssertThrowsError(
            try database.writeSynchronously { session in
                try session.saveReaction(payload: payload)
            }
        ) { error in
            XCTAssertTrue(error is ClientError.MessageDoesNotExist)
        }
    }
    
    // MARK: - Convert
    
    func test_asModel_buildsCorrectModel() throws {
        // Create message reaction payload with `DefaultExtraData`.
        let payload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: dummyUser,
            extraData: ["k": .string("v")]
        )
        
        // Save message to the database.
        try database.createMessage(id: payload.messageId)
        
        // Save message reaction to the database and corrupt extra data.
        try database.writeSynchronously { session in
            try session.saveReaction(payload: payload)
        }
        
        // Load saved message reaction and build the model.
        let model: ChatMessageReaction = try XCTUnwrap(
            database.viewContext.reaction(
                messageId: payload.messageId,
                userId: payload.user.id,
                type: payload.type
            )
        ).asModel()

        // Assert model is built up correctly.
        XCTAssertEqual(model.createdAt, payload.createdAt)
        XCTAssertEqual(model.updatedAt, payload.updatedAt)
        XCTAssertEqual(model.type, payload.type)
        XCTAssertEqual(model.score, payload.score)
        XCTAssertEqual(model.extraData, payload.extraData)
        XCTAssertEqual(model.author.id, payload.user.id)
    }
    
    func test_asModel_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        // Create message reaction payload with `DefaultExtraData`.
        let payload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: dummyUser
        )
        
        // Save message to the database.
        try database.createMessage(id: payload.messageId)
        
        try database.writeSynchronously { session in
            // Save message reaction to the database.
            let dto = try session.saveReaction(payload: payload)
            // Corrupt extra data.
            dto.extraData = #"{"invalid": json}"#.data(using: .utf8)!
        }
        
        // Load saved message reaction.
        let model: ChatMessageReaction = try XCTUnwrap(
            database.viewContext.reaction(
                messageId: payload.messageId,
                userId: payload.user.id,
                type: payload.type
            )
        ).asModel()
        
        // Assert model is built up with default extra data.
        XCTAssertEqual(model.extraData, [:])
        // Assert other fields have correct values.
        XCTAssertEqual(model.createdAt, payload.createdAt)
        XCTAssertEqual(model.updatedAt, payload.updatedAt)
        XCTAssertEqual(model.type, payload.type)
        XCTAssertEqual(model.score, payload.score)
        XCTAssertEqual(model.author.id, payload.user.id)
    }
    
    // MARK: - Delete
    
    func test_deleteReaction_worksCorrectly() throws {
        // Create message reaction payload with `DefaultExtraData`.
        let payload: MessageReactionPayload = .dummy(
            messageId: .unique,
            user: dummyUser
        )
        
        // Save message to the database.
        try database.createMessage(id: payload.messageId)
        
        // Save message reaction to the database.
        try database.writeSynchronously { session in
            try session.saveReaction(payload: payload)
        }
        
        // Delete message reaction from the database.
        try database.writeSynchronously { session in
            // Load message reaction.
            let dto = try XCTUnwrap(
                session.reaction(
                    messageId: payload.messageId,
                    userId: payload.user.id,
                    type: payload.type
                )
            )
            
            // Delete message reaction.
            session.delete(reaction: dto)
        }
        
        // Load reaction.
        let dto = database.viewContext.reaction(
            messageId: payload.messageId,
            userId: payload.user.id,
            type: payload.type
        )
        
        // Assert dto is `nil`.
        XCTAssertNil(dto)
    }

    // MARK: - Loading

    func test_onlyCorrectStatesAreReturned() throws {
        // We need to first create a channel and a message
        let cid = ChannelId(type: .messaging, id: "c")
        let messageId = "m"
        try database.writeSynchronously { session in
            try session.saveChannel(payload: .dummy(cid: cid), query: nil)
            try session.saveMessage(payload: .dummy(messageId: messageId, authorUserId: .unique), for: cid, syncOwnReactions: false)
        }

        // We store one reaction for each state
        let allStates: [LocalReactionState] = [
            .unknown,
            .pendingSend,
            .sending,
            .sendingFailed,
            .pendingDelete,
            .deleting,
            .deletingFailed
        ]
        let userId = "id"
        var storedIds: [String] = []
        for state in allStates {
            let type = MessageReactionType(stringLiteral: state.rawValue)
            let reactionId = try saveReaction(state: state, type: type, messageId: messageId, userId: userId)
            storedIds.append(reactionId)
        }

        // We not fetch the reactions the user should see
        var fetchedIds: [String] = []
        database.backgroundReadOnlyContext.performAndWait {
            fetchedIds = MessageReactionDTO.loadReactions(ids: storedIds, context: database.backgroundReadOnlyContext).map(\.id)
        }

        // We only expect to receive 4 states
        let expectedLocalStates: [LocalReactionState] = [.unknown, .deletingFailed, .pendingSend, .sending]
        XCTAssertEqual(fetchedIds.count, expectedLocalStates.count)
        for state in expectedLocalStates {
            XCTAssertTrue(fetchedIds.contains("\(userId)/\(messageId)/\(state.rawValue)"))
        }
    }

    private func saveReaction(
        state: LocalReactionState,
        type: MessageReactionType,
        messageId: MessageId,
        userId: UserId
    ) throws -> String {
        var id: String!
        try database.writeSynchronously { session in
            let reaction = try session.saveReaction(
                payload: MessageReactionPayload(
                    type: type,
                    score: 1,
                    messageId: messageId,
                    createdAt: Date(),
                    updatedAt: Date(),
                    user: .dummy(userId: userId),
                    extraData: [:]
                )
            )
            reaction.localState = state
            id = reaction.id
        }
        return id
    }

    // MARK: - Private
    
    private func assert_messageReaction_isStoredAndLoadedFromDB(
        _ payload: MessageReactionPayload,
        createMessageInTheDatabase: Bool = true
    ) throws {
        // Save message to the database.
        if createMessageInTheDatabase {
            try database.createMessage(id: payload.messageId)
        }
        
        // Save message reaction to the database.
        try database.writeSynchronously { session in
            try session.saveReaction(payload: payload)
        }
        
        // Load saved message reaction.
        let dto = try XCTUnwrap(
            database.viewContext.reaction(
                messageId: payload.messageId,
                userId: payload.user.id,
                type: payload.type
            )
        )
        
        // Encode extra data.
        let encoder = JSONEncoder.default
        let reactionExtraData = try encoder.encode(payload.extraData)
        let userExtraData = try encoder.encode(payload.user.extraData)

        // Assert loaded message reaction has valid fields.
        XCTAssertEqual(dto.createdAt?.bridgeDate, payload.createdAt)
        XCTAssertEqual(dto.updatedAt?.bridgeDate, payload.updatedAt)
        XCTAssertEqual(dto.type, payload.type.rawValue)
        XCTAssertEqual(dto.score, Int64(payload.score))
        XCTAssertEqual(dto.extraData, reactionExtraData)
        XCTAssertEqual(dto.message.id, payload.messageId)
        
        // Assert reaction author has valid fields.
        XCTAssertEqual(dto.user.id, payload.user.id)
        XCTAssertEqual(dto.user.extraData, userExtraData)
    }
}
