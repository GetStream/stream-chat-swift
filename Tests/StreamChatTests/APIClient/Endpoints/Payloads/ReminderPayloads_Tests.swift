//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReminderPayload_Tests: XCTestCase {
    let reminderJSON = XCTestCase.mockData(fromJSONFile: "ReminderPayload")
    
    func test_reminderPayload_isSerialized() throws {
        let payload = try JSONDecoder.default.decode(ReminderPayload.self, from: reminderJSON)
        
        // Test basic properties
        XCTAssertEqual(payload.channelCid.rawValue, "messaging:26D82FB1-5")
        XCTAssertEqual(payload.messageId, "lando_calrissian-8tnV2qn0umMogef2WjR4k")
        XCTAssertNil(payload.remindAt) // Updated to nil as per new JSON
        XCTAssertEqual(payload.createdAt, "2025-03-19T00:38:38.697482729Z".toDate())
        XCTAssertEqual(payload.updatedAt, "2025-03-19T00:38:38.697482729Z".toDate())
        
        // Test embedded message
        XCTAssertNotNil(payload.message)
        XCTAssertEqual(payload.message?.id, "lando_calrissian-8tnV2qn0umMogef2WjR4k")
        XCTAssertEqual(payload.message?.text, "4")
        XCTAssertEqual(payload.message?.type.rawValue, "regular")
        XCTAssertEqual(payload.message?.user.id, "lando_calrissian")
        XCTAssertEqual(payload.message?.createdAt, "2025-03-04T14:33:10.628163Z".toDate())
        XCTAssertEqual(payload.message?.updatedAt, "2025-03-04T14:33:10.628163Z".toDate())
        
        // Test channel properties (new in updated JSON)
        XCTAssertNotNil(payload.channel)
        XCTAssertEqual(payload.channel?.cid.rawValue, "messaging:26D82FB1-5")
        XCTAssertEqual(payload.channel?.name, "Yo")
    }
}

final class ReminderResponsePayload_Tests: XCTestCase {
    func test_isSerialized() throws {
        // Create a JSON representation of a ReminderResponsePayload
        // with the updated structure including duration
        let reminderResponseJSON = """
        {
            "duration": "30.74ms",
            "reminder": {
                "channel_cid": "messaging:26D82FB1-5",
                "message_id": "lando_calrissian-8tnV2qn0umMogef2WjR4k",
                "remind_at": null,
                "created_at": "2025-03-19T00:38:38.697482729Z",
                "updated_at": "2025-03-19T00:38:38.697482729Z",
                "user_id": "han_solo"
            }
        }
        """.data(using: .utf8)!
        
        let payload = try JSONDecoder.default.decode(ReminderResponsePayload.self, from: reminderResponseJSON)
        
        XCTAssertEqual(payload.reminder.channelCid.rawValue, "messaging:26D82FB1-5")
        XCTAssertEqual(payload.reminder.messageId, "lando_calrissian-8tnV2qn0umMogef2WjR4k")
        XCTAssertNil(payload.reminder.remindAt)
        XCTAssertEqual(payload.reminder.createdAt, "2025-03-19T00:38:38.697482729Z".toDate())
        XCTAssertEqual(payload.reminder.updatedAt, "2025-03-19T00:38:38.697482729Z".toDate())
    }
}

final class RemindersQueryPayload_Tests: XCTestCase {
    func test_isSerialized() throws {
        // Create a JSON representation of a RemindersQueryPayload with updated structure
        let remindersQueryJSON = """
        {
            "duration": "30.74ms",
            "reminders": [
                {
                    "channel_cid": "messaging:26D82FB1-5",
                    "message_id": "lando_calrissian-8tnV2qn0umMogef2WjR4k",
                    "remind_at": null,
                    "created_at": "2025-03-19T00:38:38.697482729Z",
                    "updated_at": "2025-03-19T00:38:38.697482729Z",
                    "user_id": "han_solo"
                },
                {
                    "channel_cid": "messaging:456",
                    "message_id": "message-456",
                    "remind_at": "2023-02-01T12:00:00.000Z",
                    "created_at": "2022-02-03T00:00:00.000Z",
                    "updated_at": "2022-02-03T00:00:00.000Z",
                    "user_id": "luke_skywalker"
                }
            ],
            "next": "next-page-token"
        }
        """.data(using: .utf8)!
        
        let payload = try JSONDecoder.default.decode(RemindersQueryPayload.self, from: remindersQueryJSON)
        
        // Verify the count of reminders
        XCTAssertEqual(payload.reminders.count, 2)
        
        // Verify pagination tokens
        XCTAssertEqual(payload.next, "next-page-token")
        
        // Verify first reminder details
        XCTAssertEqual(payload.reminders[0].channelCid.rawValue, "messaging:26D82FB1-5")
        XCTAssertEqual(payload.reminders[0].messageId, "lando_calrissian-8tnV2qn0umMogef2WjR4k")
        XCTAssertNil(payload.reminders[0].remindAt)
        
        // Verify second reminder details
        XCTAssertEqual(payload.reminders[1].channelCid.rawValue, "messaging:456")
        XCTAssertEqual(payload.reminders[1].messageId, "message-456")
        XCTAssertEqual(payload.reminders[1].remindAt, "2023-02-01T12:00:00.000Z".toDate())
    }
}
