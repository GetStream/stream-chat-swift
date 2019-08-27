//
//  ChannelTests.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 26/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest
import RxSwift
import RxBlocking
@testable import StreamChatCore

final class ChannelTests: TestCase {
    
    let channel = Channel(id: "integration")

    func testQuery() {
        do {
            let response = try channel.query(pagination: .limit(1))
                .toBlocking()
                .toArray()
            
            if let response = response.first {
                XCTAssertEqual(response.channel, channel)
            } else {
                XCTFail("Empty query channel response")
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testSendMessage() {
        expectRequest("Connected with guest token") { [unowned self] test in
            let message = Message(text: "test \(Date())")
            
            self.channel.send(message: message)
                .subscribe(onNext: { response in
                    test.fulfill()
                    XCTAssertFalse(response.message.id.isEmpty)
                    XCTAssertEqual(response.message.text, message.text)
                })
                .disposed(by: self.disposeBag)
        }
    }
}
