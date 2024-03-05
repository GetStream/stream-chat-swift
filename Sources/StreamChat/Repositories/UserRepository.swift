//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct UserRepository {
    let database: DatabaseContainer
    let apiClient: APIClient

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }
}

@available(iOS 13.0, *)
extension UserRepository {
    /// Returns an array of users in the local database.
    func watchers(for ids: Set<UserId>, in cid: ChannelId) async throws -> [ChatUser] {
        guard !ids.isEmpty else { return [] }
        return try await database.backgroundRead { context in
            try UserDTO.loadWatchers(cid: cid, ids: ids, context: context)
                .map { try $0.asModel() as ChatUser }
        }
    }
}
