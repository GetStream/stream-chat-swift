//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class ChannelEndpoints_Tests: XCTestCase {
    func test_channels_buildsCorrectly() {
        let filter: Filter<ChannelListFilterScope> = .containMembers(userIds: [.unique])
        
        func channelListQuery(options: QueryOptions) -> ChannelListQuery {
            var query: ChannelListQuery = .init(filter: filter)
            query.options = options
            return query
        }
        
        let testCases: [(ChannelListQuery, Bool)] = [
            (channelListQuery(options: .state), true),
            (channelListQuery(options: .presence), true),
            (channelListQuery(options: .watch), true),
            (channelListQuery(options: .all), true),
            (channelListQuery(options: []), false)
        ]
        
        for (query, requiresConnectionId) in testCases {
            let expectedEndpoint = Endpoint<ChannelListPayload<NoExtraData>>(
                path: "channels",
                method: .get,
                queryItems: nil,
                requiresConnectionId: requiresConnectionId,
                body: ["payload": query]
            )
            
            // Build endpoint
            let endpoint: Endpoint<ChannelListPayload<NoExtraData>> = .channels(query: query)
            
            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        }
    }
    
    func test_channel_buildsCorrectly() {
        let cid = ChannelId(type: .livestream, id: "qwerty")
        
        func channelQuery(options: QueryOptions) -> ChannelQuery {
            var query: ChannelQuery = .init(cid: cid)
            query.options = options
            return query
        }
        
        let testCases: [(ChannelQuery, Bool)] = [
            (channelQuery(options: .state), true),
            (channelQuery(options: .presence), true),
            (channelQuery(options: .watch), true),
            (channelQuery(options: .all), true),
            (channelQuery(options: []), false)
        ]
        
        for (query, requiresConnectionId) in testCases {
            let expectedEndpoint =
                Endpoint<ChannelPayload<NoExtraData>>(
                    path: "channels/\(query.apiPath)/query",
                    method: .post,
                    queryItems: nil,
                    requiresConnectionId: requiresConnectionId,
                    body: query
                )
            
            // Build endpoint
            let endpoint: Endpoint<ChannelPayload<NoExtraData>> = .channel(query: query)
            
            // Assert endpoint is built correctly
            XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        }
    }
    
    func test_updateChannel_buildsCorrectly() {
        let channelPayload: ChannelEditDetailPayload<NoExtraData> = .unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(channelPayload.apiPath)",
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
            path: "channels/\(cid.type.rawValue)/\(cid.id)",
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

    func test_truncateChannel_buildsCorrectly() {
        let cid = ChannelId.unique

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type.rawValue)/\(cid.id)/truncate",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )

        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .truncateChannel(cid: cid)

        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }

    func test_hideChannel_buildsCorrectly() {
        let testCases = [true, false]
        
        for clearHistory in testCases {
            let cid = ChannelId.unique

            let expectedEndpoint = Endpoint<EmptyResponse>(
                path: "channels/\(cid.type.rawValue)/\(cid.id)/hide",
                method: .post,
                queryItems: nil,
                requiresConnectionId: false,
                body: ["clear_history": clearHistory]
            )
            
            // Build endpoint
            let endpoint: Endpoint<EmptyResponse> = .hideChannel(cid: cid, clearHistory: clearHistory)
            
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

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type.rawValue)/\(cid.id)/show",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
        
        // Build endpoint
        let endpoint: Endpoint<EmptyResponse> = .showChannel(cid: cid)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_sendMessage_buildsCorrectly() {
        let cid = ChannelId.unique
        
        let messageBody = MessageRequestBody<NoExtraData>(
            id: .unique,
            user: .dummy(userId: .unique),
            text: .unique,
            command: .unique,
            args: .unique,
            parentId: .unique,
            showReplyInChannel: true,
            extraData: .defaultValue
        )
        
        let expectedEndpoint = Endpoint<MessagePayload<NoExtraData>.Boxed>(
            path: "channels/\(cid.type.rawValue)/\(cid.id)/message",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["message": messageBody]
        )
        
        // Build endpoint
        let endpoint: Endpoint<MessagePayload<NoExtraData>.Boxed> = .sendMessage(cid: cid, messagePayload: messageBody)
        
        // Assert endpoint is built correctly
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_addMembers_buildsCorrectly() {
        let cid = ChannelId.unique
        let userIds: Set<UserId> = Set([UserId.unique])

        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type.rawValue)/\(cid.id)",
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
            path: "channels/\(cid.type.rawValue)/\(cid.id)",
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
            path: "channels/\(cid.type.rawValue)/\(cid.id)/read",
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
            path: "channels/\(cid.type.rawValue)/\(cid.id)/event",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["event": ["type": eventType]]
        )
        
        let endpoint = Endpoint<EmptyResponse>.sendEvent(cid: cid, eventType: eventType)
        
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_enableSlowMode_buildsCorrectly() {
        let cid = ChannelId.unique
        let cooldownDuration = Int.random(in: 0...120)
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type.rawValue)/\(cid.id)",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["set": ["cooldown": cooldownDuration]]
        )
        
        let endpoint = Endpoint<EmptyResponse>.enableSlowMode(cid: cid, cooldownDuration: cooldownDuration)
        
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_stopWatching_buildsCorrectly() {
        let cid = ChannelId.unique
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/\(cid.type.rawValue)/\(cid.id)/stop-watching",
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: nil
        )
        
        let endpoint = Endpoint<EmptyResponse>.stopWatching(cid: cid)
        
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_channelWatchers_buildsCorrectly() {
        let cid = ChannelId.unique
        let pagination = Pagination(pageSize: .random(in: 10...100), offset: .random(in: 10...100))
        let query = ChannelWatcherListQuery(cid: cid, pagination: pagination)
        
        let expectedEndpoint = Endpoint<ChannelPayload<NoExtraData>>(
            path: "channels/\(query.cid.type.rawValue)/\(query.cid.id)/query",
            method: .post,
            queryItems: nil,
            requiresConnectionId: true, // Observing watchers always requires connection id
            body: query
        )
        
        let endpoint: Endpoint<ChannelPayload<NoExtraData>> = .channelWatchers(query: query)
        
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
    
    func test_freezeChannel_buildsCorrectly() {
        let cid = ChannelId.unique
        let freeze = Bool.random()
        
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: "channels/" + cid.apiPath,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["set": ["frozen": freeze]]
        )
        
        let endpoint: Endpoint<EmptyResponse> = .freezeChannel(freeze, cid: cid)
        
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
    }
}

extension ChannelEditDetailPayload where ExtraData == NoExtraData {
    static var unique: Self {
        Self(
            cid: .unique,
            name: .unique,
            imageURL: .unique(),
            team: .unique,
            members: [],
            invites: [],
            extraData: .init()
        )
    }
}
