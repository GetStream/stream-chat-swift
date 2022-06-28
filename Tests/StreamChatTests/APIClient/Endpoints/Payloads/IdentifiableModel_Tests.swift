//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class IdentifiableModel_Tests: XCTestCase {
    var database: DatabaseContainer!

    private lazy var deviceDTO: DeviceDTO = {
        let dto = DeviceDTO(context: database.viewContext)
        dto.id = "DeviceDTO_123"
        return dto
    }()

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }

    func test_ChannelDTO_conformsToIdentifiableModel() {
        let type = ChannelDTO.self
        let dto = type.init(context: database.viewContext)
        dto.cid = type.className + "_123"

        XCTAssertEqual(type.className, "ChannelDTO")
        XCTAssertEqual(type.idKeyPath, "cid")
        XCTAssertEqual(type.id(for: dto), "ChannelDTO_123")

        XCTAssertNil(type.id(for: deviceDTO))
    }

    func test_UserDTO_conformsToIdentifiableModel() {
        let type = UserDTO.self
        let dto = type.init(context: database.viewContext)
        dto.id = type.className + "_123"

        XCTAssertEqual(type.className, "UserDTO")
        XCTAssertEqual(type.idKeyPath, "id")
        XCTAssertEqual(type.id(for: dto), "UserDTO_123")

        XCTAssertNil(type.id(for: deviceDTO))
    }

    func test_MessageDTO_conformsToIdentifiableModel() {
        let type = MessageDTO.self
        let dto = type.init(context: database.viewContext)
        dto.id = type.className + "_123"

        XCTAssertEqual(type.className, "MessageDTO")
        XCTAssertEqual(type.idKeyPath, "id")
        XCTAssertEqual(type.id(for: dto), "MessageDTO_123")

        XCTAssertNil(type.id(for: deviceDTO))
    }

    func test_MessageReactionDTO_conformsToIdentifiableModel() {
        let type = MessageReactionDTO.self
        let messageDTO = MessageDTO(context: database.viewContext)
        messageDTO.id = "123"
        let userDTO = UserDTO(context: database.viewContext)
        userDTO.id = "456"

        let dto = type.loadOrCreate(
            message: messageDTO,
            type: "MessageReactionDTO",
            user: userDTO,
            context: database.viewContext,
            cache: nil
        )

        XCTAssertEqual(type.className, "MessageReactionDTO")
        XCTAssertEqual(type.idKeyPath, "id")
        XCTAssertEqual(type.id(for: dto), "456/123/MessageReactionDTO")

        XCTAssertNil(type.id(for: deviceDTO))
    }

    func test_MemberDTO_conformsToIdentifiableModel() {
        let type = MemberDTO.self
        let dto = type.loadOrCreate(
            userId: "MemberDTO",
            channelId: ChannelId(type: .team, id: "2"),
            context: database.viewContext,
            cache: nil
        )

        XCTAssertEqual(type.className, "MemberDTO")
        XCTAssertEqual(type.idKeyPath, "id")
        XCTAssertEqual(type.id(for: dto), "team:2MemberDTO")

        XCTAssertNil(type.id(for: deviceDTO))
    }

    func test_ChannelReadDTO_conformsToIdentifiableModel() {
        let type = ChannelReadDTO.self
        let dto = type.init(context: database.viewContext)

        XCTAssertEqual(type.className, "ChannelReadDTO")
        XCTAssertNil(type.idKeyPath)
        XCTAssertNil(type.id(for: dto))

        XCTAssertNil(type.id(for: deviceDTO))
    }
}
