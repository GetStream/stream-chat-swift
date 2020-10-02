//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - User muting

extension Endpoint {
    static func muteUser(_ userId: UserId) -> Endpoint<EmptyResponse> {
        muteUser(true, with: userId)
    }
    
    static func unmuteUser(_ userId: UserId) -> Endpoint<EmptyResponse> {
        muteUser(false, with: userId)
    }
}

// MARK: - Private

private extension Endpoint {
    static func muteUser(_ mute: Bool, with userId: UserId) -> Endpoint<EmptyResponse> {
        .init(
            path: "moderation/\(mute ? "mute" : "unmute")",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
    }
}
