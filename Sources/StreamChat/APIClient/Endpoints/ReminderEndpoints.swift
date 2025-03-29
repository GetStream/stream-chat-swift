//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    // Creates or updates a reminder for a message
    static func createReminder(messageId: MessageId, request: ReminderRequestBody) -> Endpoint<ReminderResponsePayload> {
        .init(
            path: .reminder(messageId),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }
    
    // Updates an existing reminder for a message
    static func updateReminder(messageId: MessageId, request: ReminderRequestBody) -> Endpoint<ReminderResponsePayload> {
        .init(
            path: .reminder(messageId),
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: request
        )
    }
    
    // Deletes a reminder for a message
    static func deleteReminder(messageId: MessageId) -> Endpoint<EmptyResponse> {
        .init(
            path: .reminder(messageId),
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
    
    // Queries reminders with the provided parameters
    static func queryReminders(query: MessageReminderListQuery) -> Endpoint<RemindersQueryPayload> {
        .init(
            path: .reminders,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: query
        )
    }
}
