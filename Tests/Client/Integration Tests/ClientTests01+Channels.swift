//
//  ClientTests01_Channels.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 16/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class ClientTests01_Channels: TestCase {
    
    func test01Channels() {
        expect("channels with current user member") { expectation in
            let query = ChannelsQuery(filter: .key("members", .in([Member.current])), pagination: .limit(2))
            Client.shared.channels(query: query) { result in
                if let channelResponses = try? result.get() {
                    XCTAssertEqual(channelResponses.count, 2)
                    expectation.fulfill()
                }
            }
        }
    }
    
    func test02Channel() {
        expect("a default channel") { expectation in
            Client.shared.channel(query: ChannelQuery(channel: self.defaultChannel)) { result in
                if let channelResponse = try? result.get() {
                    XCTAssertEqual(self.defaultChannel.cid, channelResponse.channel.cid)
                    expectation.fulfill()
                }
            }
        }
    }
}
