//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

final class ChannelEndpoints_Tests: XCTestCase {
    func test_channels_buildsCorrectly() {
        let filter = Filter.in("member", ["Luke"])
        
        let testCases: [(ChannelListQuery, Bool)] = [
            (.init(filter: filter, options: .state), true),
            (.init(filter: filter, options: .presence), true),
            (.init(filter: filter, options: .watch), true),
            (.init(filter: filter, options: .all), true),
            (.init(filter: filter, options: []), false)
        ]
        
        for (query, requiresConnectionId) in testCases {
            let expectedEndpoint = Endpoint<ChannelListPayload<DefaultExtraData>>(
                path: "channels",
                method: .get,
                queryItems: nil,
                requiresConnectionId: requiresConnectionId,
                body: ["payload": query]
            )
            
            // Build endpoint
            let endpoint: Endpoint<ChannelListPayload<DefaultExtraData>> = .channels(query: query)
            
            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        }
    }
    
    func test_channel_buildsCorrectly() {
        let channelID = ChannelId(type: .livestream, id: "qwerty")
        
        let testCases: [(ChannelQuery<DefaultExtraData>, Bool)] = [
            (.init(cid: channelID, options: .state), true),
            (.init(cid: channelID, options: .presence), true),
            (.init(cid: channelID, options: .watch), true),
            (.init(cid: channelID, options: .all), true),
            (.init(cid: channelID, options: []), false)
        ]
        
        for (query, requiresConnectionId) in testCases {
            let expectedEndpoint =
                Endpoint<ChannelPayload<DefaultExtraData>>(
                    path: "channels/\(query.cid.type.rawValue)/\(query.cid.id)/query",
                    method: .post,
                    queryItems: nil,
                    requiresConnectionId: requiresConnectionId,
                    body: query
                )
            
            // Build endpoint
            let endpoint: Endpoint<ChannelPayload<DefaultExtraData>> = .channel(query: query)
            
            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        }
    }
    
    func test_updateChannel_buildsCorrectly() {
        let channelPayload: ChannelEditDetailPayload<DefaultExtraData> = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(channelPayload.cid.type)/\(channelPayload.cid.id)",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["data": channelPayload]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .updateChannel(channelPayload: channelPayload)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_deleteChannel_buildsCorrectly() {
        let cid = ChannelId.unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type)/\(cid.id)",
            method: .delete,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .deleteChannel(cid: cid)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_hideChannel_buildsCorrectly() {
        let testCases = [true, false]
        
        for clearHistory in testCases {
            let cid = ChannelId.unique
            let userId = UserId.unique
            
            let expectedEndpoint = Endpoint<EmptyResponse>(
                path: "channels/\(cid.type)/\(cid.id)/hide",
                method: .post,
                queryItems: nil,
                requiresConnectionId: false,
                body: HideChannelRequest(userId: userId, clearHistory: clearHistory)
            )
            
            // Build endpoint
            let endpoint: Endpoint<EmptyResponse> = .hideChannel(cid: cid, userId: userId, clearHistory: clearHistory)
            
            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        }
    }
    
    func test_muteChannel_buildsCorrectly() {
        let testCases = [
            (true, "moderation/mute/channel"),
            (false, "moderation/unmute/channel")
        ]
        
        for (mute, path) in testCases {
            let channelID = ChannelId.unique
            
            let expectedEndpoint = Endpoint<EmptyResponse>(
                path: path,
                method: .post,
                queryItems: nil,
                requiresConnectionId: true,
                body: ["channel_cid": channelID]
            )
            
            // Build endpoint
            let endpoint: Endpoint<EmptyResponse> = .muteChannel(cid: channelID, mute: mute)
            
            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        }
    }
    
    func test_showChannel_buildsCorrectly() {
        let cid = ChannelId.unique
        let userId = UserId.unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type)/\(cid.id)/show",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["userId": userId]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .showChannel(cid: cid, userId: userId)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_sendMessage_buildsCorrectly() {
        let cid = ChannelId.unique
        
        let messageBody = MessageRequestBody<DefaultExtraData>(
            id: .unique,
            user: .dummy(userId: .unique),
            text: .unique,
            command: .unique,
            args: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            extraData: .defaultValue
        )
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type)/\(cid.id)/message",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": messageBody]
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .sendMessage(cid: cid, messagePayload: messageBody)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_addMembers_buildsCorrectly() {
        let cid = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type)/\(cid.id)",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["add_members": userIds]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .addMembers(cid: cid, userIds: userIds)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_removeMembers_buildsCorrectly() {
        let cid = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type)/\(cid.id)",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["remove_members": userIds]
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .removeMembers(cid: cid, userIds: userIds)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_markRead_buildsCorrectly() {
        let cid = ChannelId.unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type)/\(cid.id)/read",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        let endpoint = Endpoint<EmptyResponse>.markRead(cid: cid)
        
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_markAllRead_buildsCorrectly() {
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/read",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        let endpoint = Endpoint<EmptyResponse>.markAllRead()
        
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_sendEvent_buildsCorrectly() {
        let cid = ChannelId.unique
        let eventType = EventType.userStartTyping
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type)/\(cid.id)/event",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": ["type": eventType]]
        )
        
        let endpoint = Endpoint<EmptyResponse>.sendEvent(cid: cid, eventType: eventType)
        
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}

extension ChannelEditDetailPayload where ExtraData == DefaultExtraData {
    static var unique: Self {
        Self(
            cid: .unique,
            team: .unique,
            members: [],
            invites: [],
            extraData: .init()
        )
    }
}
