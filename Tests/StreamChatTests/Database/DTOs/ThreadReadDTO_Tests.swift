//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadReadDTO_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()

        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        database = nil

        super.tearDown()
    }

    func test_saveThreadReadPayload() throws {
        let payload = ThreadReadPayload(
            user: .dummy(userId: .unique),
            lastReadAt: .unique,
            unreadMessagesCount: 10
        )

        let dto = try database.viewContext.saveThreadRead(
            payload: payload,
            parentMessageId: .unique,
            cache: nil
        )

        XCTAssertEqual(dto.unreadMessagesCount, Int64(payload.unreadMessagesCount))
        XCTAssertEqual(dto.user.id, payload.user.id)
        XCTAssertEqual(dto.lastReadAt, payload.lastReadAt?.bridgeDate)
    }
    
    func test_asModel() throws {
        let dto = ThreadReadDTO(context: database.viewContext)
        dto.lastReadAt = .unique
        dto.unreadMessagesCount = 10
        dto.user = try database.viewContext.saveUser(payload: .dummy(
            userId: .unique
        ))

        let model = try dto.asModel()

        XCTAssertEqual(model.lastReadAt, dto.lastReadAt?.bridgeDate)
        XCTAssertEqual(model.unreadMessagesCount, Int(dto.unreadMessagesCount))
        XCTAssertEqual(model.user.id, dto.user.id)
    }

    func test_markThreadAsRead() throws {
        let messageId = MessageId.unique
        let userId = UserId.unique
        let readDate = Date.unique

        try database.writeSynchronously { session in
            try session.saveThreadRead(
                payload: .init(
                    user: .dummy(userId: userId),
                    lastReadAt: .unique,
                    unreadMessagesCount: 10
                ),
                parentMessageId: messageId,
                cache: nil
            )

            session.markThreadAsRead(
                parentMessageId: messageId,
                userId: userId,
                at: readDate
            )
        }

        let threadReadDTO = database.viewContext.loadThreadRead(
            parentMessageId: messageId,
            userId: userId
        )

        XCTAssertEqual(threadReadDTO?.unreadMessagesCount, 0)
        XCTAssertEqual(threadReadDTO?.lastReadAt?.bridgeDate, readDate)
    }

    func test_markThreadAsUnRead() throws {
        let messageId = MessageId.unique
        let userId = UserId.unique
        let replyCount = 10

        try database.writeSynchronously { session in
            try session.saveThread(
                payload: .dummy(parentMessageId: messageId, replyCount: replyCount),
                cache: nil
            )
            try session.saveThreadRead(
                payload: .init(
                    user: .dummy(userId: userId),
                    lastReadAt: .unique,
                    unreadMessagesCount: 0
                ),
                parentMessageId: messageId,
                cache: nil
            )

            session.markThreadAsUnread(for: messageId, userId: userId)
        }

        let threadReadDTO = database.viewContext.loadThreadRead(
            parentMessageId: messageId,
            userId: userId
        )

        XCTAssertEqual(threadReadDTO?.unreadMessagesCount, 1)
        XCTAssertNil(threadReadDTO?.lastReadAt?.bridgeDate)
    }
}
