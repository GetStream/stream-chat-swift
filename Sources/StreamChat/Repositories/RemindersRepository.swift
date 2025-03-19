//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData

/// A response containing a list of reminders and pagination information.
struct ReminderListResponse {
    var reminders: [MessageReminder]
    var next: String?
}

/// Repository for handling message reminders.
class RemindersRepository {
    /// The database container for local storage operations.
    private let database: DatabaseContainer
    
    /// The API client for remote operations.
    private let apiClient: APIClient
    
    /// Creates a new RemindersRepository instance.
    /// - Parameters:
    ///   - database: The database container for local storage operations.
    ///   - apiClient: The API client for remote operations.
    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }
    
    /// Loads reminders based on the provided query.
    /// - Parameters:
    ///   - query: The query containing filtering and sorting parameters.
    ///   - completion: Called when the operation completes.
    func loadReminders(
        query: MessageReminderListQuery,
        completion: @escaping (Result<ReminderListResponse, Error>) -> Void
    ) {
        apiClient.request(endpoint: .queryReminders(query: query)) { [weak self] result in
            switch result {
            case .success(let response):
                var reminders: [MessageReminder] = []
                self?.database.write({ session in
                    reminders = try response.reminders.compactMap { payload in
                        let reminderDTO = try session.saveReminder(payload: payload, cache: nil)
                        return try reminderDTO.asModel()
                    }
                }, completion: { error in
                    if let error {
                        completion(.failure(error))
                        return
                    }
                    completion(.success(ReminderListResponse(reminders: reminders, next: response.next)))
                })
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Creates a new reminder for a message.
    /// - Parameters:
    ///   - messageId: The message identifier to create a reminder for.
    ///   - cid: The channel identifier the message belongs to.
    ///   - remindAt: The date when the user should be reminded about this message.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func createReminder(
        messageId: MessageId,
        cid: ChannelId,
        remindAt: Date?,
        completion: @escaping ((Result<MessageReminder, Error>) -> Void)
    ) {
        let requestBody = ReminderRequestBody(remindAt: remindAt)
        let endpoint: Endpoint<ReminderResponsePayload> = .createReminder(
            messageId: messageId,
            request: requestBody
        )

        // First optimistically create the reminder locally
        database.write { session in
            let now = Date()
            let reminderPayload = ReminderPayload(
                channelCid: cid,
                messageId: messageId,
                message: nil,
                remindAt: remindAt,
                createdAt: now,
                updatedAt: now
            )
            
            do {
                try session.saveReminder(payload: reminderPayload, cache: nil)
            } catch {
                log.warning("Failed to optimistically create reminder in the database: \(error)")
            }
        } completion: { _ in
            // Make the API call to create the reminder
            self.apiClient.request(endpoint: endpoint) { result in
                switch result {
                case .success(let payload):
                    var reminder: MessageReminder!
                    self.database.write({ session in
                        let messageReminder = payload.reminder
                        reminder = try session.saveReminder(payload: messageReminder, cache: nil).asModel()
                    }, completion: { error in
                        if let error {
                            completion(.failure(error))
                        } else {
                            completion(.success(reminder))
                        }
                    })
                case .failure(let error):
                    // Rollback the optimistic update if the API call fails
                    self.database.write({ session in
                        session.deleteReminder(messageId: messageId)
                    }, completion: { _ in
                        completion(.failure(error))
                    })
                }
            }
        }
    }
    
    /// Updates an existing reminder for a message.
    /// - Parameters:
    ///   - messageId: The message identifier for the reminder to update.
    ///   - cid: The channel identifier the message belongs to.
    ///   - remindAt: The new date when the user should be reminded about this message.
    ///   - completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func updateReminder(
        messageId: MessageId,
        cid: ChannelId,
        remindAt: Date?,
        completion: @escaping ((Result<MessageReminder, Error>) -> Void)
    ) {
        let requestBody = ReminderRequestBody(remindAt: remindAt)
        let endpoint: Endpoint<ReminderResponsePayload> = .updateReminder(messageId: messageId, request: requestBody)
        
        // Save current data for potential rollback
        var originalRemindAt: Date?
        
        // First optimistically update the reminder locally
        database.write { session in
            // Verify the message exists
            guard let messageDTO = session.message(id: messageId) else {
                log.warning("Failed to find message with id: \(messageId) for updating reminder")
                return
            }

            originalRemindAt = messageDTO.reminder?.remindAt?.bridgeDate

            messageDTO.reminder?.remindAt = remindAt?.bridgeDate
        } completion: { [weak self] _ in
            // Make the API call to update the reminder
            self?.apiClient.request(endpoint: endpoint) { result in
                switch result {
                case .success(let payload):
                    var reminder: MessageReminder!
                    self?.database.write({ session in
                        let messageReminder = payload.reminder
                        reminder = try session.saveReminder(payload: messageReminder, cache: nil).asModel()
                    }, completion: { error in
                        if let error {
                            completion(.failure(error))
                        } else {
                            completion(.success(reminder))
                        }
                    })

                case .failure(let error):
                    self?.database.write({ session in
                        // Restore original value
                        guard let messageDTO = session.message(id: messageId) else {
                            return
                        }
                        messageDTO.reminder?.remindAt = originalRemindAt?.bridgeDate
                    }, completion: { _ in
                        completion(.failure(error))
                    })
                }
            }
        }
    }
    
    /// Deletes a reminder for a message.
    /// - Parameters:
    ///   - messageId: The message identifier for the reminder to delete.
    ///   - cid: The channel identifier the message belongs to.
    ///   - completion: Called when the API call is finished. Called with an error if the remote update fails.
    func deleteReminder(
        messageId: MessageId,
        cid: ChannelId,
        completion: @escaping ((Error?) -> Void)
    ) {
        let endpoint: Endpoint<EmptyResponse> = .deleteReminder(messageId: messageId)
        
        // Save data for potential rollback
        var originalPayload: ReminderPayload?
        
        // First optimistically delete the reminder locally
        database.write { session in
            // Verify the message exists
            guard let messageDTO = session.message(id: messageId) else {
                log.warning("Failed to find message with id: \(messageId) for deleting reminder")
                return
            }
            
            // Get original reminder data for potential rollback
            if let reminderDTO = messageDTO.reminder {
                // Store the original state for potential rollback
                originalPayload = ReminderPayload(
                    channelCid: cid,
                    messageId: messageId,
                    message: nil,
                    remindAt: reminderDTO.remindAt?.bridgeDate,
                    createdAt: reminderDTO.createdAt.bridgeDate,
                    updatedAt: reminderDTO.updatedAt.bridgeDate
                )
            }
            
            // Delete optimistically
            session.deleteReminder(messageId: messageId)
        } completion: { [weak self] _ in
            // Make the API call to delete the reminder
            self?.apiClient.request(endpoint: endpoint) { result in
                switch result {
                case .success:
                    completion(nil)
                    
                case .failure(let error):
                    // Rollback the optimistic delete if the API call fails
                    guard let originalPayload = originalPayload else {
                        completion(error)
                        return
                    }
                    
                    self?.database.write({ session in
                        // Restore original reminder
                        do {
                            try session.saveReminder(payload: originalPayload, cache: nil)
                        } catch {
                            log.warning("Failed to rollback reminder deletion: \(error)")
                        }
                    }, completion: { _ in
                        completion(error)
                    })
                }
            }
        }
    }
}
