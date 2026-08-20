//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension MuteResponse {
    /// Converts the MuteResponse to a MuteUsersResponse model.
    /// - Returns: A MuteUsersResponse instance.
    func asModel() -> MuteUsersResponse {
        MuteUsersResponse(
            mutes: mutes?.map { $0.asModel() },
            nonExistingUsers: nonExistingUsers
        )
    }
}

extension MutedUserPayload {
    /// Converts the MutedUserPayload to a MutedUserDetails model.
    /// - Returns: A MutedUserDetails instance.
    func asModel() -> MutedUserDetails {
        MutedUserDetails(
            createdAt: createdAt,
            expires: expires,
            user: target?.asModel(),
            updatedAt: updatedAt
        )
    }
}
