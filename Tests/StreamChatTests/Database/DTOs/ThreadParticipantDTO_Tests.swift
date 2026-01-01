//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadParticipantDTO_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        database = nil

        super.tearDown()
    }

    func test_saveThreadParticipantPayload() throws {
        let payload = ThreadParticipantPayload(
            user: .dummy(userId: .unique),
            threadId: .unique,
            createdAt: .unique,
            lastReadAt: .unique
        )

        let dto = try database.viewContext.saveThreadParticipant(
            payload: payload,
            threadId: payload.threadId,
            cache: nil
        )

        XCTAssertEqual(dto.createdAt, payload.createdAt.bridgeDate)
        XCTAssertEqual(dto.user.id, payload.user.id)
        XCTAssertEqual(dto.lastReadAt, payload.lastReadAt?.bridgeDate)
        XCTAssertEqual(dto.threadId, payload.threadId)
        XCTAssertEqual(dto.thread.parentMessageId, payload.threadId)
    }

    func test_asModel() throws {
        let dto = ThreadParticipantDTO(context: database.viewContext)
        dto.lastReadAt = .unique
        dto.threadId = .unique
        dto.user = try database.viewContext.saveUser(payload: .dummy(
            userId: .unique
        ))
        dto.createdAt = .unique

        let model = try dto.asModel()

        XCTAssertEqual(model.lastReadAt, dto.lastReadAt?.bridgeDate)
        XCTAssertEqual(model.threadId, dto.threadId)
        XCTAssertEqual(model.user.id, dto.user.id)
        XCTAssertEqual(model.createdAt, dto.createdAt.bridgeDate)
    }
}
