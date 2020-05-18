//
//  Channel+Setup.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 18/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class Channel_Setup: XCTestCase {
    
    let client = sharedClient
    
    let user1: User = {
        var user = User(id: "u1")
        user.name = "Mr First"
        user.avatarURL = URL(string: "http://first.com")
        return user
    }()
    
    let user2: User = {
        var user = User(id: "u2")
        user.name = "Mr Second"
        user.avatarURL = URL(string: "http://second.com")
        return user
    }()
    
    let user3: User = {
        var user = User(id: "u3")
        user.name = "Mr Third"
        return user
    }()
    
    let user4: User = {
        var user = User(id: "u4")
        user.name = "Mr Fourth"
        return user
    }()
    
    let user5: User = {
        var user = User(id: "u5")
        user.name = "Mr Fifth"
        return user
    }()

    override func setUp() {
        sharedClient.userAtomic.set(user1)
    }

    func test_channelExtraData_withId() {
        let channelId = "test_id"
        
        var channel = client.channel(type: .messaging, id: channelId)
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)
        
        channel = client.channel(type: .messaging, id: channelId, members: [user1])
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)
        
        channel = client.channel(type: .messaging, id: channelId, members: [user1, user2])
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)
        
        channel = client.channel(type: .messaging, id: channelId, members: [user1, user2, user3])
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)
    }
    
    func test_channelExtraData_withEmptyId() {
        var channel = client.channel(type: .messaging, members: [user1])
        XCTAssertNil(channel.name)
        XCTAssertNil(channel.imageURL)
        
        channel = client.channel(type: .messaging, members: [user1, user2])
        XCTAssertEqual(channel.name, user2.name)
        XCTAssertEqual(channel.imageURL, user2.avatarURL)

        channel = client.channel(type: .messaging, members: [user1, user3])
        XCTAssertEqual(channel.name, user3.name)
        XCTAssertNil(channel.imageURL)
        
        channel = client.channel(type: .messaging, members: [user1, user3, user2])
        XCTAssertEqual(channel.name, [user3.name, user2.name].joined(separator: ", "))
        XCTAssertEqual(channel.imageURL, user2.avatarURL)
        
        channel = client.channel(type: .messaging, members: [user1, user3, user2, user4, user5])
        XCTAssertEqual(channel.name, [user3.name, user2.name, user4.name].joined(separator: ", ") + " and 1 more")
        XCTAssertEqual(channel.imageURL, user2.avatarURL)
    }
    
    func test_channelExtraData_withEmptyIdAndCustomExtraData() {
        var extraData = ChannelExtraData(name: "test")
        var channel = client.channel(type: .messaging, members: [user1, user2], extraData: extraData)
        XCTAssertEqual(channel.name, extraData.name)
        XCTAssertEqual(channel.imageURL, extraData.imageURL)
        
        extraData = ChannelExtraData(imageURL: URL(string: "http://extradata.com"))
        channel = client.channel(type: .messaging, members: [user1, user2], extraData: extraData)
        XCTAssertEqual(channel.name, user2.name)
        XCTAssertEqual(channel.imageURL, extraData.imageURL)
    }
}
