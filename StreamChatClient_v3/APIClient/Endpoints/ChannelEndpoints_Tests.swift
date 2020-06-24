//
// ChannelEndpoints_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class ChannelListPayload_Tests: XCTestCase {
    let channelJSON: Data = {
        let url = Bundle(for: ChannelListPayload_Tests.self).url(forResource: "ChannelsQuery", withExtension: "json")!
        return try! Data(contentsOf: url)
    }()
    
    func test_channelQueryJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(ChannelListPayload<DefaultDataTypes>.self, from: channelJSON)
        XCTAssertEqual(payload.channels.count, 20)
    }
}

class ChannelEndpointPayloadTests: XCTestCase {
    let channelJSON: Data = {
        let url = Bundle(for: ChannelListPayload_Tests.self).url(forResource: "Channel", withExtension: "json")!
        return try! Data(contentsOf: url)
    }()
    
    func test_channelJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(ChannelPayload<DefaultDataTypes>.self, from: channelJSON)
        
        XCTAssertEqual(payload.watcherCount, 7)
        XCTAssertEqual(payload.members.count, 4)
        
        let channel = payload.channel
        XCTAssertEqual(channel.cid, try! ChannelId(cid: "messaging:general"))
        XCTAssertEqual(channel.created, "2019-05-10T14:03:49.505006Z".toDate())
        XCTAssertNotNil(channel.createdBy)
        XCTAssertEqual(channel.typeRawValue, "messaging")
        XCTAssertEqual(channel.isFrozen, true)
        XCTAssertEqual(channel.memberCount, 4)
        XCTAssertEqual(channel.updated, "2019-05-10T14:03:49.505006Z".toDate())
        
        XCTAssertEqual(channel.extraData.name, "The water cooler")
        XCTAssertEqual(channel.extraData.imageURL?.absoluteString,
                       "https://images.unsplash.com/photo-1512138664757-360e0aad5132?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2851&q=80")
        
        let config = channel.config
        XCTAssertEqual(config.reactionsEnabled, true)
        XCTAssertEqual(config.typingEventsEnabled, true)
        XCTAssertEqual(config.readEventsEnabled, true)
        XCTAssertEqual(config.connectEventsEnabled, true)
        XCTAssertEqual(config.uploadsEnabled, true)
        XCTAssertEqual(config.repliesEnabled, true)
        XCTAssertEqual(config.searchEnabled, true)
        XCTAssertEqual(config.mutesEnabled, true)
        XCTAssertEqual(config.urlEnrichmentEnabled, true)
        XCTAssertEqual(config.flagsEnabled, false)
        XCTAssertEqual(config.messageRetention, "infinite")
        XCTAssertEqual(config.maxMessageLength, 5000)
        XCTAssertEqual(config.commands,
                       [.init(name: "giphy", description: "Post a random gif to the channel", set: "fun_set", args: "[text]")])
        XCTAssertEqual(config.created, "2019-03-21T15:49:15.40182Z".toDate())
        XCTAssertEqual(config.updated, "2020-03-17T18:54:09.460881Z".toDate())
    }
    
    func test_channelJSON_isSerialized_withNoExtraData() throws {
        enum NoExtraDataTypes: ExtraDataTypes {
            typealias Channel = NoExtraData
            typealias Message = NoExtraData
            typealias User = NoExtraData
        }
        
        let payload = try JSONDecoder.default.decode(ChannelPayload<NoExtraDataTypes>.self, from: channelJSON)
        
        XCTAssertEqual(payload.watcherCount, 7)
        XCTAssertEqual(payload.members.count, 4)
        
        let channel = payload.channel
        XCTAssertEqual(channel.cid, try! ChannelId(cid: "messaging:general"))
        XCTAssertEqual(channel.created, "2019-05-10T14:03:49.505006Z".toDate())
        XCTAssertNotNil(channel.createdBy)
        XCTAssertEqual(channel.typeRawValue, "messaging")
        XCTAssertEqual(channel.isFrozen, true)
        XCTAssertEqual(channel.memberCount, 4)
        XCTAssertEqual(channel.updated, "2019-05-10T14:03:49.505006Z".toDate())
        
        let config = channel.config
        XCTAssertEqual(config.reactionsEnabled, true)
        XCTAssertEqual(config.typingEventsEnabled, true)
        XCTAssertEqual(config.readEventsEnabled, true)
        XCTAssertEqual(config.connectEventsEnabled, true)
        XCTAssertEqual(config.uploadsEnabled, true)
        XCTAssertEqual(config.repliesEnabled, true)
        XCTAssertEqual(config.searchEnabled, true)
        XCTAssertEqual(config.mutesEnabled, true)
        XCTAssertEqual(config.urlEnrichmentEnabled, true)
        XCTAssertEqual(config.flagsEnabled, false)
        XCTAssertEqual(config.messageRetention, "infinite")
        XCTAssertEqual(config.maxMessageLength, 5000)
        XCTAssertEqual(config.commands,
                       [.init(name: "giphy", description: "Post a random gif to the channel", set: "fun_set", args: "[text]")])
        XCTAssertEqual(config.created, "2019-03-21T15:49:15.40182Z".toDate())
        XCTAssertEqual(config.updated, "2020-03-17T18:54:09.460881Z".toDate())
    }
}
