//
//  ExtraDataTests.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 29/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest
import RxSwift
import RxBlocking
@testable import StreamChatCore

final class ExtraDataTests: TestCase {
    
    let meta = Meta(meta: "test")
    
    lazy var channel = Channel(type: .messaging, id: "extra", extraData: meta)
    
    lazy var message = Message(text: "Check my link!", attachments: [attachment], extraData: meta)
    
    lazy var attachment =
        Attachment(type: .link,
                   title: "Stream Chat iOS SDK",
                   url: URL(string: "https://getstream.io/tutorials/ios-chat/"),
                   imageURL: URL(string: "https://getstream.imgix.net/images/ios-chat-tutorial/iphone_chat_art@3x.png"),
                   extraData: meta)
    
    override func setUp() {
        ExtraData.decodableTypes = [.channel(Meta.self),
                                    .message(Meta.self),
                                    .attachment(Meta.self)]
        super.setUp()
    }
    
    func testChannelExtraData() {
        channel.query(pagination: .limit(1)) { result in
            do {
                let response = try result.get()
                if let responseExtraData = response.channel.extraData {
                    XCTAssertEqual(self.meta, responseExtraData.object as? Meta)
                } else {
                    XCTFail("No extra data from channel response \(result)")
                }
            } catch {
                XCTFail("\(error)")
            }
        }
    }
    
    func testMessageAndAttachmentExtraData() {
        channel.send(message: message) { result in
            do {
                let response = try result.get()
                XCTAssertEqual(self.meta, response.message.extraData?.object as? Meta)
                XCTAssertEqual(self.meta, response.message.attachments.first?.extraData?.object as? Meta)
            } catch {
                XCTFail("\(error)")
            }
        }
    }
}

struct Meta: Codable, Equatable {
    let meta: String
}
