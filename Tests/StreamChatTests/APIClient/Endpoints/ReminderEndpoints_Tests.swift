//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReminderEndpoints_Tests: XCTestCase {
    func test_createReminder_buildsGeneratedEndpoint() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let request = CreateReminderRequest(remindAt: date)
        let endpoint: Endpoint<ReminderResponseData> = .createReminder(messageId: "message-id", createReminderRequest: request)

        XCTAssertEqual(endpoint.path, "/api/v2/chat/messages/message-id/reminders")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? CreateReminderRequest, request)
    }

    func test_queryReminders_buildsGeneratedEndpoint() {
        let request = QueryRemindersRequest(limit: 10)
        let endpoint: Endpoint<QueryRemindersResponse> = .queryReminders(queryRemindersRequest: request)

        XCTAssertEqual(endpoint.path, "/api/v2/chat/reminders/query")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNil(endpoint.queryItems)
        XCTAssertFalse(endpoint.requiresConnectionId)
        XCTAssertEqual(endpoint.body as? QueryRemindersRequest, request)
    }
}
