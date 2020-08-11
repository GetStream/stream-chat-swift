//
//  ClientTestCase.swift
//  StreamChatClientTests
//
//  Created by Alexey Bukhtin on 29/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

class ClientTestCase: XCTestCase {
    
    enum TestError: Error {
        case mockError(id: UUID = .init())
    }
    
    var client: Client!
    var testSessionId: String!
    var testUser: User!
    let testToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg"
    
    override func setUp() {
        super.setUp()
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.protocolClasses?.insert(RequestRecorderURLProtocol.self, at: 0)
        sessionConfig.protocolClasses?.insert(MockNetworkURLProtocol.self, at: 1)
        
        testSessionId = UUID().uuidString
        sessionConfig.httpAdditionalHeaders = [RequestRecorderURLProtocol.testSessionHeaderKey: testSessionId!]
        
        let clientConfig = Client.Config(apiKey: "test_api_key")
        // We can create a new `Client` instance because we don't use `Client.shared` in tests.
        client = Client(config: clientConfig,
                        defaultURLSessionConfiguration: sessionConfig,
                        defaultWebSocketProviderType: WebSocketProviderMock.self)
        
        testUser = User(id: "broken-waterfall-5")
        client.set(user: testUser, token: testToken)
        
        // Prepare the test environment
        RequestRecorderURLProtocol.reset()
        RequestRecorderURLProtocol.currentSessionId = testSessionId
        
        MockNetworkURLProtocol.reset()
    }
    
    override class func tearDown() {
        // Make sure everything is cleaned up
        RequestRecorderURLProtocol.reset()
        MockNetworkURLProtocol.reset()
        super.tearDown()
    }
}
