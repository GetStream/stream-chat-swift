//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
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
    
    func test_banMember_buildsCorrectly() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let timeoutInMinutes = 15
        let reason: String = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "moderation/ban",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ChannelMemberBanRequestPayload(
                userId: userId,
                cid: cid,
                timeoutInMinutes: timeoutInMinutes,
                reason: reason
            )
        )
        
        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .banMember(userId, cid: cid, timeoutInMinutes: timeoutInMinutes, reason: reason)
        
        // Assert endpoint is built correctly.
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_unbanMember_buildsCorrectly() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "moderation/ban",
            method: .delete,
            queryItems: ChannelMemberBanRequestPayload(userId: userId, cid: cid),
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .unbanMember(userId, cid: cid)
        
        // Assert endpoint is built correctly.
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}
