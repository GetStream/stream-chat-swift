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
}
