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
    
    let currentUser: User = {
        var user = User(id: "u1")
        user.name = "Mr First"
        user.avatarURL = URL(string: "http://first.com")
        return user
    }()
    
    let user1: User = {
        var user = User(id: "u2")
        user.name = "Mr Second"
        user.avatarURL = URL(string: "http://second.com")
        return user
    }()
    
    let user2: User = {
        var user = User(id: "u3")
        user.name = "Mr Third"
        return user
    }()
    
    let user3: User = {
        var user = User(id: "u4")
        user.name = "Mr Fourth"
        return user
    }()
    
    let user4: User = {
        var user = User(id: "u5")
        user.name = "Mr Fifth"
        return user
    }()
    
    func test_channelNamingStrategry() {
        let strategy = Channel.DefaultNamingStrategy(maxUserNames: 3)
        
        var extraData = ChannelExtraData(name: user1.name, imageURL: user1.avatarURL)
        var strategyExtraData = strategy.extraData(for: currentUser, members: [currentUser, user1])
        compareExtraData(lhs: extraData, rhs: strategyExtraData)
        
        extraData = ChannelExtraData(name: [user1.name, user2.name].joined(separator: ", "))
        strategyExtraData = strategy.extraData(for: currentUser, members: [currentUser, user1, user2])
        compareExtraData(lhs: extraData, rhs: strategyExtraData)
        
        extraData = ChannelExtraData(name: [user1.name, user2.name, user3.name].joined(separator: ", ") + " and 1 more")
        strategyExtraData = strategy.extraData(for: currentUser, members: [currentUser, user1, user2, user3, user4])
        compareExtraData(lhs: extraData, rhs: strategyExtraData)
    }
    
    func test_channelNamingStrategry_edgeCases() {
        var strategy = Channel.DefaultNamingStrategy(maxUserNames: -1)
        var extraData = ChannelExtraData(name: "1 member", imageURL: user1.avatarURL)
        var strategyExtraData = strategy.extraData(for: currentUser, members: [currentUser, user1])
        compareExtraData(lhs: extraData, rhs: strategyExtraData)
        
        strategy = Channel.DefaultNamingStrategy(maxUserNames: 0)
        extraData = ChannelExtraData(name: "3 members")
        strategyExtraData = strategy.extraData(for: currentUser, members: [currentUser, user1, user2, user3])
        compareExtraData(lhs: extraData, rhs: strategyExtraData)

        strategy = Channel.DefaultNamingStrategy(maxUserNames: 1)
        extraData = ChannelExtraData(name: user1.name + " and 1 more")
        strategyExtraData = strategy.extraData(for: currentUser, members: [currentUser, user1, user2])
        compareExtraData(lhs: extraData, rhs: strategyExtraData)
        
        strategy = Channel.DefaultNamingStrategy(maxUserNames: 2)
        extraData = ChannelExtraData(name: user1.name + ", " + user2.name)
        strategyExtraData = strategy.extraData(for: currentUser, members: [currentUser, user1, user2])
        compareExtraData(lhs: extraData, rhs: strategyExtraData)
        
        strategy = Channel.DefaultNamingStrategy(maxUserNames: 2)
        extraData = ChannelExtraData(name: user1.name + ", " + user2.name + " and 2 more")
        strategyExtraData = strategy.extraData(for: currentUser, members: [currentUser, user1, user2, user3, user4])
        compareExtraData(lhs: extraData, rhs: strategyExtraData)
    }
    
    private func compareExtraData(lhs: ChannelExtraDataCodable?, rhs: ChannelExtraDataCodable?) {
        XCTAssertEqual(lhs?.name, rhs?.name)
        XCTAssertEqual(lhs?.imageURL, rhs?.imageURL)
    }
}
