//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class ModerationEndpoints_Tests: XCTestCase {
    func test_muteUser_buildsCorrectly() {
        let userId: UserId = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "moderation/mute",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .muteUser(userId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_unmuteUser_buildsCorrectly() {
        let userId: UserId = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "moderation/unmute",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .unmuteUser(userId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
