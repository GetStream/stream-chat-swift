//
//  Channel+Setup.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 18/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class Channel_SetupTests: XCTestCase {
    
    let client = sharedClient
    
    let currentUser = User(id: "u1", name: "Mr First", avatarURL: URL(string: "http://first.com"))
    let user1 = User(id: "u2", name: "Mr Second", avatarURL: URL(string: "http://second.com"))
    let user2 = User(id: "u3", name: "Mr Third")
    let user3 = User(id: "u4", name: "Mr Fourth")
    let user4 = User(id: "u5", name: "Mr Fifth")
    
    override func setUp() {
        super.setUp()
        sharedClient.userAtomic.set(currentUser)
    }

    func test_channelNameAndImage_channelWithIdDoesntChangeNameAndImage() {
        let channelId = "test_id"
        
        var channel = client.channel(type: .messaging, id: channelId)
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)
        
        channel = client.channel(type: .messaging, id: channelId, members: [currentUser])
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)
        
        channel = client.channel(type: .messaging, id: channelId, members: [currentUser, user2])
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)
        
        channel = client.channel(type: .messaging, id: channelId, members: [currentUser, user2, user3])
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)
    }
    
    func test_channelNameAndImage_withEmptyId() {
        let strategy = MockNamingStrategy()
        
        var channel = client.channel(type: .messaging, members: [], namingStrategy: strategy)
        XCTAssertEqual(channel.name, "0")
        XCTAssertNil(channel.imageURL)
        
        channel = client.channel(type: .messaging, members: [user1, currentUser], namingStrategy: strategy)
        XCTAssertEqual(channel.name, "2")
        XCTAssertEqual(channel.imageURL, user1.avatarURL)

        var extraData = ChannelExtraData(name: "test")
        channel = client.channel(type: .messaging, members: [currentUser, user1], extraData: extraData, namingStrategy: strategy)
        XCTAssertEqual(channel.name, extraData.name)
        XCTAssertEqual(channel.imageURL, extraData.imageURL)
        
        extraData = ChannelExtraData(imageURL: URL(string: "http://extradata.com"))
        channel = client.channel(type: .messaging, members: [currentUser, user1], extraData: extraData, namingStrategy: strategy)
        XCTAssertNil(channel.name)
        XCTAssertEqual(channel.imageURL, extraData.imageURL)
    }
}

fileprivate struct MockNamingStrategy: ChannelNamingStrategy {
    func extraData(for currentUser: User, members: [User]) -> ChannelExtraDataCodable? {
        ChannelExtraData(name: "\(members.count)", imageURL: members.first?.avatarURL)
    }
}
