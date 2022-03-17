//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChannelListPayload_Tests: XCTestCase {
    let channelJSON: Data = {
        let url = Bundle(for: StreamChatTestTools.self).url(forResource: "ChannelsQuery", withExtension: "json")!
        return try! Data(contentsOf: url)
    }()
    
    func test_channelQueryJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(ChannelListPayload.self, from: channelJSON)
        XCTAssertEqual(payload.channels.count, 20)
    }
}

final class ChannelPayload_Tests: XCTestCase {
    let channelJSON: Data = {
        let url = Bundle(for: StreamChatTestTools.self).url(forResource: "Channel", withExtension: "json")!
        return try! Data(contentsOf: url)
    }()
    
    func test_channelJSON_isSerialized_withDefaultExtraData() throws {
        let payload = try JSONDecoder.default.decode(ChannelPayload.self, from: channelJSON)
        
        XCTAssertEqual(payload.watcherCount, 7)
        XCTAssertEqual(payload.watchers?.count, 3)
        XCTAssertEqual(payload.members.count, 4)
        XCTAssertEqual(payload.isHidden, true)
        XCTAssertEqual(payload.watchers?.first?.id, "cilvia")
        
        XCTAssertEqual(payload.messages.count, 25)
        let firstMessage = payload.messages.first(where: { $0.id == "broken-waterfall-5-7aede36b-b89f-4f45-baff-c40c7c1875d9" })!
        
        XCTAssertEqual(firstMessage.type, MessageType.regular)
        XCTAssertEqual(firstMessage.user.id, "broken-waterfall-5")
        XCTAssertEqual(firstMessage.createdAt, "2020-06-09T08:10:40.800912Z".toDate())
        XCTAssertEqual(firstMessage.updatedAt, "2020-06-09T08:10:40.800912Z".toDate())
        XCTAssertNil(firstMessage.deletedAt)
        XCTAssertEqual(firstMessage.text, "sadfadf")
        XCTAssertNil(firstMessage.command)
        XCTAssertNil(firstMessage.args)
        XCTAssertNil(firstMessage.parentId)
        XCTAssertFalse(firstMessage.showReplyInChannel)
        XCTAssert(firstMessage.mentionedUsers.isEmpty)
        XCTAssert(firstMessage.reactionScores.isEmpty)
        XCTAssertEqual(firstMessage.replyCount, 0)
        XCTAssertFalse(firstMessage.isSilent)

        XCTAssertEqual(payload.pinnedMessages.map(\.id), ["broken-waterfall-5-7aede36b-b89f-4f45-baff-c40c7c1875d9"])
        
        let channel = payload.channel
        XCTAssertEqual(channel.cid, try! ChannelId(cid: "messaging:general"))
        XCTAssertEqual(channel.createdAt, "2019-05-10T14:03:49.505006Z".toDate())
        XCTAssertNotNil(channel.createdBy)
        XCTAssertEqual(channel.typeRawValue, "messaging")
        XCTAssertEqual(channel.isFrozen, true)
        XCTAssertEqual(channel.memberCount, 4)
        XCTAssertEqual(channel.updatedAt, "2019-05-10T14:03:49.505006Z".toDate())
        XCTAssertEqual(channel.cooldownDuration, 10)
        XCTAssertEqual(channel.team, "GREEN")
        
        XCTAssertEqual(channel.name, "The water cooler")
        XCTAssertEqual(
            channel.imageURL?.absoluteString,
            "https://images.unsplash.com/photo-1512138664757-360e0aad5132?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2851&q=80"
        )
        
        let firstChannelRead = payload.channelReads.first!
        XCTAssertEqual(firstChannelRead.lastReadAt, "2020-06-10T07:43:11.812841984Z".toDate())
        XCTAssertEqual(firstChannelRead.unreadMessagesCount, 0)
        XCTAssertEqual(firstChannelRead.user.id, "broken-waterfall-5")
        
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
        XCTAssertEqual(config.messageRetention, "infinite")
        XCTAssertEqual(config.maxMessageLength, 5000)
        XCTAssertEqual(
            config.commands,
            [.init(name: "giphy", description: "Post a random gif to the channel", set: "fun_set", args: "[text]")]
        )
        XCTAssertEqual(config.createdAt, "2019-03-21T15:49:15.40182Z".toDate())
        XCTAssertEqual(config.updatedAt, "2020-03-17T18:54:09.460881Z".toDate())

        XCTAssertEqual(payload.membership?.user.id, "broken-waterfall-5")
    }
}
