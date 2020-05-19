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
        var channel = client.channel(type: .messaging, members: [currentUser])
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)
        
        channel = client.channel(type: .messaging, members: [currentUser, user1])
        XCTAssertEqual(channel.name, user1.name)
        XCTAssertEqual(channel.imageURL, user1.avatarURL)
        
        channel = client.channel(type: .messaging, members: [user1, user2])
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)

        var extraData = ChannelExtraData(name: "test")
        channel = client.channel(type: .messaging, members: [currentUser, user1], extraData: extraData)
        XCTAssertEqual(channel.name, extraData.name)
        XCTAssertEqual(channel.imageURL, extraData.imageURL)
        
        extraData = ChannelExtraData(imageURL: URL(string: "http://extradata.com"))
        channel = client.channel(type: .messaging, members: [currentUser, user1], extraData: extraData)
        XCTAssertNil(channel.name)
        XCTAssertEqual(channel.imageURL, extraData.imageURL)
    }
}
