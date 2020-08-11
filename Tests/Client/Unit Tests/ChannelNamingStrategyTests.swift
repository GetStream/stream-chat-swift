//
//  ChannelNamingStrategyTests.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 18/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class ChannelNamingStrategyTests: XCTestCase {
    
    let currentUser = User(id: "u1", name: "Mr First", avatarURL: URL(string: "http://first.com"))
    let user1 = User(id: "u2", name: "Mr Second", avatarURL: URL(string: "http://second.com"))
    let user2 = User(id: "u3", name: "Mr Third")
    let user3 = User(id: "u4", name: "Mr Fourth")
    let user4 = User(id: "u5", name: "Mr Fifth")
    
    func test_channelNamingStrategry() {
        let strategy = Channel.DefaultNamingStrategy(maxUserNames: 3)
        
        var extraData = ChannelExtraData(name: user1.name, imageURL: user1.avatarURL)
        var strategyExtraData = strategy.extraData(for: currentUser, members: [user1, currentUser])
        XCTAssertEqual(extraData.name, strategyExtraData?.name)
        XCTAssertEqual(extraData.imageURL, strategyExtraData?.imageURL)
        
        extraData = ChannelExtraData(name: [user1.name, user2.name].joined(separator: ", "))
        strategyExtraData = strategy.extraData(for: currentUser, members: [user1, currentUser, user2])
        XCTAssertEqual(extraData.name, strategyExtraData?.name)
        
        extraData = ChannelExtraData(name: [user1.name, user2.name, user3.name].joined(separator: ", ") + " and 1 more")
        strategyExtraData = strategy.extraData(for: currentUser, members: [user1, user2, user3, currentUser, user4])
        XCTAssertEqual(extraData.name, strategyExtraData?.name)
    }
    
    func test_channelNamingStrategry_edgeCases() {
        var strategy = Channel.DefaultNamingStrategy(maxUserNames: -1)
        var extraData = ChannelExtraData(name: "1 member", imageURL: user1.avatarURL)
        var strategyExtraData = strategy.extraData(for: currentUser, members: [user1, currentUser])
        XCTAssertEqual(extraData.name, strategyExtraData?.name)
        XCTAssertEqual(extraData.imageURL, strategyExtraData?.imageURL)
        
        strategy = Channel.DefaultNamingStrategy(maxUserNames: 0)
        extraData = ChannelExtraData(name: "3 members")
        strategyExtraData = strategy.extraData(for: currentUser, members: [user1, user2, currentUser, user3])
        XCTAssertEqual(extraData.name, strategyExtraData?.name)

        strategy = Channel.DefaultNamingStrategy(maxUserNames: 1)
        extraData = ChannelExtraData(name: user1.name + " and 1 more")
        strategyExtraData = strategy.extraData(for: currentUser, members: [user1, currentUser, user2])
        XCTAssertEqual(extraData.name, strategyExtraData?.name)
        
        strategy = Channel.DefaultNamingStrategy(maxUserNames: 2)
        extraData = ChannelExtraData(name: user1.name + ", " + user2.name)
        strategyExtraData = strategy.extraData(for: currentUser, members: [currentUser, user1, user2])
        XCTAssertEqual(extraData.name, strategyExtraData?.name)
        
        strategy = Channel.DefaultNamingStrategy(maxUserNames: 2)
        extraData = ChannelExtraData(name: user1.name + ", " + user2.name + " and 2 more")
        strategyExtraData = strategy.extraData(for: currentUser, members: [user1, currentUser, user2, user3, user4])
        XCTAssertEqual(extraData.name, strategyExtraData?.name)
    }
}
