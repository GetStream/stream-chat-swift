//
//  ClientTests02_Message.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 17/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class ClientTests02_Message: TestCase {
    
    func test01Message() {
        expect("get a default channel messages and requests the first message by id") { expectation in
            self.message(from: self.defaultChannel) { message in
                Client.shared.message(with: message.id) { result in
                    if let messageResponse = try? result.get() {
                        XCTAssertEqual(message.id, messageResponse.message.id)
                        XCTAssertEqual(message.text, messageResponse.message.text)
                        XCTAssertEqual(message.args, messageResponse.message.args)
                        expectation.fulfill()
                    }
                }
            }
        }
    }
    
    /// - TODO: make a full flow:
    ///   - add 2 messages from another member to 2 shared channels.
    ///   - mark all as read.
    ///   - check that both messages was read.
    func test02MarlAllRead() {
        expect("mark all messages as read") { expectation in
            Client.shared.markAllRead {
                XCTAssertNil($0.error)
                expectation.fulfill()
            }
        }
    }
}

extension ClientTests02_Message {
    private func message(from channel: Channel, _ completion: @escaping (Message) -> Void) {
        let query = ChannelQuery(channel: channel, pagination: .limit(1), options: .state)
        
        Client.shared.channel(query: query) { result in
            if let channelResponse = try? result.get(), let message = channelResponse.messages.first {
                completion(message)
            }
        }
    }
}
