//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadListPayload_Tests: XCTestCase {
    func test_threadList_decoding() throws {
        let url = XCTestCase.mockData(fromJSONFile: "ThreadList")
        let payload = try JSONDecoder.default.decode(ThreadListPayload.self, from: url)
        // 1 of the 3 threads has no `parent_message`, which is optional in the payload.
        // Such a thread is skipped when it is saved to the database, see `ThreadDTO_Tests`.
        XCTAssertEqual(payload.threads.count, 3)
        XCTAssertEqual(payload.threads.filter { $0.parentMessage == nil }.count, 1)
    }

    func test_thread_decoding() throws {
        let url = XCTestCase.mockData(fromJSONFile: "Thread")
        let payload = try JSONDecoder.default.decode(ThreadPayload.self, from: url)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:4AB11F2F-4")
        XCTAssertEqual(payload.parentMessageId, "488bba2a-193d-48d2-95ae-3aa4b8e34960")
        XCTAssertEqual(payload.parentMessage?.id, "488bba2a-193d-48d2-95ae-3aa4b8e34960")
        XCTAssertEqual(payload.parentMessage?.text, "msg: 24")
        XCTAssertEqual(payload.createdBy?.id, "han_solo")
        XCTAssertEqual(payload.replyCount, 60)
        XCTAssertEqual(payload.participantCount, 3)
        XCTAssertEqual(payload.activeParticipantCount, 2)
        XCTAssertEqual(payload.threadParticipants?.count, 3)
        XCTAssertEqual(payload.lastMessageAt, "2024-03-26T12:25:07.25741Z".toDate())
        XCTAssertEqual(payload.createdAt, "2024-03-26T12:14:10.87779Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2024-03-26T12:25:07.25741Z".toDate())
        XCTAssertEqual(payload.title, "msg: 24")
        XCTAssertEqual(payload.latestReplies.count, 2)
        XCTAssertEqual(payload.read?.count, 3)
        XCTAssertEqual(payload.custom["custom_test"]?.numberValue, 10)
    }

    func test_thread_dropsArrayElementsThatFailDecoding() throws {
        let url = XCTestCase.mockData(fromJSONFile: "Thread")
        var thread = try XCTUnwrap(JSONSerialization.jsonObject(with: url) as? [String: Any])
        let latestReplies = try XCTUnwrap(thread["latest_replies"] as? [Any])
        let read = try XCTUnwrap(thread["read"] as? [Any])
        let threadParticipants = try XCTUnwrap(thread["thread_participants"] as? [Any])
        thread["latest_replies"] = latestReplies + [["id": "broken"]]
        thread["read"] = read + [["unread_messages": 0]]
        thread["thread_participants"] = threadParticipants + [["created_at": "broken"]]
        let data = try JSONSerialization.data(withJSONObject: thread)

        let payload = try JSONDecoder.default.decode(ThreadPayload.self, from: data)

        XCTAssertEqual(payload.latestReplies.count, latestReplies.count)
        XCTAssertEqual(payload.read?.count, read.count)
        XCTAssertEqual(payload.threadParticipants?.count, threadParticipants.count)
    }

    func test_thread_latestRepliesDefaultToEmptyWhenMissing() throws {
        let url = XCTestCase.mockData(fromJSONFile: "Thread")
        var thread = try XCTUnwrap(JSONSerialization.jsonObject(with: url) as? [String: Any])
        thread.removeValue(forKey: "latest_replies")
        let data = try JSONSerialization.data(withJSONObject: thread)

        let payload = try JSONDecoder.default.decode(ThreadPayload.self, from: data)

        XCTAssertEqual(payload.latestReplies.count, 0)
    }

    func test_threadList_shouldReturnThreadsIfOneThreadFailsParsing() throws {
        let url = XCTestCase.mockData(fromJSONFile: "Thread")
        let thread = try XCTUnwrap(JSONSerialization.jsonObject(with: url) as? [String: Any])
        var brokenThread = thread
        brokenThread.removeValue(forKey: "created_at")
        let data = try JSONSerialization.data(withJSONObject: ["threads": [thread, brokenThread]])

        let payload = try JSONDecoder.default.decode(ThreadListPayload.self, from: data)

        XCTAssertEqual(payload.threads.count, 1)
    }
}
