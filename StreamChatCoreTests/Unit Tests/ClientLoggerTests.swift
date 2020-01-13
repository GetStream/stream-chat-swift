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
    private let testData = "{\"testKey\":\"testValue\"}".data(using: .utf8)!

    private var allEndpoints = [Endpoint]()
    
    private var logged = [String]()
    
    private lazy var infoLogger: ClientLogger = {
        ClientLogger.logger = { [weak self] _, _, message in self?.logged.append(message) }
        let logger = ClientLogger(icon: "🗣", level: .info)
        return logger
    }()
    
    private lazy var debugLogger: ClientLogger = {
        ClientLogger.logger = { [weak self] _, _, message in self?.logged.append(message) }
        let logger = ClientLogger(icon: "🗣", level: .debug)
        return logger
    }()
    
    private lazy var errorLogger: ClientLogger = {
        ClientLogger.logger = { [weak self] _, _, message in self?.logged.append(message) }
        let logger = ClientLogger(icon: "🗣", level: .error)
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
    
    // MARK: Info level logging
    
    func testLogEndpointStringsWithInfoLevel() {
        for endpoint in allEndpoints {
            infoLogger.log("Endpoint: \(String(describing: endpoint))", level: .info)
        }

        XCTAssertEqual(logged.count, allEndpoints.count, "Unexpected log found! \(logged)")
    }

    func testLogURLRequestWithInfoLevel() {
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

            infoLogger.log(urlRequest)
        }

        XCTAssertFalse(logged.isEmpty)
    }

    func testLogHeadersWithInfoLevel() {
        let headers = [
            "X-Stream-Client": "stream-chat-swift-client-2",
            "X-Stream-Device": "iPhone11",
            "X-Stream-OS": "iOS13.3",
            "Stream-Auth-Type": "anonymous"]

        infoLogger.log(headers: headers)

        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        for (key, value) in headers {
            XCTAssert(logged[0].contains("\(key) = \(value)"), "Unexpected log found! \(logged)")
        }
    }

    func testLogQueryItemsWithInfoLevel() {
        let queryItems: [URLQueryItem] = [.init(name: "test1", value: "test1"),
                                          .init(name: "test2", value: "test2")]

        infoLogger.log(queryItems)

        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logged[0], "URL query items:\n▫️ test1=test1\n▫️ test2=test2\n", "Unexpected log found! \(logged)")
    }

    func testLogURLResponseWithInfoLevel() {
        let urlResponse = HTTPURLResponse(url: testUrl, mimeType: nil, expectedContentLength: 1, textEncodingName: nil)

        infoLogger.log(urlResponse, data: testData)

        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logged[0], "⬅️ Response 200 (23 bytes): getstream.io", "Unexpected log found! \(logged)")
    }

    func testLogErrorWithInfoLevel() {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        infoLogger.log(testError as Error, message: "test error message"); let line = #line

        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logged[0], "❌ test error message Error Domain=test Code=1 \"(null)\" in \(#function)[\(line)]", "Unexpected log found! \(logged)")
    }

    func testLogDataWithInfoLevel() {
        infoLogger.log(testData)

        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logged[0], "📦  {\n  \"testKey\" : \"testValue\"\n}", "Unexpected log found! \(logged)")
    }

    func testLogMessageWithInfoLevel() {
        infoLogger.log("Some message")

        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logged[0], "Some message", "Unexpected log found! \(logged)")
    }
    
    // MARK: Debug level logging
    
    func testLogEndpointStringsWithDebugLevel() {
        for endpoint in allEndpoints {
            debugLogger.log("Endpoint: \(String(describing: endpoint))", level: .debug)
        }
        
        XCTAssertEqual(logged.count, allEndpoints.count, "Unexpected log found! \(logged)")
    }
    
    func testLogURLRequestWithDebugLevel() {
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
            
            debugLogger.log(urlRequest)
        }
        
        XCTAssertFalse(logged.isEmpty)
    }
    
    func testLogHeadersWithDebugLevel() {
        let headers = [
            "X-Stream-Client": "stream-chat-swift-client-2",
            "X-Stream-Device": "iPhone11",
            "X-Stream-OS": "iOS13.3",
            "Stream-Auth-Type": "anonymous"]
        
        debugLogger.log(headers: headers)
        
        XCTAssert(logged.isEmpty, "Unexpected log found! \(logged)")
    }
    
    func testLogQueryItemsWithDebugLevel() {
        let queryItems: [URLQueryItem] = [.init(name: "test1", value: "test1"),
                                          .init(name: "test2", value: "test2")]
        
        debugLogger.log(queryItems)
        
        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logged[0], "URL query items:\n▫️ test1=test1\n▫️ test2=test2\n", "Unexpected log found! \(logged)")
    }
    
    func testLogURLResponseWithDebugLevel() {
        let urlResponse = HTTPURLResponse(url: testUrl, mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
        
        debugLogger.log(urlResponse, data: testData)
        
        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logged[0], "⬅️ Response 200 (23 bytes): getstream.io", "Unexpected log found! \(logged)")
    }
    
    func testLogErrorWithDebugLevel() {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        debugLogger.log(testError as Error, message: "test error message"); let line = #line
        
        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logged[0], "❌ test error message Error Domain=test Code=1 \"(null)\" in \(#function)[\(line)]", "Unexpected log found! \(logged)")
    }
    
    func testLogDataWithDebugLevel() {
        debugLogger.log(testData)
        
        XCTAssert(logged.isEmpty, "Unexpected log found! \(logged)")
    }
    
    func testLogMessageWithDebugLevel() {
        debugLogger.log("Some message")
        
        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logged[0], "Some message", "Unexpected log found! \(logged)")
    }
    
    // MARK: Error level logging
    
    func testLogEndpointStringsWithErrorLevel() {
        for endpoint in allEndpoints {
            errorLogger.log("Endpoint: \(String(describing: endpoint))", level: .error)
        }
        
        XCTAssertEqual(logged.count, allEndpoints.count, "Unexpected log found! \(logged)")
    }
    
    func testLogURLRequestWithErrorLevel() {
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
            
            errorLogger.log(urlRequest)
        }
        
        XCTAssert(logged.isEmpty, "Unexpected log found! \(logged)")
    }
    
    func testLogHeadersWithErrorLevel() {
        let headers = [
            "X-Stream-Client": "stream-chat-swift-client-2",
            "X-Stream-Device": "iPhone11",
            "X-Stream-OS": "iOS13.3",
            "Stream-Auth-Type": "anonymous"]
        
        errorLogger.log(headers: headers)
        
        XCTAssert(logged.isEmpty, "Unexpected log found! \(logged)")
    }
    
    func testLogQueryItemsWithErrorLevel() {
        let queryItems: [URLQueryItem] = [.init(name: "test1", value: "test1"),
                                          .init(name: "test2", value: "test2")]
        
        errorLogger.log(queryItems)
        
        XCTAssert(logged.isEmpty, "Unexpected log found! \(logged)")
    }
    
    func testLogURLResponseWithErrorLevel() {
        let urlResponse = HTTPURLResponse(url: testUrl, mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
        
        errorLogger.log(urlResponse, data: testData)
        
        XCTAssert(logged.isEmpty, "Unexpected log found! \(logged)")
    }
    
    func testLogErrorWithErrorLevel() {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        errorLogger.log(testError as Error, message: "test error message"); let line = #line
        
        if logged.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logged[0], "❌ test error message Error Domain=test Code=1 \"(null)\" in \(#function)[\(line)]", "Unexpected log found! \(logged)")
    }
    
    func testLogDataWithErrorLevel() {
        errorLogger.log(testData)
        
        XCTAssert(logged.isEmpty, "Unexpected log found! \(logged)")
    }
    
    func testLogMessageWithErrorLevel() {
        errorLogger.log("Some message")
        
        XCTAssert(logged.isEmpty, "Unexpected log found! \(logged)")
    }
}
