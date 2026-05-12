//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
import XCTest

final class MessageSearchFilterScope_Tests: StressTestCase {
    func test_withAttachments_givenAttachmentTypes() {
        let attachmentTypes: Set<AttachmentType> = [.image, .video]

        let filter: Filter<MessageSearchFilterScope> = .withAttachments(attachmentTypes)

        XCTAssertEqual(filter.key, "attachments.type")
        XCTAssertEqual(filter.operator, "$in")
        XCTAssertEqual(Set(filter.value as! [AttachmentType]), attachmentTypes)
    }

    func test_withAttachments() {
        let filter: Filter<MessageSearchFilterScope> = .withAttachments

        XCTAssertEqual(filter.key, "attachments")
        XCTAssertEqual(filter.operator, "$exists")
        XCTAssertEqual(filter.value as! Bool, true)
    }

    func test_withoutAttachments() {
        let filter: Filter<MessageSearchFilterScope> = .withoutAttachments

        XCTAssertEqual(filter.key, "attachments")
        XCTAssertEqual(filter.operator, "$exists")
        XCTAssertEqual(filter.value as! Bool, false)
    }
}

final class MessageSearchQuery_ChannelListSortMapping_Tests: XCTestCase {
    func test_messageSearchSort_fromEmptyChannelListSort_returnsCreatedAtDesc() {
        let result = MessageSearchQuery.messageSearchSort(fromChannelListSort: [])
        XCTAssertEqual(result, [.init(key: .createdAt, isAscending: false)])
    }

    func test_messageSearchSort_fromLastMessageAt_returnsCreatedAtWithSameDirection() {
        let result = MessageSearchQuery.messageSearchSort(fromChannelListSort: [
            .init(key: .lastMessageAt, isAscending: false)
        ])
        XCTAssertEqual(result, [.init(key: .createdAt, isAscending: false)])
    }

    func test_messageSearchSort_fromLastMessageAtAscending_returnsCreatedAtAscending() {
        let result = MessageSearchQuery.messageSearchSort(fromChannelListSort: [
            .init(key: .lastMessageAt, isAscending: true)
        ])
        XCTAssertEqual(result, [.init(key: .createdAt, isAscending: true)])
    }

    func test_messageSearchSort_fromUpdatedAt_returnsUpdatedAtWithSameDirection() {
        let result = MessageSearchQuery.messageSearchSort(fromChannelListSort: [
            .init(key: .updatedAt, isAscending: true)
        ])
        XCTAssertEqual(result, [.init(key: .updatedAt, isAscending: true)])
    }

    func test_messageSearchSort_fromCreatedAt_returnsCreatedAtWithSameDirection() {
        let result = MessageSearchQuery.messageSearchSort(fromChannelListSort: [
            .init(key: .createdAt, isAscending: true)
        ])
        XCTAssertEqual(result, [.init(key: .createdAt, isAscending: true)])
    }

    func test_messageSearchSort_fromUnmappedKey_returnsCreatedAtDesc() {
        let result = MessageSearchQuery.messageSearchSort(fromChannelListSort: [
            .init(key: .memberCount, isAscending: true)
        ])
        XCTAssertEqual(result, [.init(key: .createdAt, isAscending: false)])
    }
}

final class MessageSearchQuery_OpenAPIPayload_Tests: XCTestCase {
    func test_searchPayload_usesRawJSONFiltersAndSort() {
        let query = MessageSearchQuery(
            channelFilter: .equal(.cid, to: ChannelId(type: .messaging, id: "general")),
            messageFilter: .withAttachments([.image]),
            sort: [.init(key: .updatedAt, isAscending: true)],
            pageSize: 10
        )

        let payload = SearchPayload(query: query)

        XCTAssertEqual(payload.filterConditions, ["cid": .dictionary(["$eq": .string("messaging:general")])])
        XCTAssertEqual(
            payload.messageFilterConditions,
            ["attachments.type": .dictionary(["$in": .array([.string("image")])])]
        )
        XCTAssertEqual(payload.limit, 10)
        XCTAssertEqual(payload.sort, [SortParamRequest(direction: 1, field: "updated_at")])
    }
}
