//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadDTO_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        database = nil

        super.tearDown()
    }

    func test_saveThreadListPayload() throws {
        let payload = ThreadListPayload(
            threads: [
                dummyThreadPayload(),
                dummyThreadPayload()
            ],
            next: nil
        )

        let dto = database.viewContext.saveThreadList(
            payload: payload
        )

        XCTAssertEqual(dto.count, 2)
    }

    func test_saveThreadPayload() throws {
        let payload = ThreadPayload(
            parentMessageId: .unique,
            parentMessage: .dummy(),
            channel: .dummy(),
            createdBy: .dummy(userId: .unique),
            replyCount: 10,
            participantCount: 10,
            threadParticipants: [dummyThreadParticipantPayload()],
            lastMessageAt: .unique,
            createdAt: .unique,
            updatedAt: .unique,
            title: "Test",
            latestReplies: [.dummy(), .dummy()],
            read: [dummyThreadReadPayload()],
            extraData: [:]
        )

        let dto = try database.viewContext.saveThread(
            payload: payload,
            cache: nil
        )

        XCTAssertEqual(dto.title, "Test")
        XCTAssertEqual(dto.replyCount, 10)
        XCTAssertEqual(dto.participantCount, 10)
        XCTAssertEqual(dto.threadParticipants.count, 1)
        XCTAssertEqual(dto.latestReplies.count, 2)
        XCTAssertEqual(dto.read.count, 1)
        XCTAssertEqual(dto.parentMessageId, payload.parentMessageId)
        XCTAssertEqual(dto.parentMessage.id, payload.parentMessage.id)
        XCTAssertEqual(dto.channel.cid, payload.channel.cid.rawValue)
        XCTAssertEqual(dto.createdBy.id, payload.createdBy.id)
        XCTAssertEqual(dto.lastMessageAt, payload.lastMessageAt?.bridgeDate)
        XCTAssertEqual(dto.createdAt, payload.createdAt.bridgeDate)
        XCTAssertEqual(dto.updatedAt, payload.updatedAt?.bridgeDate)
    }

    func test_asModel() throws {
        let payload = ThreadPayload(
            parentMessageId: .unique,
            parentMessage: .dummy(),
            channel: .dummy(),
            createdBy: .dummy(userId: .unique),
            replyCount: 10,
            participantCount: 10,
            threadParticipants: [dummyThreadParticipantPayload()],
            lastMessageAt: .unique,
            createdAt: .unique,
            updatedAt: .unique,
            title: "Test",
            latestReplies: [.dummy(), .dummy()],
            read: [dummyThreadReadPayload()],
            extraData: [:]
        )

        let dto = try database.viewContext.saveThread(
            payload: payload,
            cache: nil
        )

        let model = try dto.asModel()
        
        XCTAssertEqual(model.title, "Test")
        XCTAssertEqual(model.replyCount, 10)
        XCTAssertEqual(model.participantCount, 10)
        XCTAssertEqual(model.threadParticipants.count, 1)
        XCTAssertEqual(model.latestReplies.count, 2)
        XCTAssertEqual(model.reads.count, 1)
        XCTAssertEqual(model.parentMessageId, payload.parentMessageId)
        XCTAssertEqual(model.parentMessage.id, payload.parentMessage.id)
        XCTAssertEqual(model.channel.cid, payload.channel.cid)
        XCTAssertEqual(model.createdBy.id, payload.createdBy.id)
        XCTAssertEqual(model.lastMessageAt, payload.lastMessageAt)
        XCTAssertEqual(model.createdAt, payload.createdAt)
        XCTAssertEqual(model.updatedAt, payload.updatedAt)
    }

    func test_asModel_sortsLatestRepliesByCreatedAt() throws {
        let now = Date()
        let payload = ThreadPayload.dummy(
            parentMessageId: .unique,
            latestReplies: [
                .dummy(text: "3", createdAt: now.addingTimeInterval(20)),
                .dummy(text: "2", createdAt: now.addingTimeInterval(10)),
                .dummy(text: "1", createdAt: now)
            ]
        )

        let dto = try database.viewContext.saveThread(
            payload: payload,
            cache: nil
        )

        let model = try dto.asModel()

        XCTAssertEqual(
            model.latestReplies.map(\.text),
            ["1", "2", "3"]
        )
    }
}
