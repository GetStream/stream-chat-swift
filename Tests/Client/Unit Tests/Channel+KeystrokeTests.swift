//
//  Channel+KeystrokeTests.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 29/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class Channel_KeystrokeTests: ClientTestCase {
    
    var eventLogger: [EventType]!
    var time: VirtualTime!
    
    override func setUp() {
        super.setUp()
        time = VirtualTime()
        VirtualTimeTimer.time = time
        
        eventLogger = []
        client.outgoingEventsTestLogger = { self.eventLogger.append($0) }
    }
    
    func test_channel_keystroke() throws {
        Channel.startTypingEventTimeout = 5
        Channel.startTypingResendInterval = 5
        
        assert(eventLogger.isEmpty)
        let channel = client.channel(type: .messaging, id: "test-keystroke")
        channel.currentTime = { Date(timeIntervalSinceReferenceDate: self.time.currentTime) }
        
        // 1. The first keystroke.
        sendKeystroke(in: channel)
        XCTAssertEqual(eventLogger, [.typingStart])
        
        // 2. The second keystroke, the request should be skipped.
        time.run(numberOfSeconds: 4)
        sendKeystroke(in: channel)
        XCTAssertEqual(eventLogger, [.typingStart])
        
        // 3. The third keystroke, the request shouldn't be skipped. User is typing too long.
        time.run(numberOfSeconds: 4)
        sendKeystroke(in: channel)
        XCTAssertEqual(eventLogger, [.typingStart, .typingStart])

        // 4. User stopped typing, the `typingStop` event should be sent
        time.run(numberOfSeconds: 6)
        XCTAssertEqual(eventLogger, [.typingStart, .typingStart, .typingStop])
    }
    
    private func sendKeystroke(in channel: Channel) {
        channel.keystroke(client: client, timerType: VirtualTimeTimer.self) { _ in }
    }
}
