//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadListPayload_Tests: XCTestCase {
    func test_threadList_decoding() throws {
        let url = XCTestCase.mockData(fromJSONFile: "ThreadList")
        let payload = try JSONDecoder.default.decode(ThreadListPayload.self, from: url)
        // The JSON Payload actually has 3 threads, but 1 has an invalid `parentMessage`.
        // The goal is to also test that if there are invalid threads, we still parse the remaining ones.
        XCTAssertEqual(payload.threads.count, 2)
    }

    func test_thread_decoding() throws {
        let url = XCTestCase.mockData(fromJSONFile: "Thread")
        let payload = try JSONDecoder.default.decode(ThreadPayload.self, from: url)
        XCTAssertEqual(payload.channel.cid.rawValue, "messaging:4AB11F2F-4")
        XCTAssertEqual(payload.parentMessageId, "488bba2a-193d-48d2-95ae-3aa4b8e34960")
        XCTAssertEqual(payload.parentMessage.id, "488bba2a-193d-48d2-95ae-3aa4b8e34960")
        XCTAssertEqual(payload.parentMessage.text, "msg: 24")
        XCTAssertEqual(payload.createdBy.id, "han_solo")
        XCTAssertEqual(payload.replyCount, 60)
        XCTAssertEqual(payload.participantCount, 3)
        XCTAssertEqual(payload.threadParticipants.count, 3)
        XCTAssertEqual(payload.lastMessageAt, "2024-03-26T12:25:07.25741Z".toDate())
        XCTAssertEqual(payload.createdAt, "2024-03-26T12:14:10.87779Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2024-03-26T12:25:07.25741Z".toDate())
        XCTAssertEqual(payload.title, "msg: 24")
        XCTAssertEqual(payload.latestReplies.count, 2)
        XCTAssertEqual(payload.read.count, 3)
        XCTAssertEqual(payload.extraData["custom_test"]?.numberValue, 10)
    }
}
