//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ModerationEndpoints_Tests: XCTestCase {
    func test_muteUser_buildsCorrectly() {
        let userId: UserId = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .muteUser(true),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .muteUser(userId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("moderation/mute", endpoint.path.value)
    }
    
    func test_unmuteUser_buildsCorrectly() {
        let userId: UserId = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .muteUser(false),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .unmuteUser(userId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("moderation/unmute", endpoint.path.value)
    }
    
    func test_banMember_buildsCorrectly() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        let timeoutInMinutes = 15
        let reason: String = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .banMember,
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
        XCTAssertEqual("moderation/ban", endpoint.path.value)
    }
    
    func test_unbanMember_buildsCorrectly() {
        let userId: UserId = .unique
        let cid: ChannelId = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .banMember,
            method: .delete,
            queryItems: ChannelMemberBanRequestPayload(userId: userId, cid: cid),
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint.
        let endpoint: Endpoint<EmptyResponse> = .unbanMember(userId, cid: cid)
        
        // Assert endpoint is built correctly.
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("moderation/ban", endpoint.path.value)
    }
    
    func test_flagUser_buildsCorrectly() {
        let testCases = [
            (true, EndpointPath.flagUser(true)),
            (false, EndpointPath.flagUser(false))
        ]
        
        for (flag, path) in testCases {
            let userId: UserId = .unique
            
            let expectedEndpoint = Endpoint<FlagUserPayload>(
                path: path,
                method: .post,
                queryItems: nil,
                requiresConnectionId: false,
                body: ["target_user_id": userId]
            )
            
            // Build endpoint.
            let endpoint: Endpoint<FlagUserPayload> = .flagUser(flag, with: userId)
            
            // Assert endpoint is built correctly.
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual(flag ? "moderation/flag" : "moderation/unflag", endpoint.path.value)
        }
    }
    
    func test_flagMessage_buildsCorrectly() {
        let testCases = [
            (true, EndpointPath.flagMessage(true)),
            (false, EndpointPath.flagMessage(false))
        ]
        
        for (flag, path) in testCases {
            let messageId: MessageId = .unique
            
            let expectedEndpoint = Endpoint<FlagMessagePayload>(
                path: path,
                method: .post,
                queryItems: nil,
                requiresConnectionId: false,
                body: ["target_message_id": messageId]
            )
            
            // Build endpoint.
            let endpoint: Endpoint<FlagMessagePayload> = .flagMessage(flag, with: messageId)
            
            // Assert endpoint is built correctly.
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
            XCTAssertEqual(flag ? "moderation/flag" : "moderation/unflag", endpoint.path.value)
        }
    }
}
