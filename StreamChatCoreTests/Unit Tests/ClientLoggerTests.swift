//
//  ClientLoggerTests.swift
//  StreamChatCoreTests
//
//  Created by Bahadir Oncel on 20.12.2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatCore

class ClientLoggerTests: XCTestCase {
    private let testUser = User(id: "test", name: "Test")
    private let testChannel = Channel(type: .messaging, id: "test")
    private let testUrl = "getstream.io".url!
    private let testFilter = Filter.key("members", .in(["test-member"]))
    private let testData = Data(base64Encoded: "TestData")!

    private var allEndpoints = [Endpoint]()
    
    private var logged = [String]()
    
    private lazy var logger: ClientLogger = {
        ClientLogger.logger = { [weak self] _, _, message in self?.logged.append(message) }
        let logger = ClientLogger(icon: "🗣", level: .info)
        return logger
    }()
    
    override func setUp() {
        super.setUp()
        
        logged.removeAll()
        
        let testMembers = Set([testUser.asMember])
        let testMessage = Message(id: "test", type: .reply, parentId: nil, created: Date(), updated: Date(), deleted: nil, text: "test", command: nil, args: nil, user: testUser, attachments: [], mentionedUsers: [], extraData: nil, latestReactions: [], ownReactions: [], reactionCounts: nil, replyCount: 0, showReplyInChannel: false)
        
        allEndpoints = [.guestToken(testUser),
                        .addDevice(deviceId: "test", testUser),
                        .devices(testUser),
                        .removeDevice(deviceId: "test", testUser),
                        .channels(.init(filter: testFilter)),
                        .message("test"),
                        .markAllRead,
                        .search(.init(filter: testFilter, query: "search", pagination: .none)),
                        .channel(.init(channel: testChannel, members: testMembers, pagination: .none, options: .all)),
                        .stopWatching(testChannel),
                        .updateChannel(.init(data: .init(testChannel))),
                        .deleteChannel(testChannel),
                        .hideChannel(testChannel, testUser, true),
                        .showChannel(testChannel, testUser),
                        .sendMessage(testMessage, testChannel),
                        .sendImage("test", "image", testData, testChannel),
                        .sendFile("test", "image", testData, testChannel),
                        .deleteImage(testUrl, testChannel),
                        .deleteFile(testUrl, testChannel),
                        .markRead(testChannel),
                        .sendEvent(.channelDeleted, testChannel),
                        .sendMessageAction(.init(channel: testChannel, message: testMessage, action: .init(name: "test", value: "test", style: .default, type: .button, text: "test"))),
                        .addMembers(testMembers, testChannel),
                        .removeMembers(testMembers, testChannel),
                        .invite(testMembers, testChannel),
                        .inviteAnswer(.init(channel: testChannel, accept: nil, reject: nil, message: testMessage)),
                        .replies(testMessage, .none),
                        .deleteMessage(testMessage),
                        .addReaction(.angry, testMessage),
                        .deleteReaction(.angry, testMessage),
                        .flagMessage(testMessage),
                        .unflagMessage(testMessage),
                        .users(.init(filter: testFilter)),
                        .updateUsers([testUser]),
                        .muteUser(testUser),
                        .unmuteUser(testUser),
                        .flagUser(testUser),
                        .unflagUser(testUser),
                        .ban(.init(user: testUser, channel: testChannel, timeoutInMinutes: 0, reason: nil))]
    }
    
    func testLogEndpointStrings() {
        for endpoint in allEndpoints {
            logger.log("Endpoint: \(String(describing: endpoint))", level: .debug)
        }
        
        XCTAssertEqual(logged.count, allEndpoints.count)
    }
    
    func testLogURLRequest() {
        for endpoint in allEndpoints {
            var urlRequest = URLRequest(url: testUrl)
            urlRequest.httpMethod = endpoint.method.rawValue
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let body = endpoint.body {
                let encodable = AnyEncodable(body)
                
                do {
                    if let httpBody = try? JSONEncoder.defaultGzip.encode(encodable) {
                        urlRequest.httpBody = httpBody
                        urlRequest.addValue("gzip", forHTTPHeaderField: "Content-Encoding")
                    } else {
                        urlRequest.httpBody = try JSONEncoder.default.encode(encodable)
                    }
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
            
            logger.log(urlRequest)
        }
        
        XCTAssertFalse(logged.isEmpty)
    }
    
    func testLogHeaders() {
        let headers = [
            "X-Stream-Client": "stream-chat-swift-client-2",
            "X-Stream-Device": "iPhone11",
            "X-Stream-OS": "iOS13.3",
            "Stream-Auth-Type": "anonymous"]
        
        logger.log(headers: headers)
        
        XCTAssertFalse(logged.isEmpty)
    }
    
    func testLogQueryItems() {
        let queryItems: [URLQueryItem] = [.init(name: "test1", value: "test1"),
                                          .init(name: "test2", value: "test2")]
        
        logger.log(queryItems)
        
        XCTAssertFalse(logged.isEmpty)
    }
    
    func testLogURLResponse() {
        let urlResponse = URLResponse(url: testUrl, mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
        
        logger.log(urlResponse, data: testData)
        
        XCTAssertFalse(logged.isEmpty)
    }
    
    func testLogError() {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        logger.log(testError as Error, message: "test error message")
        
        XCTAssertFalse(logged.isEmpty)
    }
    
    func testLogData() {
        logger.log(testData)
        
        XCTAssertFalse(logged.isEmpty)
    }
    
    func testLogMessage() {
        logger.log("Some message")
        
        XCTAssertFalse(logged.isEmpty)
    }
}
