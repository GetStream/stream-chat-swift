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
class ReminderRepository {
    /// The database container for local storage operations.
    private let database: DatabaseContainer
    
    /// The API client for remote operations.
    private let apiClient: APIClient
    
    /// Creates a new ReminderRepository instance.
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
}
