//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

/// Mock implementation of RemindersRepository
final class RemindersRepository_Mock: RemindersRepository {
    var loadReminders_callCount: Int = 0
    var loadReminders_query: MessageReminderListQuery?
    var loadReminders_completion: ((Result<ReminderListResponse, Error>) -> Void)?
    var loadReminders_completion_result: Result<ReminderListResponse, Error>?
    
    var createReminder_messageId: MessageId?
    var createReminder_cid: ChannelId?
    var createReminder_remindAt: Date?
    var createReminder_completion: ((Result<MessageReminder, Error>) -> Void)?
    var createReminder_completion_result: Result<MessageReminder, Error>?
    
    var updateReminder_messageId: MessageId?
    var updateReminder_cid: ChannelId?
    var updateReminder_remindAt: Date?
    var updateReminder_completion: ((Result<MessageReminder, Error>) -> Void)?
    var updateReminder_completion_result: Result<MessageReminder, Error>?
    
    var deleteReminder_messageId: MessageId?
    var deleteReminder_cid: ChannelId?
    var deleteReminder_completion: ((Error?) -> Void)?
    var deleteReminder_error: Error?
    
    /// Default initializer
    override init(database: DatabaseContainer, apiClient: APIClient) {
        super.init(database: database, apiClient: apiClient)
    }
    
    /// Convenience initializer
    init() {
        super.init(database: DatabaseContainer_Spy(), apiClient: APIClient_Spy())
    }
    
    // Cleans up all recorded values
    func cleanUp() {
        loadReminders_query = nil
        loadReminders_completion = nil
        loadReminders_completion_result = nil
        
        createReminder_messageId = nil
        createReminder_cid = nil
        createReminder_remindAt = nil
        createReminder_completion = nil
        createReminder_completion_result = nil
        
        updateReminder_messageId = nil
        updateReminder_cid = nil
        updateReminder_remindAt = nil
        updateReminder_completion = nil
        updateReminder_completion_result = nil
        
        deleteReminder_messageId = nil
        deleteReminder_cid = nil
        deleteReminder_completion = nil
        deleteReminder_error = nil
    }
    
    override func loadReminders(
        query: MessageReminderListQuery,
        completion: @escaping ((Result<ReminderListResponse, Error>) -> Void)
    ) {
        loadReminders_callCount += 1
        loadReminders_query = query
        loadReminders_completion = completion
        
        if let result = loadReminders_completion_result {
            completion(result)
        }
    }
    
    override func createReminder(
        messageId: MessageId,
        cid: ChannelId,
        remindAt: Date?,
        completion: @escaping ((Result<MessageReminder, Error>) -> Void)
    ) {
        createReminder_messageId = messageId
        createReminder_cid = cid
        createReminder_remindAt = remindAt
        createReminder_completion = completion
        
        if let result = createReminder_completion_result {
            completion(result)
        }
    }
    
    override func updateReminder(
        messageId: MessageId,
        cid: ChannelId,
        remindAt: Date?,
        completion: @escaping ((Result<MessageReminder, Error>) -> Void)
    ) {
        updateReminder_messageId = messageId
        updateReminder_cid = cid
        updateReminder_remindAt = remindAt
        updateReminder_completion = completion
        
        if let result = updateReminder_completion_result {
            completion(result)
        }
    }
    
    override func deleteReminder(
        messageId: MessageId, 
        cid: ChannelId, 
        completion: @escaping ((Error?) -> Void)
    ) {
        deleteReminder_messageId = messageId
        deleteReminder_cid = cid
        deleteReminder_completion = completion
        
        completion(deleteReminder_error)
    }
} 
