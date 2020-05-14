//
//  ClientLoggerTests.swift
//  StreamChatCoreTests
//
//  Created by Bahadir Oncel on 20.12.2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class ClientLoggerTests: XCTestCase {
    private let testUser = User(id: "test")
    private let testUrl = "getstream.io".url!
    private let testFilter = Filter.in("members", ["test-member"])
    private let testData = "{\"testKey\":\"testValue\"}".data(using: .utf8)!
    private var allEndpoints = [Endpoint]()
    private var logOutput = [String]()
    
    private lazy var infoLogger: ClientLogger = {
        ClientLogger.log = { [weak self] _, _, _, message in self?.logOutput.append(message) }
        let logger = ClientLogger(icon: "🗣", level: .info)
        return logger
    }()
    
    private lazy var debugLogger: ClientLogger = {
        ClientLogger.log = { [weak self] _, _, _, message in self?.logOutput.append(message) }
        let logger = ClientLogger(icon: "🗣", level: .debug)
        return logger
    }()
    
    private lazy var errorLogger: ClientLogger = {
        ClientLogger.log = { [weak self] _, _, _, message in self?.logOutput.append(message) }
        let logger = ClientLogger(icon: "🗣", level: .error)
        return logger
    }()
    
    override func setUp() {
        super.setUp()
        
        logOutput = [String]()
        
        let testMembers = Set([User.user1.asMember])
        let testMessage = Message(id: "test", type: .reply, text: "test", user: testUser)
        let testReaction = Reaction(type: "angry", messageId: testMessage.id, user: testUser)
        let testChannel = sharedClient.channel(type: .messaging, id: "test")
        
        allEndpoints = [.guestToken(User.user1),
                        .addDevice(deviceId: "test", User.user1),
                        .devices(User.user1),
                        .removeDevice(deviceId: "test", User.user1),
                        .channels(.init(filter: testFilter)),
                        .message("test"),
                        .markAllRead,
                        .search(.init(filter: testFilter, query: "search")),
                        .channel(.init(channel: testChannel, options: .all)),
                        .stopWatching(testChannel),
                        .updateChannel(.init(data: .init(testChannel))),
                        .deleteChannel(testChannel),
                        .hideChannel(testChannel, User.user1, true),
                        .showChannel(testChannel, User.user1),
                        .sendMessage(testMessage, testChannel),
                        .sendImage(testData, "test", "image", testChannel),
                        .sendFile(testData, "test", "image", testChannel),
                        .deleteImage(testUrl, testChannel),
                        .deleteFile(testUrl, testChannel),
                        .markRead(testChannel),
                        .sendEvent(.channelDeleted, testChannel),
                        .sendMessageAction(.init(channel: testChannel,
                                                 message: testMessage,
                                                 action: .init(name: "test",
                                                               value: "test",
                                                               style: .default,
                                                               type: .button,
                                                               text: "test"))),
                        .addMembers(testMembers, testChannel),
                        .removeMembers(testMembers, testChannel),
                        .invite(testMembers, testChannel),
                        .inviteAnswer(.init(channel: testChannel, accept: nil, reject: nil, message: testMessage)),
                        .replies(testMessage, []),
                        .deleteMessage(testMessage),
                        .addReaction(testReaction),
                        .deleteReaction(testReaction.type, testMessage),
                        .flagMessage(testMessage),
                        .unflagMessage(testMessage),
                        .users(.init(filter: testFilter)),
                        .updateUsers([User.user1]),
                        .muteUser(User.user1),
                        .unmuteUser(User.user1),
                        .flagUser(User.user1),
                        .unflagUser(User.user1),
                        .ban(.init(user: User.user1, channel: testChannel, timeoutInMinutes: 0, reason: nil))]
    }
    
    override func tearDown() {
        super.tearDown()
        
        logOutput = [String]()
    }
    
    // MARK: Info level logging
    
    func testLogEndpointStringsWithInfoLevel() {
        for endpoint in allEndpoints {
            infoLogger.log("Endpoint: \(String(describing: endpoint))", level: .info)
        }
        
        XCTAssertEqual(logOutput.filter({ $0.starts(with: "Endpoint:") }).count, allEndpoints.count, "Unexpected log found! \(logOutput)")
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
        
        XCTAssertFalse(logOutput.isEmpty)
    }
    
    func testLogHeadersWithInfoLevel() {
        let headers = [
            "X-Stream-Client": "stream-chat-swift-client-2",
            "X-Stream-Device": "iPhone11",
            "X-Stream-OS": "iOS13.3",
            "Stream-Auth-Type": "anonymous"]
        
        infoLogger.log(headers: headers)
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        for (key, value) in headers {
            XCTAssert(logOutput[0].contains("\(key) = \(value)"), "Unexpected log found! \(logOutput)")
        }
    }
    
    func testLogQueryItemsWithInfoLevel() {
        let queryItems: [URLQueryItem] = [.init(name: "test1", value: "test1"),
                                          .init(name: "test2", value: "test2")]
        
        infoLogger.log(queryItems)
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logOutput[0], "URL query items:\n▫️ test1=test1\n▫️ test2=test2\n", "Unexpected log found! \(logOutput)")
    }
    
    func testLogURLResponseWithInfoLevel() {
        let urlResponse = HTTPURLResponse(url: testUrl, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        infoLogger.log(urlResponse, data: testData)
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logOutput[0], "⬅️ Response 200 (23 bytes): getstream.io", "Unexpected log found! \(logOutput)")
    }
    
    func testLogErrorWithInfoLevel() {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        infoLogger.log(testError as Error, message: "test error message"); let line = #line
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logOutput[0], "❌ test error message Error Domain=test Code=1 \"(null)\" in \(#function)[\(line)]", "Unexpected log found! \(logOutput)")
    }
    
    func testLogDataWithInfoLevel() {
        infoLogger.log(testData)
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logOutput[0], "📦  {\n  \"testKey\" : \"testValue\"\n}", "Unexpected log found! \(logOutput)")
    }
    
    func testLogMessageWithInfoLevel() {
        infoLogger.log("Some message")
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logOutput[0], "Some message", "Unexpected log found! \(logOutput)")
    }
    
    // MARK: Debug level logging
    
    func testLogEndpointStringsWithDebugLevel() {
        for endpoint in allEndpoints {
            debugLogger.log("Endpoint: \(String(describing: endpoint))", level: .debug)
        }
        
        XCTAssertEqual(logOutput.filter({ $0.starts(with: "Endpoint:") }).count, allEndpoints.count, "Unexpected log found! \(logOutput)")
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
        
        XCTAssertFalse(logOutput.isEmpty)
    }
    
    func testLogHeadersWithDebugLevel() {
        let headers = [
            "X-Stream-Client": "stream-chat-swift-client-2",
            "X-Stream-Device": "iPhone11",
            "X-Stream-OS": "iOS13.3",
            "Stream-Auth-Type": "anonymous"]
        
        debugLogger.log(headers: headers)
        
        XCTAssert(logOutput.isEmpty, "Unexpected log found! \(logOutput)")
    }
    
    func testLogQueryItemsWithDebugLevel() {
        let queryItems: [URLQueryItem] = [.init(name: "test1", value: "test1"),
                                          .init(name: "test2", value: "test2")]
        
        debugLogger.log(queryItems)
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logOutput[0], "URL query items:\n▫️ test1=test1\n▫️ test2=test2\n", "Unexpected log found! \(logOutput)")
    }
    
    func testLogURLResponseWithDebugLevel() {
        let urlResponse = HTTPURLResponse(url: testUrl, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        debugLogger.log(urlResponse, data: testData)
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logOutput[0], "⬅️ Response 200 (23 bytes): getstream.io", "Unexpected log found! \(logOutput)")
    }
    
    func testLogErrorWithDebugLevel() {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        debugLogger.log(testError as Error, message: "test error message"); let line = #line
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logOutput[0], "❌ test error message Error Domain=test Code=1 \"(null)\" in \(#function)[\(line)]", "Unexpected log found! \(logOutput)")
    }
    
    func testLogDataWithDebugLevel() {
        debugLogger.log(testData)
        
        XCTAssert(logOutput.isEmpty, "Unexpected log found! \(logOutput)")
    }
    
    func testLogMessageWithDebugLevel() {
        debugLogger.log("Some message")
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logOutput[0], "Some message", "Unexpected log found! \(logOutput)")
    }
    
    // MARK: Error level logging
    
    func testLogEndpointStringsWithErrorLevel() {
        for endpoint in allEndpoints {
            errorLogger.log("Endpoint: \(String(describing: endpoint))", level: .error)
        }
        
        XCTAssertEqual(logOutput.filter({ $0.starts(with: "Endpoint:") }).count, allEndpoints.count, "Unexpected log found! \(logOutput)")
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
        
        XCTAssert(logOutput.isEmpty, "Unexpected log found! \(logOutput)")
    }
    
    func testLogHeadersWithErrorLevel() {
        let headers = [
            "X-Stream-Client": "stream-chat-swift-client-2",
            "X-Stream-Device": "iPhone11",
            "X-Stream-OS": "iOS13.3",
            "Stream-Auth-Type": "anonymous"]
        
        errorLogger.log(headers: headers)
        
        XCTAssert(logOutput.isEmpty, "Unexpected log found! \(logOutput)")
    }
    
    func testLogQueryItemsWithErrorLevel() {
        let queryItems: [URLQueryItem] = [.init(name: "test1", value: "test1"),
                                          .init(name: "test2", value: "test2")]
        
        errorLogger.log(queryItems)
        
        XCTAssert(logOutput.isEmpty, "Unexpected log found! \(logOutput)")
    }
    
    func testLogURLResponseWithErrorLevel() {
        let urlResponse = HTTPURLResponse(url: testUrl, mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
        
        errorLogger.log(urlResponse, data: testData)
        
        XCTAssert(logOutput.isEmpty, "Unexpected log found! \(logOutput)")
    }
    
    func testLogErrorWithErrorLevel() {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        errorLogger.log(testError as Error, message: "test error message"); let line = #line
        
        if logOutput.isEmpty {
            XCTFail("No logged message!")
            return
        }
        XCTAssertEqual(logOutput[0], "❌ test error message Error Domain=test Code=1 \"(null)\" in \(#function)[\(line)]", "Unexpected log found! \(logOutput)")
    }
    
    func testLogDataWithErrorLevel() {
        errorLogger.log(testData)
        
        XCTAssert(logOutput.isEmpty, "Unexpected log found! \(logOutput)")
    }
    
    func testLogMessageWithErrorLevel() {
        errorLogger.log("Some message")
        
        XCTAssert(logOutput.isEmpty, "Unexpected log found! \(logOutput)")
    }
}
