//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ReminderEndpoints_Tests: XCTestCase {
    func test_createReminder_buildsCorrectly() {
        let messageId: MessageId = .unique
        let remindAt = Date()
        let request = ReminderRequestBody(remindAt: remindAt)
        
        let expectedEndpoint = Endpoint<ReminderResponsePayload>(
            path: .reminder(messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
        
        let endpoint: Endpoint<ReminderResponsePayload> = .createReminder(messageId: messageId, request: request)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)/reminders", endpoint.path.value)
    }
    
    func test_updateReminder_buildsCorrectly() {
        let messageId: MessageId = .unique
        let remindAt = Date()
        let request = ReminderRequestBody(remindAt: remindAt)
        
        let expectedEndpoint = Endpoint<ReminderResponsePayload>(
            path: .reminder(messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
        
        let endpoint: Endpoint<ReminderResponsePayload> = .updateReminder(messageId: messageId, request: request)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)/reminders", endpoint.path.value)
    }
    
    func test_deleteReminder_buildsCorrectly() {
        let messageId: MessageId = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .reminder(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        let endpoint: Endpoint<EmptyResponse> = .deleteReminder(messageId: messageId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("messages/\(messageId)/reminders", endpoint.path.value)
    }
    
    func test_queryReminders_buildsCorrectly() {
        let query = MessageReminderListQuery(
            filter: .equal(.cid, to: ChannelId.unique),
            sort: [.init(key: .remindAt, isAscending: true)],
            pageSize: 25
        )
        
        let expectedEndpoint = Endpoint<RemindersQueryPayload>(
            path: .reminders,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: query
        )
        
        let endpoint: Endpoint<RemindersQueryPayload> = .queryReminders(query: query)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("reminders/query", endpoint.path.value)
    }
}
